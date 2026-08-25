import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/favorite_patients_service.dart';
import '../../../../domain/entities/dashboard/doctor_dashboard_entity.dart';
import '../doctor_dashboard_bloc/doctor_dashboard_bloc.dart';

class DashboardMetricsGrid extends StatelessWidget {
  final DashboardMetricsEntity metrics;
  final Color primaryColor;
  final bool isTab;

  const DashboardMetricsGrid({
    super.key,
    required this.metrics,
    required this.primaryColor,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final int todayCount = metrics.today?.value ?? 0;
    final int totalPatients = metrics.patients?.value ?? 0;
    final int doneCount = metrics.done?.value ?? 0;

    final String todayDateStr = DateFormat('d MMM, EEE').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row inside Master Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        size: 16,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Clinical Overview",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 16 : 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981), // Emerald green pulse dot
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        todayDateStr,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 12 : 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),

          // 4 Metric Pillars Content
          if (isTab)
            // Tablet: 4-Column Layout with Vertical Dividers
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      context: context,
                      isDark: isDark,
                      isTab: isTab,
                      title: "Appointments",
                      value: "$todayCount",
                      subtext: metrics.today?.subtext ?? "Today",
                      icon: Icons.calendar_month_rounded,
                      accentColor: const Color(0xFF4F46E5), // Indigo
                      onTap: () => context.read<DoctorDashboardBloc>().add(ViewCalendarEvent()),
                    ),
                  ),
                  _buildVerticalDivider(isDark),
                  Expanded(
                    child: _buildMetricItem(
                      context: context,
                      isDark: isDark,
                      isTab: isTab,
                      title: "Total Patients",
                      value: "$totalPatients",
                      subtext: metrics.patients?.subtext ?? "All Time",
                      icon: Icons.groups_rounded,
                      accentColor: const Color(0xFF0284C7), // Sky Blue
                      onTap: () => context.read<DoctorDashboardBloc>().add(ViewPatientsEvent()),
                    ),
                  ),
                  _buildVerticalDivider(isDark),
                  Expanded(
                    child: _buildMetricItem(
                      context: context,
                      isDark: isDark,
                      isTab: isTab,
                      title: "Completed",
                      value: "$doneCount",
                      subtext: metrics.done?.subtext ?? "Today",
                      icon: Icons.task_alt_rounded,
                      accentColor: const Color(0xFF10B981), // Emerald
                    ),
                  ),
                  _buildVerticalDivider(isDark),
                  Expanded(
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: FavoritePatientsService().favoriteIdsNotifier,
                      builder: (context, favSet, _) {
                        return _buildMetricItem(
                          context: context,
                          isDark: isDark,
                          isTab: isTab,
                          title: "Favorites",
                          value: "${favSet.length}",
                          subtext: "⭐ Saved",
                          icon: Icons.star_rounded,
                          accentColor: const Color(0xFFD97706), // Amber
                          onTap: () => Navigator.pushNamed(context, AppRoutes.favoritePatientsScreen),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            // Mobile: 2x2 Grid inside Master Card with Clean Cross Dividers
            Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          context: context,
                          isDark: isDark,
                          isTab: isTab,
                          title: "Appointments",
                          value: "$todayCount",
                          subtext: metrics.today?.subtext ?? "Today",
                          icon: Icons.calendar_month_rounded,
                          accentColor: const Color(0xFF4F46E5), // Indigo
                          onTap: () => context.read<DoctorDashboardBloc>().add(ViewCalendarEvent()),
                        ),
                      ),
                      _buildVerticalDivider(isDark),
                      Expanded(
                        child: _buildMetricItem(
                          context: context,
                          isDark: isDark,
                          isTab: isTab,
                          title: "Total Patients",
                          value: "$totalPatients",
                          subtext: metrics.patients?.subtext ?? "All Time",
                          icon: Icons.groups_rounded,
                          accentColor: const Color(0xFF0284C7), // Sky Blue
                          onTap: () => context.read<DoctorDashboardBloc>().add(ViewPatientsEvent()),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          context: context,
                          isDark: isDark,
                          isTab: isTab,
                          title: "Completed",
                          value: "$doneCount",
                          subtext: metrics.done?.subtext ?? "Today",
                          icon: Icons.task_alt_rounded,
                          accentColor: const Color(0xFF10B981), // Emerald
                        ),
                      ),
                      _buildVerticalDivider(isDark),
                      Expanded(
                        child: ValueListenableBuilder<Set<String>>(
                          valueListenable: FavoritePatientsService().favoriteIdsNotifier,
                          builder: (context, favSet, _) {
                            return _buildMetricItem(
                              context: context,
                              isDark: isDark,
                              isTab: isTab,
                              title: "Favorites",
                              value: "${favSet.length}",
                              subtext: "⭐ Saved",
                              icon: Icons.star_rounded,
                              accentColor: const Color(0xFFD97706), // Amber
                              onTap: () => Navigator.pushNamed(context, AppRoutes.favoritePatientsScreen),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required bool isDark,
    required bool isTab,
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTab ? 12.0 : 16.0,
            vertical: isTab ? 12.0 : 14.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row: Icon Squircle + Action Arrow if tappable
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: isTab ? 18 : 16,
                      color: accentColor,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Metric Value
              Text(
                value,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 26 : 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),

              // Title & Subtext
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 13 : 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 11.5 : 10.5,
                  fontWeight: FontWeight.w500,
                  color: accentColor.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    );
  }
}