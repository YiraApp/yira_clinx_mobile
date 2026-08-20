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
        title: metrics.today?.title ?? 'Today',
        value: '${metrics.today?.value ?? 0}',
        subtext: metrics.today?.subtext ?? '',
        icon: Icons.calendar_today_outlined,
        iconColor: primaryColor,
        isTab: isTab,
      ),
      DocMetricCard(
        title: metrics.patients?.title ?? 'Patients',
        value: '${metrics.patients?.value ?? 0}',
        subtext: metrics.patients?.subtext ?? '',
        icon: Icons.person_outline_rounded,
        iconColor: primaryColor,
        isTab: isTab,
      ),
      DocMetricCard(
        title: metrics.done?.title ?? 'Completed',
        value: '${metrics.done?.value ?? 0}',
        subtext: metrics.done?.subtext ?? '',
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.teal,
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

    return Row(
      children: List.generate(metricCards.length, (index) {
        final bool isLast = index == metricCards.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0.0 : 8.0),
            child: metricCards[index],
          ),
        );
      }),
    );
  }
}