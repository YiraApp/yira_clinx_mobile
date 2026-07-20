import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../colors/colors.dart'; // Adjust path if needed

class YiraClinxLogo extends StatelessWidget {
  final bool isTablet;
  final double? customSize;
  final Color? customColor;
  final bool isFlat;
  final BorderRadius? borderRadius;

  final double padding;
  final bool isShadow;

  const YiraClinxLogo({
    super.key,
    required this.isTablet,
    this.customSize,
    this.customColor,
    this.isFlat = false,
    this.borderRadius,  this.padding = 2,  this.isShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final double defaultSize = isTablet ? 78.0 : 68.0;
    final double targetSize = customSize ?? defaultSize;

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final Color logoColor = customColor ?? primaryColor;

    if (isFlat) {
      return Center(
        child: SizedBox(
          height: targetSize,
          width: targetSize,
          child: SvgPicture.asset(
            appLogo,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    final List<Color> backgroundGradient = isDarkMode
        ? [
      theme.cardColor.withOpacity(0.8),
      theme.cardColor.withOpacity(0.3),
    ]
        : [
      Colors.white,
      logoColor.withOpacity(0.04),
    ];

    final BoxShape containerShape = borderRadius == null ? BoxShape.circle : BoxShape.rectangle;

    return Center(
      child: Container(
        height: targetSize,
        width: targetSize,
        decoration: BoxDecoration(
          shape: containerShape,
          borderRadius: borderRadius, // Will apply smoothly if shape is rectangle
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundGradient,
          ),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.12) : logoColor.withOpacity(0.14),
            width: 1.5,
          ),
          boxShadow:isShadow?[]: [
            BoxShadow(
              color: logoColor.withOpacity(isDarkMode ? 0.08 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.4) : const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(targetSize),
            child: SvgPicture.asset(
              appLogo,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}