import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

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
    this.valueColor, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDotColor = isDark ? Colors.blue[400]! : const Color(0xFF1A73E8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isLast && valueColor != null
                    ? (isDark ? Colors.grey[600] : Colors.grey[400])
                    : activeDotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 38,
                color: isDark ? Colors.grey[850] : const Color(0xFFE9ECEF),
              ),
          ],
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
                  fontSize:isTab? displayWidth(context) * 0.018: displayWidth(context) * 0.024,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab? displayWidth(context) * 0.02:displayWidth(context) * 0.032,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                ),
              ),
              if (!isLast) const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}