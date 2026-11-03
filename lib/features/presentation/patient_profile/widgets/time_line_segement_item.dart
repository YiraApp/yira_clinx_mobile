import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

import 'record_tab_ui.dart';

class TimelineSegmentItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;
  final Color? valueColor;
  final bool isTab;

  const TimelineSegmentItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.isLast,
    this.valueColor,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: DietUi.hint(isDark), shape: BoxShape.circle),
            ),
            if (!isLast) Container(width: 1.5, height: 38, color: RecordUi.line(isDark)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark))),
              const SizedBox(height: 2),
              Text(value, style: DietUi.text(13, FontWeight.w500, valueColor ?? DietUi.body(isDark), height: 1.35)),
              if (!isLast) const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
