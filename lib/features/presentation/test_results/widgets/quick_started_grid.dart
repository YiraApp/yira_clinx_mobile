


import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/test_results/widgets/stat_count_card.dart';

import '../test_result_bloc/test_result_bloc.dart';

class QuickStatsGrid extends StatelessWidget {
  final TestResultsLoaded state;
  const QuickStatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCountCard(
                title: "Blood Tests",
                count: "${state.bloodTestsCount}",
                icon: Icons.science_outlined,
                iconColor: Colors.red.shade400,
                bgColor: surface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCountCard(
                title: "Urine Tests",
                count: "${state.urineTestsCount}",
                icon: Icons.biotech_outlined,
                iconColor: Colors.orange.shade400,
                bgColor: surface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCountCard(
                title: "Normal",
                count: "17",
                icon: Icons.check_circle_outline,
                iconColor: Colors.green.shade400,
                bgColor: surface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCountCard(
                title: "Abnormal",
                count: "${state.abnormalCount}",
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.red.shade700,
                bgColor: surface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}