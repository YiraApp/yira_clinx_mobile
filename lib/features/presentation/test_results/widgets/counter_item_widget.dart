


import 'package:flutter/material.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class CounterItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const CounterItem({super.key, 
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Numeric Value
        CommonText(
          value,
          style: TextStyle(
            fontSize: displayWidth(context)*0.045,
            fontWeight: FontWeight.w600,
            fontFamily: appPoppinFont,
            color: valueColor ,
          ),
        ),
        const SizedBox(height: 4),
        CommonText(
          label,
          style: TextStyle(
            fontSize: displayWidth(context)*0.032,
            fontFamily: appPoppinFont,
            color:  Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}