
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class MetricTileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color? valueColor;
  final bool isTab;

  const MetricTileItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.valueColor, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? accentColor.withOpacity(0.18) : accentColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(fieldBorderRadius),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isDark ? accentColor.withOpacity(0.9) : accentColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize:isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.024,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize:isTab?  displayWidth(context) * 0.02: displayWidth(context) * 0.032,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: valueColor ?? (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}