import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/models/work_space_model.dart';

class ProfileSwitcherSheet extends StatelessWidget {
  const ProfileSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ProfileSwitcherSheet(),
    );
  }

  IconData _getRoleIcon(String? roleName) {
    final lower = roleName?.toLowerCase() ?? '';
    if (lower.contains('doctor') || lower.contains('provider') || lower.contains('physician')) {
      return Icons.medical_services_rounded;
    }
    if (lower.contains('patient')) {
      return Icons.person_rounded;
    }
    if (lower.contains('admin') || lower.contains('manager')) {
      return Icons.admin_panel_settings_rounded;
    }
    if (lower.contains('nurse')) {
      return Icons.health_and_safety_rounded;
    }
    return Icons.account_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final roles = currentUser?.data?.roles ?? [];
    final activeRoleId = currentUser?.data?.latestRoleId;
    final activeUserRole = currentUser?.data?.latestUserRole;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
          // Drag handle
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Switch Profile",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Select a practice workspace or user role",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 13 : 12,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Roles List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: roles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final role = roles[index];
                final bool isActive = (role.roleId == activeRoleId) ||
                    (activeUserRole != null &&
                        role.roleName?.toLowerCase() == activeUserRole.toLowerCase());

                return InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    if (!isActive) {
                      final workSpaceData = WorkSpaceModel(true, role);

                      // Navigate to workspace selection or switch active context
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.workSpaceScreen,
                        arguments: workSpaceData,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
                          : (isDark ? const Color(0xFF243048) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? primaryColor
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                        width: isActive ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Role Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? primaryColor
                                : (isDark ? Colors.white10 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getRoleIcon(role.roleName),
                            size: 20,
                            color: isActive
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Role Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.roleName ?? "User Role",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 15 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isActive ? "Active Profile" : "Tap to switch into this workspace",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 12 : 11,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive
                                      ? primaryColor
                                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Active Indicator / Radio Check
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
