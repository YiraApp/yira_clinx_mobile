import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../../core/common_size_helpers/common_size_helpers.dart';

class DocMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color iconColor;

  const DocMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(width: 0.5, color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: displayWidth(context) * 0.032,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              Icon(icon, color: iconColor, size: 18.0),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.045,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            subtext,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.03,
              color: iconColor == Colors.green
                  ? Colors.green
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
