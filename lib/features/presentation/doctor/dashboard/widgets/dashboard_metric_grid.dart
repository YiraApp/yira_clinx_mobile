import 'package:flutter/material.dart';
import '../../../../../core/constants/constants.dart';
import '../../../../domain/entities/dashboard/doctor_dashboard_entity.dart';
import '../widgets/doc_metric_card.dart';

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
    final List<Widget> metricCards = [
      DocMetricCard(
        title: metrics.today?.title ?? '',
        value: '${metrics.today?.value}',
        subtext: metrics.today?.subtext ??'',
        icon: Icons.calendar_today_outlined,
        iconColor: primaryColor,
        isTab: isTab,
      ),
      DocMetricCard(
        title: metrics.patients?.title ?? '',
        value: '${metrics.patients?.value}',
        subtext: metrics.patients?.subtext ?? '',
        icon: Icons.person_outline_rounded,
        iconColor: primaryColor,
        isTab: isTab,
      ),
      DocMetricCard(
        title: metrics.done?.title ?? '',
        value: '${metrics.done?.value}',
        subtext: metrics.done?.subtext ?? '',
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.teal,
        isTab: isTab,
      ),
      DocMetricCard(
        title: metrics.stats?.title ?? '',
        value: '${metrics.stats?.value}',
        subtext: metrics.stats?.subtext ??'',
        icon: Icons.analytics_outlined,
        iconColor: primaryColor,
        isTab: isTab,
      ),
    ];

    if (isTab) {
      return Row(
        children: List.generate(metricCards.length, (index) {
          final bool isLast = index == metricCards.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0.0 : fieldSpace),
              child: metricCards[index],
            ),
          );
        }),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: fieldSpace,
      crossAxisSpacing: fieldSpace,
      childAspectRatio: 1.5,
      children: metricCards,
    );
  }
}