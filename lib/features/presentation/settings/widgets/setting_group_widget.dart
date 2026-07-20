
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

class SettingsGroupCard extends StatelessWidget {
  final List<Widget> children;
  final bool isTab;

  const SettingsGroupCard({super.key, required this.children, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 0.5,color: Colors.grey.withOpacity(0.2)),
        color: isDark ? CupertinoColors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        boxShadow:isDark ?[]: [
          BoxShadow(
            color:  Colors.grey.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}