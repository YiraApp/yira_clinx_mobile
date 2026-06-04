import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/test_results/widgets/status_badge.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../test_result_bloc/test_result_bloc.dart';
import 'counter_item_widget.dart';

class HealthOverviewCard extends StatelessWidget {
  final TestResultsLoaded state;
  const HealthOverviewCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(displayWidth(context) * 0.04),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonText(
                "Health Overview",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w600,
                  fontSize: displayWidth(context) * 0.034,
                ),
              ),
              const StatusBadge(text: "Overall: Good", color: Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonText(
                "Normal Results",
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: displayWidth(context) * 0.032,
                ),
              ),
              CommonText(
                "${(state.overallPercentage * 100).toInt()}%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: state.overallPercentage,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
              color: Colors.blue.shade600,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CounterItem(
                  label: "Total Tests",
                  value: "${state.totalTests}",
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
              Expanded(
                child: CounterItem(
                  label: "All Normal",
                  value: "${state.normalTests}",
                  valueColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
