import 'package:flutter/material.dart';
import '../../config/yira_colors/yira_colors.dart';
import '../common_size_helpers/common_size_helpers.dart';

class VerticalScalePainter extends CustomPainter {
  final double value;
  final bool isMajor;
  final BuildContext context;
  final String unit;

  VerticalScalePainter({
    required this.value,
    required this.isMajor,
    required this.context,
    this.unit = 'cm',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = textLightDarkColor
      ..strokeWidth = isMajor ? 3.0 : 1.5;

    final double tickWidth = isMajor ? 35.0 : 18.0;
    double yCenter = size.height / 2;

    canvas.drawLine(
      Offset(0, yCenter),
      Offset(tickWidth, yCenter),
      paint,
    );

    if (isMajor) {
      String displayValue = unit == 'in'
          ? value.toStringAsFixed(1)
          : value.toStringAsFixed(0);

      final textSpan = TextSpan(
        text: displayValue,
        style: TextStyle(
          color: textLightDarkColor,
          fontSize: isTablet(context)
              ? displayWidth(context) * 0.02
              : displayWidth(context) * 0.04,
          fontWeight: FontWeight.bold,
        ),
      );

      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(tickWidth + 10, yCenter - (tp.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant VerticalScalePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.unit != unit;
  }
}