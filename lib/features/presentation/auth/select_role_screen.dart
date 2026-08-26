import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/models/select_role_model.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/domain/entities/work_space/get_work_space_entity.dart' as ws;
import 'package:yiraclinics/features/use_cases/get_work_space_details_use_case.dart';
import 'package:yiraclinics/features/use_cases/update_latest_org_details_use_case.dart';

class SelectRoleScreen extends StatefulWidget {
  final SelectRoleModel? roles;
  const SelectRoleScreen({super.key, this.roles});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  // 0: Profile Selection, 1: Role/Facility Selection
  int _currentStep = 0;
  ProfileEntity? _selectedProfile;
  List<ProfileEntity> _profiles = [];

  bool _isLoadingWorkspaces = false;
  String? _switchingKey;
  final List<_FlatWorkspaceItem> _flatItems = [];
  String? _workspaceErrorMessage;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();

    _initializeProfiles();
  }

  void _initializeProfiles() {
    final List<ProfileEntity> rawProfiles = [];
    if (widget.roles?.profiles != null && widget.roles!.profiles!.isNotEmpty) {
      rawProfiles.addAll(widget.roles!.profiles!);
    } else {
      final currentUser = GlobalSession.instance.userNotifier.value;
      if (currentUser?.data?.profiles != null &&
          currentUser!.data!.profiles!.isNotEmpty) {
        rawProfiles.addAll(currentUser.data!.profiles!);
      } else if (currentUser?.data != null) {
        final d = currentUser!.data!;
        rawProfiles.add(
          ProfileEntity(
            id: d.id,
            firstName: d.firstName,
            lastName: d.lastName,
            name: "${d.firstName ?? ''} ${d.lastName ?? ''}".trim().isNotEmpty
                ? "${d.firstName ?? ''} ${d.lastName ?? ''}".trim()
                : "Primary Account",
            phoneNumber: d.phoneNumber,
            relation: "Self",
            isPrimary: true,
            gender: d.gender,
            dob: d.dob,
            accountType: "Independent",
          ),
        );
      }
    }

    _profiles = rawProfiles;

    // If only 1 profile or none, select it and advance to role/facility step or direct login
    if (_profiles.length <= 1) {
      if (_profiles.isNotEmpty) {
        _selectedProfile = _profiles.first;
      }
      final bool isDep = _selectedProfile != null &&
          (_selectedProfile!.isPrimary == false ||
              _selectedProfile!.accountType == "Dependent" ||
              (_selectedProfile!.relation != null &&
                  _selectedProfile!.relation!.toLowerCase() != "self" &&
                  _selectedProfile!.relation!.toLowerCase() != "admin"));
      if (isDep) {
        _switchWorkspace(_FlatWorkspaceItem(
          roleId: "4FC67429-28AE-4106-93EF-436228282ED0",
          roleName: "User",
          orgId: 1,
          orgName: "",
          hospitalId: 19,
          hospitalName: "Yira Hospitals",
        ));
        return;
      }
      _currentStep = 1;
      _loadAllRolesAndWorkspaces();
    } else {
      _currentStep = 0;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRolesAndWorkspaces() async {
    final bool isDep = _selectedProfile != null &&
        (_selectedProfile!.isPrimary == false ||
            _selectedProfile!.accountType == "Dependent" ||
            (_selectedProfile!.relation != null &&
                _selectedProfile!.relation!.toLowerCase() != "self" &&
                _selectedProfile!.relation!.toLowerCase() != "admin"));

    if (isDep) {
      // Dependents only have Patient access -> direct login immediately
      _switchWorkspace(_FlatWorkspaceItem(
        roleId: "4FC67429-28AE-4106-93EF-436228282ED0",
        roleName: "User",
        orgId: 1,
        orgName: "",
        hospitalId: 19,
        hospitalName: "Yira Hospitals",
      ));
      return;
    }

    setState(() {
      _isLoadingWorkspaces = true;
      _workspaceErrorMessage = null;
    });

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = _selectedProfile?.id ?? currentUser?.data?.id ?? '';
    final allRoles = currentUser?.data?.roles ?? widget.roles?.roles ?? [];

    final roles = allRoles.where((r) {
      final name = r.roleName?.toLowerCase() ?? '';
      return name.contains('provider') ||
          name.contains('doctor') ||
          name.contains('physician') ||
          name.contains('user') ||
          name.contains('patient');
    }).toList();

    if (roles.isEmpty) {
      // Fallback patient/user role
      roles.add(RoleEntity(
        roleId: "4FC67429-28AE-4106-93EF-436228282ED0",
        roleName: "Patient",
        status: true,
      ));
    }

    try {
      final getWorkSpaceUseCase = sl<GetWorkSpaceDetailsUseCase>();
      final List<_FlatWorkspaceItem> items = [];

      for (final role in roles) {
        final roleId = role.roleId ?? '';
        final rawRoleName = role.roleName ?? 'Provider';
        final bool isPatientRole =
            rawRoleName.toLowerCase().contains('patient') ||
                rawRoleName.toLowerCase().contains('user') ||
                roleId.toUpperCase() ==
                    "4FC67429-28AE-4106-93EF-436228282ED0";
        final String roleName = isPatientRole ? 'User' : 'Provider';

        if (roleId.isNotEmpty) {
          try {
            final res = await getWorkSpaceUseCase(
              WorkSpaceParameters(userId, roleId),
            );
            if (res != null &&
                res.status == true &&
                res.data != null &&
                res.data!.isNotEmpty) {
              final orgs = res.data!.whereType<ws.DataEntity>().toList();

              for (final org in orgs) {
                final orgId = org.organizationId ?? 1;
                final orgName = org.organizationName ?? 'Organization';

                if (org.hospitals != null && org.hospitals!.isNotEmpty) {
                  for (final hospital in org.hospitals!) {
                    final hospitalId = hospital.hospitalId ?? 1;
                    final hospitalName =
                        hospital.hospitalName ?? 'Healthcare Facility';
                    final location = hospital.city ?? hospital.address;

                    items.add(_FlatWorkspaceItem(
                      roleId: roleId,
                      roleName: roleName,
                      orgId: orgId,
                      orgName: orgName,
                      hospitalId: hospitalId,
                      hospitalName: hospitalName,
                      location: location,
                    ));
                  }
                } else {
                  items.add(_FlatWorkspaceItem(
                    roleId: roleId,
                    roleName: roleName,
                    orgId: orgId,
                    orgName: orgName,
                    hospitalId: 19,
                    hospitalName: 'Healthcare Facility',
                  ));
                }
              }
            } else if (isPatientRole) {
              items.add(_FlatWorkspaceItem(
                roleId: roleId,
                roleName: "User",
                orgId: 1,
                orgName: '',
                hospitalId: 19,
                hospitalName: 'Healthcare Facility',
              ));
            }
            // If Provider role has no hospitals returned, do NOT add dummy items
          } catch (_) {
            if (isPatientRole) {
              items.add(_FlatWorkspaceItem(
                roleId: roleId,
                roleName: "User",
                orgId: 1,
                orgName: '',
                hospitalId: 19,
                hospitalName: 'Healthcare Facility',
              ));
            }
          }
        }
      }

      if (items.isEmpty) {
        items.add(_FlatWorkspaceItem(
          roleId: "4FC67429-28AE-4106-93EF-436228282ED0",
          roleName: "User",
          orgId: 1,
          orgName: '',
          hospitalId: 19,
          hospitalName: 'Healthcare Facility',
        ));
      }

      // If only 1 role/facility option exists -> DIRECT LOGIN!
      if (items.length == 1) {
        if (mounted) {
          _switchWorkspace(items.first);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _flatItems.clear();
          _flatItems.addAll(items);
          _isLoadingWorkspaces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWorkspaces = false;
          _workspaceErrorMessage = "Failed to load facilities";
        });
      }
    }
  }

  Future<void> _switchWorkspace(_FlatWorkspaceItem item) async {
    final key = "${item.roleId}_${item.orgId}_${item.hospitalId}";
    if (_switchingKey != null) return;

    setState(() {
      _switchingKey = key;
    });

    try {
      final updateUseCase = sl<UpdateLatestOrgDetailsUseCase>();
      final selectedUserId = _selectedProfile?.id;
      final params = UpdateLatestOrgDetailsModelParams(
        userId: selectedUserId,
        latestRoleId: item.roleId,
        latestOrgId: item.orgId,
        latestHospitalId: item.hospitalId,
      );

      final response = await updateUseCase(params);

      if (response != null && response.status == true && response.data != null) {
        final currentSession = GlobalSession.instance.userNotifier.value;
        final bool isPatientRole = item.roleId.toUpperCase() ==
                "4FC67429-28AE-4106-93EF-436228282ED0" ||
            item.roleName.toLowerCase().contains("patient") ||
            item.roleName.toLowerCase().contains("user");
        final String navigationId = isPatientRole ? "1" : "2";
        final String latestUserRole = isPatientRole ? "Patient" : "Provider";

        if (currentSession?.data != null) {
          final oldData = currentSession!.data!;
          final updatedData = DataEntity(
            id: selectedUserId ?? oldData.id,
            accessToken: oldData.accessToken,
            refreshToken: oldData.refreshToken,
            accessTokenExpiry: oldData.accessTokenExpiry,
            refreshTokenExpiry: oldData.refreshTokenExpiry,
            isMobileVerified: oldData.isMobileVerified,
            isEmailVerified: oldData.isEmailVerified,
            roleCount: oldData.roleCount,
            hospitalCount: oldData.hospitalCount,
            organizationCount: oldData.organizationCount,
            roles: oldData.roles,
            firstName: _selectedProfile?.firstName ?? oldData.firstName,
            lastName: _selectedProfile?.lastName ?? oldData.lastName,
            email: oldData.email,
            phoneNumber: _selectedProfile?.phoneNumber ?? oldData.phoneNumber,
            countryCode: oldData.countryCode,
            gender: _selectedProfile?.gender ?? oldData.gender,
            dob: _selectedProfile?.dob ?? oldData.dob,
            height: oldData.height,
            weight: oldData.weight,
            heightUnit: oldData.heightUnit,
            weightUnit: oldData.weightUnit,
            latestRoleId: item.roleId,
            latestOrgId: item.orgId,
            latestHospitalId: item.hospitalId,
            latestUserRole: latestUserRole,
            navigationId: navigationId,
            profiles: oldData.profiles,
          );

          await GlobalSession.instance.update(
            LoginEntity(
              status: true,
              message: "Session updated",
              data: updatedData,
            ),
          );
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.userConfiguration,
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _switchingKey = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?.message ?? "Failed to switch workspace"),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _switchingKey = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error switching workspace: $e"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleBackPress() {
    if (_currentStep == 1 && _profiles.length > 1) {
      setState(() {
        _currentStep = 0;
        _fadeController.reset();
        _fadeController.forward();
      });
      return;
    }

    if (widget.roles?.inApp ?? false) {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final payload = currentUser?.data;
      final navigationId = payload?.navigationId;
      final roleName = (payload?.latestUserRole ?? '').toLowerCase();
      final navigationRoutes = const {
        '1': AppRoutes.patientDashboard,
        '2': AppRoutes.doctorDashboard,
        '3': AppRoutes.patientDashboard,
      };

      final coreRoute = navigationRoutes[navigationId] ??
          (roleName.contains('patient') || roleName == 'user'
              ? AppRoutes.patientDashboard
              : AppRoutes.doctorDashboard);
      Navigator.pushNamedAndRemoveUntil(
        context,
        coreRoute,
        (route) => false,
      );
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.initial,
          (route) => false,
        );
      }
    }
  }

  IconData _getRoleIcon(String roleName) {
    final lower = roleName.toLowerCase();
    if (lower.contains('doctor') ||
        lower.contains('provider') ||
        lower.contains('physician')) {
      return Icons.medical_services_rounded;
    }
    if (lower.contains('patient') || lower.contains('user')) {
      return Icons.person_rounded;
    }
    if (lower.contains('admin') || lower.contains('manager')) {
      return Icons.admin_panel_settings_rounded;
    }
    if (lower.contains('nurse')) {
      return Icons.health_and_safety_rounded;
    }
    return Icons.local_hospital_rounded;
  }

  Color _getRoleColor(String roleName, Color fallback) {
    final lower = roleName.toLowerCase();
    if (lower.contains('doctor') || lower.contains('provider')) {
      return const Color(0xFF0284C7); // Sky Blue
    }
    if (lower.contains('admin')) {
      return const Color(0xFF6366F1); // Indigo
    }
    if (lower.contains('patient') || lower.contains('user')) {
      return const Color(0xFF10B981); // Emerald
    }
    if (lower.contains('nurse')) {
      return const Color(0xFFEC4899); // Pink
    }
    return fallback;
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].length > 1
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getRelationColor(String relation, bool isPrimary) {
    if (isPrimary || relation.toLowerCase() == 'self') {
      return const Color(0xFF0284C7); // Sky Blue
    }
    final lower = relation.toLowerCase();
    if (lower.contains('spouse') || lower.contains('wife') || lower.contains('husband')) {
      return const Color(0xFFEC4899); // Rose Pink
    }
    if (lower.contains('child') || lower.contains('son') || lower.contains('daughter')) {
      return const Color(0xFF10B981); // Emerald
    }
    if (lower.contains('father') || lower.contains('mother') || lower.contains('parent')) {
      return const Color(0xFFF59E0B); // Amber
    }
    return const Color(0xFF8B5CF6); // Purple
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isTab = isTablet(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mainHeadingColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final primaryColor = theme.primaryColor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: mainHeadingColor,
              size: 20,
            ),
            onPressed: _handleBackPress,
          ),
          automaticallyImplyLeading: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            // Background branding pattern
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenSize.height * 0.45,
              child: Opacity(
                opacity: isDarkMode ? 0.03 : 0.06,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black.withValues(alpha: 0.0)],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/ic_role_bg.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeController,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: SvgPicture.asset(
                                'assets/images/svgs/ic_apps_logo.svg',
                                width: isTab ? 65 : 56,
                                height: isTab ? 65 : 56,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CommonText(
                              _currentStep == 0
                                  ? 'Select Profile'
                                  : 'Select Role & Facility',
                              style: TextStyle(
                                fontSize: displayWidth(context) *
                                    (isTab ? 0.032 : 0.06),
                                fontWeight: FontWeight.w700,
                                fontFamily: appPoppinFont,
                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            CommonText(
                              _currentStep == 0
                                  ? 'Choose the profile or dependent account'
                                  : (_selectedProfile != null
                                      ? 'Active Profile: ${_selectedProfile!.name ?? "Primary Account"}'
                                      : 'Choose your workspace to proceed'),
                              style: TextStyle(
                                fontSize: displayWidth(context) *
                                    (isTab ? 0.018 : 0.032),
                                fontWeight: FontWeight.w500,
                                fontFamily: appPoppinFont,
                                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            if (_currentStep == 1 && _profiles.length > 1) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _currentStep = 0;
                                    _fadeController.reset();
                                    _fadeController.forward();
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swap_horiz_rounded,
                                        size: 14,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Change Profile",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Content Section based on step
                    if (_currentStep == 0)
                      _buildProfileListSliver(isTab, isDarkMode, primaryColor)
                    else
                      _buildWorkspaceListSliver(isTab, isDarkMode, primaryColor),

                    // Footer security info
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 24.0,
                          top: 20.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 14,
                                  color: isDarkMode
                                      ? Colors.white24
                                      : Colors.black26,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Secure clinical environment rules apply.',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: displayWidth(context) *
                                        (isTab ? 0.018 : 0.025),
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? Colors.white30
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Profiles List ──
  Widget _buildProfileListSliver(bool isTab, bool isDark, Color primaryColor) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: screenHorizontalSpacePadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final profile = _profiles[index];
            final bool isPrimary = profile.isPrimary == true ||
                profile.relation?.toLowerCase() == 'self';
            final String relation = profile.relation ?? (isPrimary ? 'Self' : 'Dependent');
            final Color relColor = _getRelationColor(relation, isPrimary);
            final String displayName = profile.name?.isNotEmpty ?? false
                ? profile.name!
                : (isPrimary ? "Primary Account" : "Family Member");
            final String initials = _getInitials(displayName);

            final String subtitle = [
              if (profile.gender != null && profile.gender!.isNotEmpty) profile.gender!,
              if (profile.dob != null && profile.dob!.isNotEmpty) profile.dob!,
              if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty)
                profile.phoneNumber!,
            ].join(' • ');

            final bool isDep = !isPrimary &&
                (profile.accountType == "Dependent" ||
                    (profile.relation != null &&
                        profile.relation!.toLowerCase() != "self" &&
                        profile.relation!.toLowerCase() != "admin"));
            final bool isThisProfileSwitching =
                _switchingKey != null && _selectedProfile?.id == profile.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Material(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                elevation: isDark ? 0 : 2,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                child: InkWell(
                  onTap: () {
                    if (_switchingKey != null) return;
                    _selectedProfile = profile;

                    if (isDep) {
                      // Dependent only has Patient role -> Direct login!
                      _switchWorkspace(_FlatWorkspaceItem(
                        roleId: "4FC67429-28AE-4106-93EF-436228282ED0",
                        roleName: "User",
                        orgId: 1,
                        orgName: "",
                        hospitalId: 19,
                        hospitalName: "Yira Hospitals",
                      ));
                      return;
                    }

                    setState(() {
                      _currentStep = 1;
                      _fadeController.reset();
                      _fadeController.forward();
                    });
                    _loadAllRolesAndWorkspaces();
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Avatar with Initials
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                relColor.withValues(alpha: 0.85),
                                relColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: relColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name and Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab ? 16 : 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: relColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: relColor.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isPrimary ? "Primary (Self)" : relation,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: relColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTab ? 12.5 : 11.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Chevron or Loading spinner
                        isThisProfileSwitching
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(primaryColor),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 13,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: _profiles.length,
        ),
      ),
    );
  }

  // ── Step 1: Workspace & Role Switcher (matching Provider Switcher) ──
  Widget _buildWorkspaceListSliver(bool isTab, bool isDark, Color primaryColor) {
    if (_isLoadingWorkspaces) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: screenHorizontalSpacePadding,
        ),
        sliver: SliverToBoxAdapter(
          child: _buildLoadingShimmer(isDark),
        ),
      );
    }

    if (_workspaceErrorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
          child: Column(
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: Colors.amber.shade600),
              const SizedBox(height: 12),
              Text(
                _workspaceErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadAllRolesAndWorkspaces,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_flatItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              "No healthcare profiles found for this account",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    }

    final currentUser = GlobalSession.instance.userNotifier.value;
    final activeRoleId = currentUser?.data?.latestRoleId;
    final activeHospitalId = currentUser?.data?.latestHospitalId;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: screenHorizontalSpacePadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _flatItems[index];
            final String key = "${item.roleId}_${item.orgId}_${item.hospitalId}";
            final bool isSwitching = (_switchingKey == key);
            final bool isActive = (item.roleId == activeRoleId) &&
                (item.hospitalId == activeHospitalId);
            final Color roleColor = _getRoleColor(item.roleName, primaryColor);

            // Format: "Yira Hospital (Provider)"
            final String displayTitle = "${item.hospitalName} (${item.roleName})";

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Material(
                color: isActive
                    ? roleColor.withValues(alpha: isDark ? 0.2 : 0.08)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isActive
                        ? roleColor
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isActive ? 1.6 : 1.2,
                  ),
                ),
                elevation: isDark ? 0 : 2,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                child: InkWell(
                  onTap: isSwitching ? null : () => _switchWorkspace(item),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Role / Facility Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? roleColor
                                : roleColor.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getRoleIcon(item.roleName),
                            size: 20,
                            color: isActive ? Colors.white : roleColor,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Organization info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 15.5 : 14,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              if (item.orgName.isNotEmpty || item.location != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  [
                                    if (item.orgName.isNotEmpty) item.orgName,
                                    if (item.location != null && item.location!.isNotEmpty)
                                      item.location!,
                                  ].join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTab ? 12.5 : 11.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Action Indicator
                        if (isSwitching)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: roleColor,
                            ),
                          )
                        else if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: roleColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "ACTIVE",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: _flatItems.length,
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return BaseShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: displayWidth(context) * 0.52,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: displayWidth(context) * 0.32,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FlatWorkspaceItem {
  final String roleId;
  final String roleName;
  final int orgId;
  final String orgName;
  final int hospitalId;
  final String hospitalName;
  final String? location;

  _FlatWorkspaceItem({
    required this.roleId,
    required this.roleName,
    required this.orgId,
    required this.orgName,
    required this.hospitalId,
    required this.hospitalName,
    this.location,
  });
}
