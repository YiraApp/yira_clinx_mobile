import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/domain/entities/work_space/get_work_space_entity.dart' as ws;
import 'package:yiraclinics/features/use_cases/get_work_space_details_use_case.dart';
import 'package:yiraclinics/features/use_cases/update_latest_org_details_use_case.dart';

class ProfileSwitcherSheet extends StatefulWidget {
  const ProfileSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSwitcherSheet(),
    );
  }

  @override
  State<ProfileSwitcherSheet> createState() => _ProfileSwitcherSheetState();
}

class _ProfileSwitcherSheetState extends State<ProfileSwitcherSheet> {
  bool _isLoading = true;
  String? _switchingKey;
  final List<_FlatWorkspaceItem> _flatItems = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllRolesAndWorkspaces();
  }

  Future<void> _loadAllRolesAndWorkspaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final allRoles = currentUser?.data?.roles ?? [];
    final roles = allRoles.where((r) {
      final name = r.roleName?.toLowerCase() ?? '';
      final roleId = (r.roleId ?? '').toUpperCase();
      return name.contains('provider') ||
          name.contains('doctor') ||
          name.contains('physician') ||
          name.contains('user') ||
          name.contains('patient') ||
          name.contains('front desk') ||
          name.contains('admin') ||
          roleId == '4FC67429-28AE-4106-93EF-436228282ED0' ||
          roleId == 'FE80173F-9DB3-4703-84A8-5C23E7CC493C' ||
          roleId == '3956F98D-D835-4204-8D5B-72870E57FF76' ||
          roleId == 'FFE1811D-6200-407C-9BDD-3B89FA1BAF2B' ||
          roleId == '6F92E889-9844-4C8F-A9E7-5A456F12A9C7' ||
          roleId == 'F6C3292F-BB06-4F43-9962-988E23087FD5';
    }).toList();

    if (roles.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final getWorkSpaceUseCase = sl<GetWorkSpaceDetailsUseCase>();
      final List<_FlatWorkspaceItem> items = [];

      bool addedPatientEntry = false;

      for (final role in roles) {
        final roleId = role.roleId ?? '';
        final roleIdUpper = roleId.toUpperCase();
        final rawRoleName = role.roleName ?? 'Provider';

        String roleName = rawRoleName;
        if (roleIdUpper == '4FC67429-28AE-4106-93EF-436228282ED0' ||
            rawRoleName.toLowerCase().contains('patient') ||
            rawRoleName.toLowerCase().contains('user') ||
            rawRoleName.toLowerCase().contains('client') ||
            rawRoleName.toLowerCase().contains('consumer')) {
          roleName = 'User';
        } else if (roleIdUpper == 'FE80173F-9DB3-4703-84A8-5C23E7CC493C' || rawRoleName.toLowerCase().contains('provider')) {
          roleName = 'Provider';
        } else if (roleIdUpper == '3956F98D-D835-4204-8D5B-72870E57FF76' || rawRoleName.toLowerCase().contains('front desk')) {
          roleName = 'Front Desk';
        } else if (roleIdUpper == 'FFE1811D-6200-407C-9BDD-3B89FA1BAF2B' || rawRoleName.toLowerCase().contains('hospital admin')) {
          roleName = 'Hospital Admin';
        } else if (roleIdUpper == '6F92E889-9844-4C8F-A9E7-5A456F12A9C7' || rawRoleName.toLowerCase().contains('org admin')) {
          roleName = 'Org Admin';
        } else if (roleIdUpper == 'F6C3292F-BB06-4F43-9962-988E23087FD5' || rawRoleName.toLowerCase().contains('system admin')) {
          roleName = 'Yira System Admin';
        }

        // Patients / Users have a single, unified profile across the platform
        if (roleName == 'User' || roleName == 'Patient') {
          if (!addedPatientEntry) {
            items.add(_FlatWorkspaceItem(
              roleId: roleId,
              roleName: 'User',
              orgId: 1,
              orgName: 'Unified Health Account',
              hospitalId: 1,
              hospitalName: 'User Profile',
              location: 'Personal Account',
            ));
            addedPatientEntry = true;
          }
          continue;
        }

        if (roleId.isNotEmpty) {
          try {
            final res = await getWorkSpaceUseCase(WorkSpaceParameters(userId, roleId));
            if (res != null && res.status == true && res.data != null) {
              final orgs = res.data!.whereType<ws.DataEntity>().toList();
              bool addedAnyHospital = false;

              for (final org in orgs) {
                final orgId = org.organizationId ?? 1;
                final orgName = org.organizationName ?? 'Organization';

                if (org.hospitals != null && org.hospitals!.isNotEmpty) {
                  for (final hospital in org.hospitals!) {
                    final hospitalId = hospital.hospitalId ?? 1;
                    final hospitalName = hospital.hospitalName ?? 'Healthcare Facility';
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
                    addedAnyHospital = true;
                  }
                }
              }

              if (!addedAnyHospital) {
                // Fallback for role with no explicit hospital entries
                items.add(_FlatWorkspaceItem(
                  roleId: roleId,
                  roleName: roleName,
                  orgId: 1,
                  orgName: '',
                  hospitalId: 1,
                  hospitalName: 'Healthcare Facility',
                ));
              }
            } else {
              items.add(_FlatWorkspaceItem(
                roleId: roleId,
                roleName: roleName,
                orgId: 1,
                orgName: '',
                hospitalId: 1,
                hospitalName: 'Healthcare Facility',
              ));
            }
          } catch (_) {
            items.add(_FlatWorkspaceItem(
              roleId: roleId,
              roleName: roleName,
              orgId: 1,
              orgName: '',
              hospitalId: 1,
              hospitalName: 'Healthcare Facility',
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _flatItems.clear();
          _flatItems.addAll(items);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load profiles";
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
      final params = UpdateLatestOrgDetailsModelParams(
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
            id: oldData.id,
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
            firstName: oldData.firstName,
            lastName: oldData.lastName,
            email: oldData.email,
            phoneNumber: oldData.phoneNumber,
            countryCode: oldData.countryCode,
            gender: oldData.gender,
            dob: oldData.dob,
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
          Navigator.of(context, rootNavigator: true).pop();
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

  IconData _getRoleIcon(String roleName) {
    final lower = roleName.toLowerCase();
    if (lower.contains('doctor') || lower.contains('provider') || lower.contains('physician')) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final activeRoleId = currentUser?.data?.latestRoleId;
    final activeHospitalId = currentUser?.data?.latestHospitalId;

    return Container(
      constraints: BoxConstraints(
        maxHeight: displayHeight(context) * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.switch_account_rounded,
                      size: 20,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Switch Profile",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 19 : 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "Tap to switch into any hospital profile",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 12.5 : 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.pop(context),
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Flat Clean List of "Hospital Name (Role)"
          Flexible(
            child: _isLoading
                ? _buildLoadingShimmer(isDark)
                : _errorMessage != null
                    ? _buildErrorView(isDark, primaryColor)
                    : _flatItems.isEmpty
                        ? _buildEmptyView(isDark)
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _flatItems.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _flatItems[index];
                              final String key = "${item.roleId}_${item.orgId}_${item.hospitalId}";
                              final bool isSwitching = (_switchingKey == key);
                              final activeRoleName = (currentUser?.data?.latestUserRole ?? '').toLowerCase().trim();
                              final activeNavId = currentUser?.data?.navigationId?.toString().trim();
                              final activeRoleIdStr = (activeRoleId?.toString() ?? '').toUpperCase();

                              final isPatientItem = (item.roleName == 'User' ||
                                  item.roleName == 'Patient' ||
                                  item.roleId.toUpperCase() == '4FC67429-28AE-4106-93EF-436228282ED0');

                              final bool isSessionPatient = activeRoleName.contains('patient') ||
                                  activeRoleName == 'user' ||
                                  activeRoleName.contains('consumer') ||
                                  activeRoleName.contains('client') ||
                                  activeNavId == '1' ||
                                  activeRoleIdStr == '4FC67429-28AE-4106-93EF-436228282ED0';

                              final bool isActive = isPatientItem
                                  ? isSessionPatient
                                  : (!isSessionPatient &&
                                      item.roleId.toUpperCase() == activeRoleIdStr &&
                                      item.hospitalId.toString() == activeHospitalId.toString());
                              final Color roleColor = _getRoleColor(item.roleName, primaryColor);

                              // Format: "User Profile" or "Yira Hospital (Provider)"
                              final String displayTitle = (item.roleName == 'User' || item.roleName == 'Patient')
                                  ? item.hospitalName
                                  : "${item.hospitalName} (${item.roleName})";

                              return Material(
                                color: isActive
                                    ? roleColor.withValues(alpha: isDark ? 0.2 : 0.08)
                                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isActive
                                        ? roleColor
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: isActive ? 1.6 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: isActive || isSwitching
                                      ? null
                                      : () => _switchWorkspace(item),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? roleColor
                                                : roleColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _getRoleIcon(item.roleName),
                                            size: 18,
                                            color: isActive ? Colors.white : roleColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Title: "Yira Hospital (Provider)"
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
                                                  fontSize: isTab ? 15 : 13.5,
                                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              if (item.orgName.isNotEmpty || item.location != null) ...[
                                                const SizedBox(height: 2),
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
                                                    fontSize: isTab ? 12 : 11,
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Action / Status Pill
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
                                            size: 20,
                                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return BaseShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
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

  Widget _buildErrorView(bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 36, color: Colors.amber.shade600),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? "Error loading profiles",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
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
    );
  }

  Widget _buildEmptyView(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          "No profiles assigned to your account",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
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
