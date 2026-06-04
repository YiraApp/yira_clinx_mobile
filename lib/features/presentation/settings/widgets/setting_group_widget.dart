
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsGroupCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroupCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 0.5,color: Colors.grey.withOpacity(0.2)),
        color: isDark ? CupertinoColors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(8),
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