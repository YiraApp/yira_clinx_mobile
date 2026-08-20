import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleItemTapped(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    if (onTap != null) {
      onTap!(index);
      return;
    }

    if (index == currentIndex) return;

    String targetRoute;
    switch (index) {
      case 0:
        targetRoute = AppRoutes.doctorDashboard;
        break;
      case 1:
        targetRoute = AppRoutes.appointmentDashboardScreen;
        break;
      case 2:
        targetRoute = AppRoutes.patientManagementScreen;
        break;
      case 3:
        targetRoute = AppRoutes.slotDashboard;
        break;
      default:
        return;
    }

    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        targetRoute,
        (route) => route.settings.name == AppRoutes.doctorDashboard || route.isFirst,
      );
    } else {
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final Color bgColor = isDark ? darkModeCardColor : Colors.white;
    final Color borderColor = isDark ? darkModeBorderColor : lightModeBorderColor;

    final items = [
      _BottomNavItem(
        title: 'Home',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
      ),
      _BottomNavItem(
        title: 'Appointments',
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
      ),
      _BottomNavItem(
        title: 'Patients',
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_alt_rounded,
      ),
      _BottomNavItem(
        title: 'Slots',
        icon: Icons.schedule_outlined,
        activeIcon: Icons.schedule_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: isTab ? 66 : 58,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => _handleItemTapped(context, index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? (isTab ? 16 : 12) : 6,
                            vertical: isSelected ? 3 : 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? primaryColor
                                : (isDark ? Colors.white60 : Colors.blueGrey.shade400),
                            size: isTab ? 24 : 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: CommonText(
                              item.title,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab
                                    ? displayWidth(context) * 0.013
                                    : displayWidth(context) * 0.026,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? Colors.white70 : Colors.blueGrey.shade600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final String title;
  final IconData icon;
  final IconData activeIcon;

  _BottomNavItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
  });
}
