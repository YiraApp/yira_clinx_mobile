import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

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
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.w500,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}