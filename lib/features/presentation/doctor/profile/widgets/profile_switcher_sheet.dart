import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/widgets/profile_visuals.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/domain/entities/work_space/get_work_space_entity.dart' as ws;
import 'package:yiraclinics/core/navigation_services/navigation_services.dart';
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

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      String? resolveProfileImage(String? profId, String? serverImage) {
        if (serverImage != null && serverImage.trim().isNotEmpty) {
          return serverImage.trim();
        }
        if (profId != null && profId.trim().isNotEmpty) {
          final id = profId.trim();
          final idLower = id.toLowerCase();
          final idUpper = id.toUpperCase();
          for (final keyId in [id, idLower, idUpper]) {
            final net = prefs.getString('patient_profile_network_image_$keyId');
            if (net != null && net.trim().isNotEmpty) return net.trim();
            final loc = prefs.getString('patient_profile_image_$keyId') ??
                prefs.getString('profile_image_$keyId') ??
                prefs.getString('doctor_profile_image_$keyId');
            if (loc != null && loc.trim().isNotEmpty) return loc.trim();
          }
        }
        return null;
      }

      final currentUser = GlobalSession.instance.userNotifier.value;
      final List<ProfileEntity> profiles = currentUser?.data?.profiles ?? [];
      final List<RoleEntity> allRoles = currentUser?.data?.roles ?? [];

      // Always use the primary account's ID for workspace fetching
      final primaryUserId = (profiles.isNotEmpty && profiles.first.id != null && profiles.first.id!.isNotEmpty)
          ? profiles.first.id!
          : (currentUser?.data?.id ?? '');

      final roles = allRoles.where((r) {
        final name = r.roleName?.toLowerCase() ?? '';
        final roleId = (r.roleId ?? '').toUpperCase();
        return name.contains('provider') ||
            name.contains('doctor') ||
            name.contains('physician') ||
            name.contains('user') ||
            name.contains('patient') ||
            roleId == '4FC67429-28AE-4106-93EF-436228282ED0' ||
            roleId == 'FE80173F-9DB3-4703-84A8-5C23E7CC493C';
      }).toList();

      final List<_FlatWorkspaceItem> items = [];

      final String fallbackPrimaryName = '${currentUser?.data?.firstName ?? ''} ${currentUser?.data?.lastName ?? ''}'.trim().isNotEmpty
          ? '${currentUser?.data?.firstName ?? ''} ${currentUser?.data?.lastName ?? ''}'.trim()
          : 'Primary Account';

      final bool primaryHasPatientRole = allRoles.any((r) {
        final rName = (r.roleName ?? '').toLowerCase();
        final rId = (r.roleId ?? '').toUpperCase();
        return rId == '4FC67429-28AE-4106-93EF-436228282ED0' ||
               rName.contains('patient') ||
               rName.contains('user');
      });

      RoleEntity? providerRoleEntity;
      for (final r in allRoles) {
        final rName = (r.roleName ?? '').toLowerCase();
        final rId = (r.roleId ?? '').toUpperCase();
        if (rId == 'FE80173F-9DB3-4703-84A8-5C23E7CC493C' ||
            rName.contains('provider') ||
            rName.contains('doctor') ||
            rName.contains('physician')) {
          providerRoleEntity = r;
          break;
        }
      }
      final bool primaryHasProviderRole = providerRoleEntity != null &&
          providerRoleEntity.roleId != null &&
          providerRoleEntity.roleId!.isNotEmpty;

      final String primaryRoleId = primaryHasPatientRole
          ? '4FC67429-28AE-4106-93EF-436228282ED0'
          : (primaryHasProviderRole ? providerRoleEntity.roleId! : '4FC67429-28AE-4106-93EF-436228282ED0');

      // 1. Add Family Profiles (Primary + Dependents)
      if (profiles.isNotEmpty) {
        int primaryIndex = profiles.indexWhere((p) {
          final r = (p.relation ?? '').trim().toLowerCase();
          final isFam = r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin';
          return p.isPrimary == true && !isFam;
        });

        if (primaryIndex != -1) {
          final primaryProf = profiles[primaryIndex];
          final String pPrimaryName = (primaryProf.name?.isNotEmpty ?? false)
              ? primaryProf.name!
              : '${primaryProf.firstName ?? ''} ${primaryProf.lastName ?? ''}'.trim().isNotEmpty
                  ? '${primaryProf.firstName ?? ''} ${primaryProf.lastName ?? ''}'.trim()
                  : fallbackPrimaryName;

          final String? primaryImage = resolveProfileImage(
            primaryProf.id ?? primaryUserId,
            primaryProf.imagePath ?? currentUser?.data?.imagePath,
          );

          items.add(_FlatWorkspaceItem(
            roleId: primaryRoleId,
            roleName: 'Primary',
            orgId: currentUser?.data?.latestOrgId ?? 1,
            orgName: 'Family Profile',
            hospitalId: currentUser?.data?.latestHospitalId ?? 1,
            hospitalName: pPrimaryName,
            location: null,
            profileUserId: primaryProf.id ?? primaryUserId,
            firstName: primaryProf.firstName,
            lastName: primaryProf.lastName,
            gender: primaryProf.gender,
            dob: primaryProf.dob,
            phoneNumber: primaryProf.phoneNumber,
            relation: 'Self',
            imagePath: primaryImage,
          ));
        } else {
          final String? primaryImage = resolveProfileImage(
            primaryUserId,
            currentUser?.data?.imagePath,
          );
          items.add(_FlatWorkspaceItem(
            roleId: primaryRoleId,
            roleName: 'Primary',
            orgId: currentUser?.data?.latestOrgId ?? 1,
            orgName: 'Family Profile',
            hospitalId: currentUser?.data?.latestHospitalId ?? 1,
            hospitalName: fallbackPrimaryName,
            location: null,
            profileUserId: primaryUserId,
            firstName: currentUser?.data?.firstName,
            lastName: currentUser?.data?.lastName,
            gender: currentUser?.data?.gender,
            dob: currentUser?.data?.dob,
            phoneNumber: currentUser?.data?.phoneNumber,
            relation: 'Self',
            imagePath: primaryImage,
          ));
        }

        // 2. All other family members retain their exact fixed relations
        for (int i = 0; i < profiles.length; i++) {
          if (primaryIndex != -1 && i == primaryIndex) continue;

          final p = profiles[i];
          final rawRel = (p.relation ?? '').trim();
          final bool hasFamilyRelation = rawRel.isNotEmpty &&
              rawRel.toLowerCase() != 'self' &&
              rawRel.toLowerCase() != 'primary' &&
              rawRel.toLowerCase() != 'admin';

          final String pRel = hasFamilyRelation ? rawRel : 'Dependent';
          final String pName = (p.name?.isNotEmpty ?? false)
              ? p.name!
              : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim().isNotEmpty
                  ? '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim()
                  : pRel;

          final String pUserId = (p.id != null && p.id!.isNotEmpty) ? p.id! : '';
          final String? depImage = resolveProfileImage(
            pUserId,
            p.imagePath,
          );

          items.add(_FlatWorkspaceItem(
            roleId: '4FC67429-28AE-4106-93EF-436228282ED0',
            roleName: 'Family Member',
            orgId: 1,
            orgName: 'Family Profile',
            hospitalId: 1,
            hospitalName: pName,
            location: null,
            profileUserId: pUserId,
            firstName: p.firstName,
            lastName: p.lastName,
            gender: p.gender,
            dob: p.dob,
            phoneNumber: p.phoneNumber,
            relation: pRel,
            imagePath: depImage,
          ));
        }
      } else {
        final String? fallbackImage = resolveProfileImage(
          primaryUserId,
          currentUser?.data?.imagePath,
        );

        items.add(_FlatWorkspaceItem(
          roleId: primaryRoleId,
          roleName: 'Primary',
          orgId: currentUser?.data?.latestOrgId ?? 1,
          orgName: 'Family Profile',
          hospitalId: currentUser?.data?.latestHospitalId ?? 1,
          hospitalName: fallbackPrimaryName,
          location: null,
          profileUserId: primaryUserId,
          firstName: currentUser?.data?.firstName,
          lastName: currentUser?.data?.lastName,
          gender: currentUser?.data?.gender,
          dob: currentUser?.data?.dob,
          phoneNumber: currentUser?.data?.phoneNumber,
          relation: 'Self',
          imagePath: fallbackImage,
        ));
      }

      // 2. Add Provider / Staff Workspaces for each facility
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

        // If patient entries already added above from profiles, skip redundant generic entry
        if (roleName == 'User' || roleName == 'Patient') {
          continue;
        }

        if (roleId.isNotEmpty) {
          try {
            final getWorkSpaceUseCase = sl<GetWorkSpaceDetailsUseCase>();
            final res = await getWorkSpaceUseCase(WorkSpaceParameters(primaryUserId, roleId));
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

                    final String? docImage = (roleName == 'Provider' || roleName.toLowerCase().contains('doctor'))
                        ? resolveProfileImage(primaryUserId, currentUser?.data?.imagePath)
                        : null;

                    items.add(_FlatWorkspaceItem(
                      roleId: roleId,
                      roleName: roleName,
                      orgId: orgId,
                      orgName: orgName,
                      hospitalId: hospitalId,
                      hospitalName: hospitalName,
                      location: location,
                      profileUserId: primaryUserId,
                      imagePath: docImage,
                    ));
                    addedAnyHospital = true;
                  }
                }
              }

              if (!addedAnyHospital) {
                items.add(_FlatWorkspaceItem(
                  roleId: roleId,
                  roleName: roleName,
                  orgId: currentUser?.data?.latestOrgId ?? 1,
                  orgName: '',
                  hospitalId: currentUser?.data?.latestHospitalId ?? 1,
                  hospitalName: 'Healthcare Facility',
                  profileUserId: primaryUserId,
                ));
              }
            } else {
              items.add(_FlatWorkspaceItem(
                roleId: roleId,
                roleName: roleName,
                orgId: currentUser?.data?.latestOrgId ?? 1,
                orgName: '',
                hospitalId: currentUser?.data?.latestHospitalId ?? 1,
                hospitalName: 'Healthcare Facility',
                profileUserId: primaryUserId,
              ));
            }
          } catch (_) {
            items.add(_FlatWorkspaceItem(
              roleId: roleId,
              roleName: roleName,
              orgId: currentUser?.data?.latestOrgId ?? 1,
              orgName: '',
              hospitalId: currentUser?.data?.latestHospitalId ?? 1,
              hospitalName: 'Healthcare Facility',
              profileUserId: primaryUserId,
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _flatItems.clear();
          _flatItems.addAll(items);
          _isLoading = false;
          _errorMessage = items.isEmpty ? "No profiles found" : null;
        });
      }
    } catch (e, stack) {
      developer.log("Error loading switcher profiles", error: e, stackTrace: stack, name: "ProfileSwitcherSheet");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _flatItems.isNotEmpty ? null : "Failed to load profiles";
        });
      }
    }
  }

  Future<void> _switchWorkspace(_FlatWorkspaceItem item) async {
    final key = "${item.profileUserId ?? ''}_${item.roleId}_${item.orgId}_${item.hospitalId}";
    if (_switchingKey != null) return;

    setState(() {
      _switchingKey = key;
    });

    try {
      final updateUseCase = sl<UpdateLatestOrgDetailsUseCase>();
      final params = UpdateLatestOrgDetailsModelParams(
        userId: item.profileUserId,
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
            item.roleName.toLowerCase().contains("user") ||
            (item.relation != null &&
             item.relation!.toLowerCase() != 'doctor' &&
             item.relation!.toLowerCase() != 'provider' &&
             effectiveRoleId.toUpperCase() != "FE80173F-9DB3-4703-84A8-5C23E7CC493C");
        final String navigationId = response.data?.navigationId ?? (isPatientRole ? "1" : "2");
        final String latestUserRole = (navigationId == "2" || !isPatientRole) ? "Provider" : "Patient";

        if (currentSession?.data != null) {
          final oldData = currentSession!.data!;
          final targetUserId = (item.profileUserId != null && item.profileUserId!.isNotEmpty)
              ? item.profileUserId!
              : oldData.id;

          final updatedData = DataEntity(
            id: targetUserId,
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
            firstName: item.firstName ?? oldData.firstName,
            lastName: item.lastName ?? oldData.lastName,
            email: oldData.email,
            phoneNumber: item.phoneNumber ?? oldData.phoneNumber,
            countryCode: oldData.countryCode,
            gender: item.gender ?? oldData.gender,
            dob: item.dob ?? oldData.dob,
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
            imagePath: item.imagePath ?? oldData.imagePath,
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
        }
        NavigationService.navigateTo(AppRoutes.userConfiguration);
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
    if (lower.contains('admin') || lower.contains('manager')) {
      return Icons.admin_panel_settings_rounded;
    }
    if (lower.contains('nurse')) {
      return Icons.health_and_safety_rounded;
    }
    if (lower.contains('father') || lower.contains('mother') || lower.contains('parent')) {
      return Icons.family_restroom_rounded;
    }
    if (lower.contains('spouse') || lower.contains('wife') || lower.contains('husband')) {
      return Icons.favorite_rounded;
    }
    if (lower.contains('brother') || lower.contains('sister') || lower.contains('sibling')) {
      return Icons.people_alt_rounded;
    }
    if (lower.contains('son') || lower.contains('daughter') || lower.contains('child') || lower.contains('kid')) {
      return Icons.child_care_rounded;
    }
    if (lower.contains('patient') || lower.contains('user') || lower == 'primary' || lower == 'self') {
      return Icons.person_rounded;
    }
    return Icons.local_hospital_rounded;
  }

  Color _getRoleColor(String roleName, Color fallback) {
    final lower = roleName.toLowerCase();
    if (lower.contains('doctor') || lower.contains('provider') || lower == 'primary' || lower == 'self' || lower.contains('patient') || lower.contains('user')) {
      return const Color(0xFF0284C7); // Primary Sky Blue
    }
    if (lower.contains('admin')) {
      return const Color(0xFF2563EB); // Royal Blue
    }
    if (lower.contains('father') || lower.contains('mother') || lower.contains('parent')) {
      return const Color(0xFF1D4ED8); // Deep Cobalt Blue
    }
    if (lower.contains('brother') || lower.contains('sister') || lower.contains('sibling')) {
      return const Color(0xFF0EA5E9); // Azure / Ocean Blue
    }
    if (lower.contains('spouse') || lower.contains('wife') || lower.contains('husband') || lower.contains('nurse')) {
      return const Color(0xFF06B6D4); // Soft Cyan Blue
    }
    if (lower.contains('son') || lower.contains('daughter') || lower.contains('child') || lower.contains('kid')) {
      return const Color(0xFF38BDF8); // Soft Sky Blue
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
                        "Choose a family member or a workspace",
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
                        : Builder(
                            builder: (context) {
                              final profileItems = _flatItems.where((i) =>
                                  i.roleId.toUpperCase() == '4FC67429-28AE-4106-93EF-436228282ED0' ||
                                  i.relation != null).toList();

                              final roleItems = _flatItems.where((i) =>
                                  i.roleId.toUpperCase() != '4FC67429-28AE-4106-93EF-436228282ED0' &&
                                  i.relation == null).toList();

                              return ListView(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  if (profileItems.isNotEmpty) ...[
ProfileSectionLabel(title: "Family profiles", count: profileItems.length, isDark: isDark),
                                    ...profileItems.map((item) => _buildItemTile(
                                          item: item,
                                          isDark: isDark,
                                          primaryColor: primaryColor,
                                          isTab: isTab,
                                          currentUser: currentUser,
                                          activeRoleId: activeRoleId,
                                          activeHospitalId: activeHospitalId,
                                        )),
                                    if (_isPatientSession(currentUser) && !GlobalSession.instance.isSignedInAsFamilyMember)
                                      _buildAddFamilyTile(isDark: isDark, primaryColor: primaryColor, isTab: isTab),
                                  ],
                                  if (roleItems.isNotEmpty) ...[
                                    if (profileItems.isNotEmpty) const SizedBox(height: 12),
ProfileSectionLabel(title: "Workspaces", count: roleItems.length, isDark: isDark),
                                    ...roleItems.map((item) => _buildItemTile(
                                          item: item,
                                          isDark: isDark,
                                          primaryColor: primaryColor,
                                          isTab: isTab,
                                          currentUser: currentUser,
                                          activeRoleId: activeRoleId,
                                          activeHospitalId: activeHospitalId,
                                        )),
                                  ],
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile({
    required _FlatWorkspaceItem item,
    required bool isDark,
    required Color primaryColor,
    required bool isTab,
    required dynamic currentUser,
    required dynamic activeRoleId,
    required dynamic activeHospitalId,
  }) {
    final String key = "${item.profileUserId ?? ''}_${item.roleId}_${item.orgId}_${item.hospitalId}";
    final bool isSwitching = (_switchingKey == key);
    final activeRoleName = (currentUser?.data?.latestUserRole ?? '').toLowerCase().trim();
    final activeNavId = currentUser?.data?.navigationId?.toString().trim();
    final activeRoleIdStr = (activeRoleId?.toString() ?? '').toUpperCase();

    final isPatientItem = (item.roleName == 'User' ||
        item.roleName == 'Patient' ||
        item.roleId.toUpperCase() == '4FC67429-28AE-4106-93EF-436228282ED0' ||
        item.relation != null);

    final bool isSessionPatient = activeRoleName.contains('patient') ||
        activeRoleName == 'user' ||
        activeRoleName.contains('consumer') ||
        activeRoleName.contains('client') ||
        activeNavId == '1' ||
        activeRoleIdStr == '4FC67429-28AE-4106-93EF-436228282ED0';

    final String currentUserId = (currentUser?.data?.id ?? '').toLowerCase().trim();
    final String targetProfileId = (item.profileUserId ?? '').toLowerCase().trim();

    final bool isActuallyCurrentModeAndItem = isPatientItem
        ? (isSessionPatient && targetProfileId.isNotEmpty && targetProfileId == currentUserId)
        : (!isSessionPatient &&
            item.roleId.toUpperCase() == activeRoleIdStr &&
            item.hospitalId.toString() == activeHospitalId.toString());

    final bool isActive = isPatientItem
        ? (targetProfileId.isNotEmpty && targetProfileId == currentUserId)
        : (!isSessionPatient &&
            item.roleId.toUpperCase() == activeRoleIdStr &&
            item.hospitalId.toString() == activeHospitalId.toString());
    final Color roleColor = _getRoleColor(item.roleName, primaryColor);
    final Color infoColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final bool isOtherSwitching = _switchingKey != null && !isSwitching;

    final String relation = (item.relation ?? '').trim();
    final bool isSelf = relation.isEmpty || relation.toLowerCase() == 'self' || item.roleName == 'Primary';
    final String tagLabel = isPatientItem ? (isSelf ? 'You' : relation) : item.roleName;
    final Color accent = isPatientItem ? profileRelationColor(relation, isPrimary: isSelf) : roleColor;
    final String title = item.hospitalName;
    final String gender = (item.gender ?? '').trim();
    final String? age = profileAgeLabel(item.dob);
    final String? location = (item.location != null && item.location!.trim().isNotEmpty) ? item.location!.trim() : null;

    final Widget leading = isPatientItem
        ? ProfileAvatar(name: title, imagePath: item.imagePath, color: accent, size: isTab ? 46 : 42)
        : Container(
            width: isTab ? 50 : 46,
            height: isTab ? 50 : 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.8), accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Icon(_getRoleIcon(item.roleName), size: 21, color: Colors.white),
          );

    final List<Widget> info = isPatientItem
        ? [
            if (gender.isNotEmpty) ProfileInfoItem(icon: profileGenderIcon(gender), text: gender, color: infoColor, isTab: isTab),
            if (age != null) ProfileInfoItem(icon: Icons.cake_outlined, text: age, color: infoColor, isTab: isTab),
          ]
        : [
            if (item.orgName.isNotEmpty) ProfileInfoItem(icon: Icons.apartment_rounded, text: item.orgName, color: infoColor, isTab: isTab),
            if (location != null) ProfileInfoItem(icon: Icons.location_on_outlined, text: location, color: infoColor, isTab: isTab),
          ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isOtherSwitching ? 0.5 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isActive ? Color.alphaBlend(accent.withValues(alpha: isDark ? 0.2 : 0.07), cardColor) : cardColor,
            border: Border.all(
              color: isActive ? accent.withValues(alpha: 0.6) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isActive ? 1.4 : 1,
            ),
            boxShadow: isDark
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: isActuallyCurrentModeAndItem || _switchingKey != null ? null : () => _switchWorkspace(item),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    leading,
                    const SizedBox(width: 13),
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
                                    fontSize: isTab ? 15.5 : 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ProfileTag(label: tagLabel, color: accent, isDark: isDark),
                            ],
                          ),
                          if (info.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Wrap(spacing: 12, runSpacing: 4, children: info),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (isSwitching)
                      SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: accent))
                    else if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'Current',
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isPatientSession(dynamic currentUser) {
    final role = (currentUser?.data?.latestUserRole ?? '').toString().toLowerCase().trim();
    final roleId = (currentUser?.data?.latestRoleId?.toString() ?? '').toUpperCase();
    return role.contains('patient') ||
        role == 'user' ||
        currentUser?.data?.navigationId?.toString().trim() == '1' ||
        roleId == '4FC67429-28AE-4106-93EF-436228282ED0';
  }

  Widget _buildAddFamilyTile({required bool isDark, required Color primaryColor, required bool isTab}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: primaryColor.withValues(alpha: 0.25)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _switchingKey != null
              ? null
              : () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.pushNamed(AppRoutes.patientMyFamily);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: isTab ? 46 : 42,
                  height: isTab ? 46 : 42,
                  decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.person_add_alt_1_rounded, size: 20, color: primaryColor),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add a family member',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 15 : 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'Manage their records from your account',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 12 : 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  final String? profileUserId;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? dob;
  final String? phoneNumber;
  final String? relation;
  final String? imagePath;

  _FlatWorkspaceItem({
    required this.roleId,
    required this.roleName,
    required this.orgId,
    required this.orgName,
    required this.hospitalId,
    required this.hospitalName,
    this.location,
    this.profileUserId,
    this.firstName,
    this.lastName,
    this.gender,
    this.dob,
    this.phoneNumber,
    this.relation,
    this.imagePath,
  });
}
