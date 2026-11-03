import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

class MetricTileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// Kept for callers; the icon is grey so that colour stays for what matters,
  /// such as [valueColor] on an allergy.
  final Color accentColor;
  final Color? valueColor;
  final bool isTab;

  const MetricTileItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.valueColor,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trimmed = value.trim();
    final displayVal = (trimmed.isEmpty ||
            trimmed.toLowerCase() == 'none' ||
            trimmed.toLowerCase() == 'none scheduled' ||
            trimmed == '-')
        ? 'N/A'
        : value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: DietUi.muted(isDark)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark))),
              const SizedBox(height: 2),
              Text(displayVal, style: DietUi.text(13, FontWeight.w500, valueColor ?? DietUi.body(isDark), height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
