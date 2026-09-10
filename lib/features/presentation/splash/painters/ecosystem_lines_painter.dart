import 'dart:math';

import 'package:flutter/material.dart';

/// Custom painter that draws crisp royal-blue laser paths for Light Mode.
class EcosystemLinesPainter extends CustomPainter {
  final List<Offset> iconPositions;
  final double revealProgress;
  final double convergence;
  final double dashOffset;
  final Offset convergenceCenter;

  EcosystemLinesPainter({
    required this.iconPositions,
    required this.revealProgress,
    required this.convergence,
    required this.dashOffset,
    required this.convergenceCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (revealProgress <= 0.0 || iconPositions.length < 2) return;

    final actualPositions = iconPositions.map((p) {
      return Offset(p.dx * size.width, p.dy * size.height);
    }).toList();

    final center = Offset(
      convergenceCenter.dx * size.width,
      convergenceCenter.dy * size.height,
    );

    // 1. Draw circumferential orbit guide ring
    _drawOrbitRing(canvas, center, actualPositions);

    // 2. Draw radial laser beams
    for (int i = 0; i < actualPositions.length; i++) {
      final p = actualPositions[i];
      _drawRadialLaser(canvas, center, p, i);
    }
  }

  void _drawOrbitRing(
      Canvas canvas, Offset center, List<Offset> positions) {
    if (convergence >= 0.95) return;

    final ringOpacity =
        (revealProgress * 0.35 * (1.0 - pow(convergence, 1.4))).clamp(0.0, 1.0);
    if (ringOpacity <= 0.0) return;

    for (int i = 0; i < positions.length; i++) {
      final nextIdx = (i + 1) % positions.length;
      final p1 = positions[i];
      final p2 = positions[nextIdx];

      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;
      final towardCenterX = (center.dx - midX) * 0.18;
      final towardCenterY = (center.dy - midY) * 0.18;

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(
            midX + towardCenterX, midY + towardCenterY, p2.dx, p2.dy);

      final arcPaint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: ringOpacity * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, arcPaint);
    }
  }

  void _drawRadialLaser(
      Canvas canvas, Offset center, Offset target, int index) {
    final lineReveal =
        ((revealProgress - index * 0.04).clamp(0.0, 1.0) * 1.3).clamp(0.0, 1.0);
    if (lineReveal <= 0.0) return;

    final dx = target.dx - center.dx;
    final dy = target.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance < 1.0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    final currentDistance = distance * lineReveal;
    final endPoint = Offset(
        center.dx + unitX * currentDistance, center.dy + unitY * currentDistance);

    final lineOpacity =
        (lineReveal * 0.45 * (1.0 - pow(convergence, 1.8))).clamp(0.0, 1.0);

    // Soft laser glow line
    final glowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: lineOpacity * 0.5)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(center, endPoint, glowPaint);

    // Core crisp royal blue beam
    final corePaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: lineOpacity)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, endPoint, corePaint);

    // Traveling photon data pulse flowing inward toward center
    final pulseT = (dashOffset + index * 0.125) % 1.0;
    final pulseDist = distance * (1.0 - pulseT);

    if (pulseDist <= currentDistance) {
      final pulseX = center.dx + unitX * pulseDist;
      final pulseY = center.dy + unitY * pulseDist;
      final pulsePos = Offset(pulseX, pulseY);

      // Photon glow
      final photonGlow = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: lineOpacity * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      canvas.drawCircle(pulsePos, 3.8, photonGlow);

      // Photon core
      final photonCore = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: lineOpacity * 0.95);
      canvas.drawCircle(pulsePos, 2.0, photonCore);
    }
  }

  @override
  bool shouldRepaint(EcosystemLinesPainter oldDelegate) {
    return oldDelegate.revealProgress != revealProgress ||
        oldDelegate.convergence != convergence ||
        oldDelegate.dashOffset != dashOffset;
  }
}
