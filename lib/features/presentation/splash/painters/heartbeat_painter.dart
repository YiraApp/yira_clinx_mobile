import 'dart:math';

import 'package:flutter/material.dart';

/// Custom painter for the animated electric-blue ECG heartbeat waveform in Light Mode.
class HeartbeatPainter extends CustomPainter {
  final double revealProgress;
  final double opacity;
  final double loopValue;

  HeartbeatPainter({
    required this.revealProgress,
    required this.opacity,
    required this.loopValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0 || revealProgress <= 0.0) return;

    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    final points = _generateHeartbeatPoints(w, midY, h);
    if (points.isEmpty) return;

    final rawIndex = (points.length - 1) * revealProgress;
    final floorIndex = rawIndex.floor().clamp(0, points.length - 1);
    final frac = (rawIndex - floorIndex).clamp(0.0, 1.0);

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i <= floorIndex; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    Offset tipPoint = points[floorIndex];
    if (floorIndex < points.length - 1 && frac > 0.0) {
      final p1 = points[floorIndex];
      final p2 = points[floorIndex + 1];
      tipPoint = Offset(
        p1.dx + (p2.dx - p1.dx) * frac,
        p1.dy + (p2.dy - p1.dy) * frac,
      );
      path.lineTo(tipPoint.dx, tipPoint.dy);
    }

    // Outer soft glow layer (layered stroke, zero GPU blur pass)
    final glowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: opacity * 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    // Core crisp line (Royal Blue)
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: opacity * 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Glowing photon tip at the leading edge
    if (revealProgress > 0.02 && revealProgress < 1.0) {
      final tipGlow = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: opacity * 0.50);
      canvas.drawCircle(tipPoint, 4.5, tipGlow);

      final tipCore = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: opacity);
      canvas.drawCircle(tipPoint, 2.2, tipCore);
    }
  }

  List<Offset> _generateHeartbeatPoints(
      double width, double midY, double height) {
    final points = <Offset>[];
    final segmentWidth = width;
    final amplitude = height * 0.40;
    const totalSteps = 60; // 60 steps provide ultra smooth curve with half the allocations

    for (int i = 0; i <= totalSteps; i++) {
      final t = i / totalSteps;
      final x = t * segmentWidth;
      final cycleT = ((t * 2.0 + loopValue) % 1.0);

      double y = midY;

      if (cycleT < 0.15) {
        y = midY;
      } else if (cycleT < 0.20) {
        final localT = (cycleT - 0.15) / 0.05;
        y = midY - sin(localT * pi) * amplitude * 0.15;
      } else if (cycleT < 0.30) {
        y = midY;
      } else if (cycleT < 0.33) {
        final localT = (cycleT - 0.30) / 0.03;
        y = midY + sin(localT * pi) * amplitude * 0.12;
      } else if (cycleT < 0.38) {
        final localT = (cycleT - 0.33) / 0.05;
        y = midY - sin(localT * pi) * amplitude * 0.95;
      } else if (cycleT < 0.42) {
        final localT = (cycleT - 0.38) / 0.04;
        y = midY + sin(localT * pi) * amplitude * 0.22;
      } else if (cycleT < 0.54) {
        y = midY;
      } else if (cycleT < 0.64) {
        final localT = (cycleT - 0.54) / 0.10;
        y = midY - sin(localT * pi) * amplitude * 0.22;
      } else {
        y = midY;
      }

      points.add(Offset(x, y));
    }

    return points;
  }

  @override
  bool shouldRepaint(HeartbeatPainter oldDelegate) {
    return oldDelegate.revealProgress != revealProgress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.loopValue != loopValue;
  }
}
