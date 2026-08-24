import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import '../../../../../core/constants/constants.dart';

class DashboardQuickActions extends StatelessWidget {
  final bool isDark;
  final bool isTab;
  final Color primaryColor;

  const DashboardQuickActions({
    super.key,
    required this.isDark,
    required this.isTab,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        label: "+ Appt",
        icon: Icons.add_circle_outline_rounded,
        color: const Color(0xFF2563EB),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.appointmentDashboardScreen);
        },
      ),
      _ActionItem(
        label: "Patients",
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF0EA5E9),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.patientManagementScreen);
        },
      ),
      _ActionItem(
        label: "Slots",
        icon: Icons.access_time_filled_rounded,
        color: const Color(0xFF10B981),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.slotDashboard);
        },
      ),
      _ActionItem(
        label: "Rx List",
        icon: Icons.medication_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.prescriptionListScreen);
        },
      ),
    ];

    return Row(
      children: List.generate(actions.length, (index) {
        final item = actions[index];
        final bool isLast = index == actions.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : (isTab ? 10 : 8)),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isTab ? 14 : 11,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    width: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTab ? 10 : 8),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: isTab ? 20 : 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12 : 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
