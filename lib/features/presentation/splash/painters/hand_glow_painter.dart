import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Custom painter for Light Mode biometric aura, vitality core, and shockwave.
class HandGlowPainter extends CustomPainter {
  /// Fade in progress of the hand aura (0.0 to 1.0)
  final double fadeIn;

  /// Oscillating heartbeat/breathing pulse value (-1.0 to 1.0)
  final double glowPulse;

  /// Overall scale factor
  final double scale;

  /// Convergence shockwave progress (0.0 = none, 1.0 = full shockwave explosion)
  final double shockwaveProgress;

  /// Normalized center position
  final Offset normalizedCenter;

  HandGlowPainter({
    required this.fadeIn,
    required this.glowPulse,
    required this.scale,
    this.shockwaveProgress = 0.0,
    this.normalizedCenter = const Offset(0.5, 0.48),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fadeIn <= 0.0 && shockwaveProgress <= 0.0) return;

    final center = Offset(size.width * normalizedCenter.dx, size.height * normalizedCenter.dy);
    final coreRadius = size.width * 0.34 * scale;

    canvas.save();

    if (fadeIn > 0.0) {
      // 1. Soft ambient royal blue glow
      _drawAmbientGlow(canvas, center, coreRadius);

      // 2. High-contrast biometric precision rings
      _drawBiometricRings(canvas, center, coreRadius);

      // 3. Vitality core flare
      _drawVitalityCore(canvas, center, coreRadius);
    }

    // 4. Convergence shockwave
    if (shockwaveProgress > 0.0) {
      _drawShockwave(canvas, center, size);
    }

    canvas.restore();
  }

  void _drawAmbientGlow(Canvas canvas, Offset center, double radius) {
    final pulseScale = 1.0 + glowPulse * 0.07;

    // Outer soft blue halo
    final outerPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: fadeIn * 0.14)
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, radius * 0.9 * pulseScale);
    canvas.drawCircle(center, radius * 1.05 * pulseScale, outerPaint);

    // Mid blue halo
    final midPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: fadeIn * 0.18)
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, radius * 0.5 * pulseScale);
    canvas.drawCircle(center, radius * 0.65 * pulseScale, midPaint);
  }

  void _drawBiometricRings(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ring 1: Inner subtle blue ring
    ringPaint
      ..color = const Color(0xFF2563EB).withValues(alpha: fadeIn * 0.35)
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(center, radius * 0.80, ringPaint);

    // Ring 2: Outer dashed precision ring
    ringPaint
      ..color = const Color(0xFF0284C7).withValues(alpha: fadeIn * 0.45)
      ..strokeWidth = 1.2
      ..maskFilter = null;

    const segmentCount = 36;
    final r = radius * 0.94;
    for (int i = 0; i < segmentCount; i++) {
      if (i % 3 == 0) continue; // Dashed gaps
      final startAngle = (i * 2 * pi / segmentCount);
      final sweepAngle = (2 * pi / segmentCount) * 0.65;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        sweepAngle,
        false,
        ringPaint,
      );
    }

    // 4 Precision crosshair ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: fadeIn * 0.55)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = i * (pi / 2);
      final p1 = Offset(
          center.dx + cos(angle) * (r - 6), center.dy + sin(angle) * (r - 6));
      final p2 = Offset(
          center.dx + cos(angle) * (r + 6), center.dy + sin(angle) * (r + 6));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  void _drawVitalityCore(Canvas canvas, Offset center, double radius) {
    final corePulse = 1.0 + glowPulse * 0.12;
    final orbRadius = radius * 0.24 * corePulse;

    final coreGradient = ui.Gradient.radial(
      center,
      orbRadius,
      [
        const Color(0xFF2563EB).withValues(alpha: fadeIn * 0.35),
        const Color(0xFF38BDF8).withValues(alpha: fadeIn * 0.15),
        Colors.transparent,
      ],
      [0.0, 0.55, 1.0],
    );

    final corePaint = Paint()..shader = coreGradient;
    canvas.drawCircle(center, orbRadius, corePaint);
  }

  void _drawShockwave(Canvas canvas, Offset center, Size size) {
    final maxRadius = size.height * 0.65;
    final currentRadius = maxRadius * shockwaveProgress;
    final opacity = (1.0 - shockwaveProgress).clamp(0.0, 1.0);

    // Primary shockwave ring in vibrant royal blue
    final wavePaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * (1.0 - shockwaveProgress * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, currentRadius, wavePaint);

    // Cyan trailing ring
    if (shockwaveProgress > 0.15) {
      final trailRadius = currentRadius * 0.78;
      final trailOpacity = (opacity * 0.45).clamp(0.0, 1.0);
      final trailPaint = Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: trailOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, trailRadius, trailPaint);
    }

    // Light flash
    if (shockwaveProgress < 0.45) {
      final flashOpacity =
          ((1.0 - shockwaveProgress / 0.45) * 0.7).clamp(0.0, 1.0);
      final flashPaint = Paint()
        ..color = const Color(0xFFE0EDFF).withValues(alpha: flashOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.4);
      canvas.drawCircle(center, size.width * 0.35, flashPaint);
    }
  }

  @override
  bool shouldRepaint(HandGlowPainter oldDelegate) {
    return oldDelegate.fadeIn != fadeIn ||
        oldDelegate.glowPulse != glowPulse ||
        oldDelegate.scale != scale ||
        oldDelegate.shockwaveProgress != shockwaveProgress;
  }
}
