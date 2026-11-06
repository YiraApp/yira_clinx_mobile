import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/models/select_role_model.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/widgets/profile_visuals.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/domain/entities/work_space/get_work_space_entity.dart' as ws;
import 'package:yiraclinics/features/use_cases/get_work_space_details_use_case.dart';
import 'package:yiraclinics/features/use_cases/update_latest_org_details_use_case.dart';
import 'package:yiraclinics/core/services/liked_hospitals_service.dart';

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

    if (rawProfiles.isNotEmpty) {
      int pIdx = rawProfiles.indexWhere((p) {
        final r = (p.relation ?? '').trim().toLowerCase();
        final isFam = r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin';
        return p.isPrimary == true && !isFam;
      });
      if (pIdx >= 0) {
        final primary = rawProfiles.removeAt(pIdx);
        rawProfiles.insert(0, primary);
        GlobalSession.instance.rootPrimaryUserId = primary.id;
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
        _switchToDefaultPatientWorkspace();
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

  /// Family members only have the patient role; they open at the hospital
  /// admins set as the default, not a fixed one.
  Future<void> _switchToDefaultPatientWorkspace() async {
    await LikedHospitalsService.loadDefaultHospital();
    final hospital = LikedHospitalsService.defaultHospitalEntry();
    _switchWorkspace(_FlatWorkspaceItem(
      roleId: "4FC67429-28AE-4106-93EF-436228282ED0",
      roleName: "User",
      orgId: int.tryParse('${hospital['orgId']}') ?? 1,
      orgName: '${hospital['orgName'] ?? ''}',
      hospitalId: int.tryParse('${hospital['id']}') ?? 19,
      hospitalName: '${hospital['name']}',
    ));
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
      _switchToDefaultPatientWorkspace();
      return;
    }

    setState(() {
      _isLoadingWorkspaces = true;
      _workspaceErrorMessage = null;
    });
    // Patient workspaces open at the configured default hospital.
    await LikedHospitalsService.loadDefaultHospital();

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
      if (mounted) {
        setState(() {
          _isLoadingWorkspaces = false;
          _workspaceErrorMessage = "No authorized roles found for this account. Please register as a patient or contact support.";
        });
      }
      return;
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

        if (isPatientRole) {
          // Patient role is Unified & Global across all clinics & hospitals
          items.add(_FlatWorkspaceItem(
            roleId: roleId.isNotEmpty ? roleId : "4FC67429-28AE-4106-93EF-436228282ED0",
            roleName: "User",
            orgId: int.tryParse('${LikedHospitalsService.defaultHospitalEntry()['orgId']}') ?? 1,
            orgName: "Unified Global Patient",
            hospitalId: int.tryParse(LikedHospitalsService.defaultHospitalId) ?? 19,
            hospitalName: "User",
            location: "",
          ));
          continue;
        }

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
                    hospitalId: int.tryParse(LikedHospitalsService.defaultHospitalId) ?? 19,
                    hospitalName: 'Healthcare Facility',
                  ));
                }
              }
            }
          } catch (_) {}
        }
      }

      if (items.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingWorkspaces = false;
            _workspaceErrorMessage = "No active facilities found for this account. Please contact support.";
          });
        }
        return;
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
        final String effectiveRoleId = response.data?.latestRoleId ?? item.roleId;
        final bool isPatientRole = effectiveRoleId.toUpperCase() ==
                "4FC67429-28AE-4106-93EF-436228282ED0" ||
            item.roleName.toLowerCase().contains("patient") ||
            item.roleName.toLowerCase().contains("user");
        final String navigationId = response.data?.navigationId ?? (isPatientRole ? "1" : "2");
        final String latestUserRole = (navigationId == "2" || !isPatientRole) ? "Provider" : "Patient";

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
            latestRoleId: effectiveRoleId,
            latestOrgId: response.data?.latestOrgId ?? item.orgId,
            latestHospitalId: response.data?.latestHospitalId ?? item.hospitalId,
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

  Color _getRelationColor(String relation, bool isPrimary) {
    if (isPrimary || relation.toLowerCase() == 'primary' || relation.toLowerCase() == 'self') {
      return const Color(0xFF0284C7); // Primary Sky Blue
    }
    final lower = relation.toLowerCase();
    if (lower.contains('father') || lower.contains('mother') || lower.contains('parent')) {
      return const Color(0xFF1D4ED8); // Deep Cobalt Blue
    }
    if (lower.contains('brother') || lower.contains('sister') || lower.contains('sibling')) {
      return const Color(0xFF0EA5E9); // Azure / Ocean Blue
    }
    if (lower.contains('spouse') || lower.contains('wife') || lower.contains('husband')) {
      return const Color(0xFF06B6D4); // Soft Cyan Blue
    }
    if (lower.contains('child') || lower.contains('son') || lower.contains('daughter')) {
      return const Color(0xFF38BDF8); // Soft Sky Blue
    }
    return const Color(0xFF64748B); // Slate Blue
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
    final ProfileEntity? primary = _profiles.isNotEmpty ? _profiles.first : null;
    final List<ProfileEntity> family =
        _profiles.length > 1 ? _profiles.sublist(1) : const [];
    final String? primaryPhone = primary?.phoneNumber?.trim();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: screenHorizontalSpacePadding,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (primary != null) ...[
            ProfileSectionLabel(title: 'Your profile', isDark: isDark),
            _buildProfileCard(
              primary,
              position: 0,
              isPrimaryCard: true,
              primaryPhone: primaryPhone,
              isTab: isTab,
              isDark: isDark,
              primaryColor: primaryColor,
            ),
          ],
          if (family.isNotEmpty) ...[
            const SizedBox(height: 10),
            ProfileSectionLabel(title: 'Family members', isDark: isDark, count: family.length),
            for (var i = 0; i < family.length; i++)
              _buildProfileCard(
                family[i],
                position: i + 1,
                isPrimaryCard: false,
                primaryPhone: primaryPhone,
                isTab: isTab,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
          ],
        ]),
      ),
    );
  }

  Widget _buildProfileCard(
    ProfileEntity profile, {
    required int position,
    required bool isPrimaryCard,
    required String? primaryPhone,
    required bool isTab,
    required bool isDark,
    required Color primaryColor,
  }) {
    final String rawRelation = (profile.relation ?? '').trim();
    final bool hasFamilyRelation = rawRelation.isNotEmpty &&
        rawRelation.toLowerCase() != 'self' &&
        rawRelation.toLowerCase() != 'primary' &&
        rawRelation.toLowerCase() != 'admin';
    final String displayRelation =
        isPrimaryCard ? 'Primary' : (hasFamilyRelation ? rawRelation : 'Dependent');
    final Color relColor = _getRelationColor(displayRelation, isPrimaryCard);
    final String displayName = profile.name?.isNotEmpty ?? false
        ? profile.name!
        : (isPrimaryCard ? 'Primary Account' : displayRelation);
    final String gender = (profile.gender ?? '').trim();
    final String? age = profileAgeLabel(profile.dob);
    final String phone = (profile.phoneNumber ?? '').trim();
    // Family members usually share the primary number; only show a phone that differs.
    final bool showPhone = phone.isNotEmpty && (isPrimaryCard || phone != primaryPhone);
    final Color infoColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final IconData genderIcon = gender.toLowerCase().startsWith('f')
        ? Icons.female_rounded
        : gender.toLowerCase().startsWith('m')
            ? Icons.male_rounded
            : Icons.person_outline_rounded;

    final bool isThisProfileSwitching =
        _switchingKey != null && _selectedProfile?.id == profile.id;
    final bool isOtherSwitching = _switchingKey != null && !isThisProfileSwitching;

    final Color cardColor = isDark ? const Color(0xFF232323) : Colors.white;
    final Color borderColor = isPrimaryCard
        ? primaryColor.withValues(alpha: isDark ? 0.55 : 0.35)
        : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0));

    void onTap() {
      if (_switchingKey != null) return;
      _selectedProfile = profile;

      if (!isPrimaryCard) {
        // A family member only has the patient role, so sign straight in.
        _switchToDefaultPatientWorkspace();
        return;
      }

      setState(() {
        _currentStep = 1;
        _fadeController.reset();
        _fadeController.forward();
      });
      _loadAllRolesAndWorkspaces();
    }

    final card = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isOtherSwitching ? 0.5 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // Opaque tint: a see-through fill would let the shadow show through.
          gradient: isPrimaryCard
              ? LinearGradient(
                  colors: [
                    Color.alphaBlend(
                      primaryColor.withValues(alpha: isDark ? 0.22 : 0.07),
                      cardColor,
                    ),
                    cardColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimaryCard ? null : cardColor,
          border: Border.all(color: borderColor, width: isPrimaryCard ? 1.3 : 1),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: (isPrimaryCard ? primaryColor : Colors.black)
                        .withValues(alpha: isPrimaryCard ? 0.08 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: isPrimaryCard ? 16 : 13,
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    name: displayName,
                    imagePath: profile.imagePath,
                    color: relColor,
                    size: isPrimaryCard ? (isTab ? 54 : 50) : (isTab ? 48 : 44),
                  ),
                  const SizedBox(width: 14),
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
                                  fontSize: isPrimaryCard
                                      ? (isTab ? 17 : 15.5)
                                      : (isTab ? 16 : 14.5),
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: relColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                displayRelation,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: relColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (gender.isNotEmpty || age != null || showPhone) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              if (gender.isNotEmpty) ProfileInfoItem(icon: genderIcon, text: gender, color: infoColor, isTab: isTab),
                              if (age != null) ProfileInfoItem(icon: Icons.cake_outlined, text: age, color: infoColor, isTab: isTab),
                              if (showPhone) ProfileInfoItem(icon: Icons.phone_outlined, text: phone, color: infoColor, isTab: isTab),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  isThisProfileSwitching
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(primaryColor),
                          ),
                        )
                      : Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isPrimaryCard
                                ? primaryColor
                                : (isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: isPrimaryCard
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.grey.shade600),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Cards slide in one after another.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 320 + position * 70),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 14), child: child),
        ),
        child: card,
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

    bool isPatientItem(_FlatWorkspaceItem item) =>
        item.roleName == 'User' ||
        item.roleId.toUpperCase() == "4FC67429-28AE-4106-93EF-436228282ED0";
    final personal = _flatItems.where(isPatientItem).toList();
    final workspaces = _flatItems.where((i) => !isPatientItem(i)).toList();

    var position = 0;
    Widget card(_FlatWorkspaceItem item) => _buildWorkspaceCard(
          item,
          position: position++,
          isPatient: isPatientItem(item),
          isActive: item.roleId == activeRoleId && item.hospitalId == activeHospitalId,
          isTab: isTab,
          isDark: isDark,
          primaryColor: primaryColor,
        );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: screenHorizontalSpacePadding,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (personal.isNotEmpty) ...[
            ProfileSectionLabel(title: 'Personal', isDark: isDark),
            for (final item in personal) card(item),
          ],
          if (workspaces.isNotEmpty) ...[
            if (personal.isNotEmpty) const SizedBox(height: 10),
            ProfileSectionLabel(title: 'Workspaces', isDark: isDark, count: workspaces.length),
            for (final item in workspaces) card(item),
          ],
        ]),
      ),
    );
  }

  Widget _buildWorkspaceCard(
    _FlatWorkspaceItem item, {
    required int position,
    required bool isPatient,
    required bool isActive,
    required bool isTab,
    required bool isDark,
    required Color primaryColor,
  }) {
    final String key = "${item.roleId}_${item.orgId}_${item.hospitalId}";
    final bool isSwitching = _switchingKey == key;
    final bool isOtherSwitching = _switchingKey != null && !isSwitching;
    final Color roleColor = _getRoleColor(item.roleName, primaryColor);
    final Color infoColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color cardColor = isDark ? const Color(0xFF232323) : Colors.white;

    final String title = isPatient ? 'My Health' : item.hospitalName;
    final String chip = isPatient ? 'Patient' : item.roleName;
    final String? location =
        (item.location != null && item.location!.trim().isNotEmpty) ? item.location!.trim() : null;

    final cardWidget = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isOtherSwitching ? 0.5 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isActive
              ? Color.alphaBlend(roleColor.withValues(alpha: isDark ? 0.2 : 0.07), cardColor)
              : cardColor,
          border: Border.all(
            color: isActive
                ? roleColor.withValues(alpha: 0.6)
                : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0)),
            width: isActive ? 1.4 : 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _switchingKey != null ? null : () => _switchWorkspace(item),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: isTab ? 52 : 48,
                    height: isTab ? 52 : 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [roleColor.withValues(alpha: 0.8), roleColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: roleColor.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPatient ? Icons.favorite_rounded : _getRoleIcon(item.roleName),
                      size: isTab ? 24 : 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 16 : 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                chip,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: roleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (isPatient)
                          ProfileInfoItem(icon: Icons.folder_shared_outlined, text: 'Your health records & appointments', color: infoColor, isTab: isTab)
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              if (item.orgName.isNotEmpty)
                                ProfileInfoItem(icon: Icons.apartment_rounded, text: item.orgName, color: infoColor, isTab: isTab),
                              if (location != null)
                                ProfileInfoItem(icon: Icons.location_on_outlined, text: location, color: infoColor, isTab: isTab),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isSwitching)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: roleColor),
                    )
                  else if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 320 + position * 70),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 14), child: child),
        ),
        child: cardWidget,
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
              color: isDark ? const Color(0xFF232323) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0),
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
