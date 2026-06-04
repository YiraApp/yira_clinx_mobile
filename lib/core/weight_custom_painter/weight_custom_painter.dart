import 'package:flutter/material.dart';

import '../../config/yira_colors/yira_colors.dart';
import '../common_size_helpers/common_size_helpers.dart';

class ScaleTickPainter extends CustomPainter {
  final double value;
  final bool isMajor;
  final BuildContext context;

  ScaleTickPainter({required this.value, required this.isMajor, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = textLightDarkColor
      ..strokeWidth = isMajor ? 3.0 : 2.0;

    final double tickHeight = isMajor ? 38 : 18;

    canvas.drawLine(
      Offset(size.width / 12 - 5, 0),
      Offset(size.width / 12 - 5, tickHeight),
      paint,
    );

    if (isMajor) {
      final textSpan = TextSpan(
        text: value.toStringAsFixed(0),
        style: TextStyle(
          color: textLightDarkColor,
          fontSize:isTablet(context)?displayWidth(context) * 0.025: displayWidth(context) * 0.05,
          fontWeight: FontWeight.w500,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(size.width / 12-5 - tp.width / 2, tickHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}