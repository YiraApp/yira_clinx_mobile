

import 'package:flutter/material.dart';

import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: isDark
            ? Border.all(color: color.withOpacity(0.3), width: 0.5)
            : null,
      ),
      child: CommonText(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          fontFamily: appPoppinFont,
        ),
      ),
    );
  }
}