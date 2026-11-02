import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

class InfoRowItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRowItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark))),
        const SizedBox(height: 2),
        Text(value, style: DietUi.text(13, FontWeight.w500, valueColor ?? DietUi.body(isDark), height: 1.35)),
      ],
    );
  }
}
