import 'package:flutter/material.dart';

class UpdateIllustration extends StatelessWidget {
  const UpdateIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 140,
      height: 140,
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
          Icons.rocket_launch_rounded,
          size: 60,
          color: theme.primaryColor,
        ),
      ),
    );
  }
}