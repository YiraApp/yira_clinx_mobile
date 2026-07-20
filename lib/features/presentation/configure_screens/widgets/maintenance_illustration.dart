
import 'package:flutter/material.dart';

class MaintenanceIllustration extends StatelessWidget {
  final bool isTab;
  const MaintenanceIllustration({super.key, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double containerSize = isTab ? 140 : 120;

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: isDark
            ? theme.primaryColor.withOpacity(0.12)
            : theme.primaryColor.withOpacity(0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? theme.primaryColor.withOpacity(0.2)
              : theme.primaryColor.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.handyman_rounded,
          size: containerSize * 0.45,
          color: theme.primaryColor,
        ),
      ),
    );
  }
}