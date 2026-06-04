
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../core/colors/colors.dart';

class CustomCardSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const CustomCardSection({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.white
            : darkModeCardColor,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(width: 1,color: Colors.grey.withOpacity(0.2)),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: child,
    );
  }
}