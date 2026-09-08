import 'dart:math';
import 'package:flutter/material.dart';

/// Anatomical position data for a vital point on the human body.
class VitalPointData {
  /// Normalized position on the body image (0.0 - 1.0)
  final Offset bodyPosition;

  /// The exact screen coordinate where the pill leader line anchors
  final Offset cardAnchor;

  /// Accent color for this vital
  final Color color;

  /// Current pulse phase (0.0 - 1.0) for animation
  final double pulsePhase;

  /// Whether this vital has recorded data
  final bool hasData;

  /// Whether this vital is currently selected/highlighted
  final bool isSelected;

  /// Label for identification
  final String label;

  /// Whether the card/pill is on the left side
  final bool isLeft;

  const VitalPointData({
    required this.bodyPosition,
    required this.cardAnchor,
    required this.color,
    required this.pulsePhase,
    required this.hasData,
    this.isSelected = false,
    required this.label,
    required this.isLeft,
  });
}

/// Paints glowing vital hotspots, anatomical leader lines, cardiac ripples,
/// holographic scan beams, and floating particles locked to the 3D human body.
class VitalPointPainter extends CustomPainter {
  /// The exact rendered rectangle of the 3D body image within the container
  final Rect imageRect;

  /// Dynamic breathing scale applied to the body image
  final double breathScale;

  final List<VitalPointData> vitalPoints;
  final double heartPulse; // 0.0 - 1.0, synced to heart rate
  final double breathPhase; // 0.0 - 1.0, breathing cycle
  final double entryProgress; // 0.0 - 1.0, staggered entry
  final List<VitalParticle> particles;
  final bool isDark;

  VitalPointPainter({
    required this.imageRect,
    required this.breathScale,
    required this.vitalPoints,
    required this.heartPulse,
    required this.breathPhase,
    required this.entryProgress,
    required this.particles,
    required this.isDark,
  }) : super();

  static const Color _primaryBlue = Color(0xFF2563EB);

  /// Convert normalized coordinates on the body image to exact screen pixels,
  /// factoring in the current breathing scale and image centering.
  Offset getScreenPoint(Offset normalized) {
    final center = imageRect.center;
    final unscaled = Offset(
      imageRect.left + normalized.dx * imageRect.width,
      imageRect.top + normalized.dy * imageRect.height,
    );
    return center + (unscaled - center) * breathScale;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect.isEmpty) return;

    // 1. Draw ambient particles
    _drawParticles(canvas);

    // 2. Draw connection leader lines from pills to anatomical hotspots
    for (final vp in vitalPoints) {
      final progress = _getPointEntryProgress(vp);
      if (progress <= 0) continue;
      _drawConnectionLine(canvas, vp, progress);
    }

    // 3. Draw anatomical vital hotspots
    for (final vp in vitalPoints) {
      final progress = _getPointEntryProgress(vp);
      if (progress <= 0) continue;
      _drawVitalHotspot(canvas, vp, progress);
    }

    // 4. Draw cardiac ripples (synced to heart rate)
    final heartPoint = vitalPoints.where((v) => v.label == 'Heart Rate');
    if (heartPoint.isNotEmpty) {
      _drawHeartRipples(canvas, heartPoint.first);
    }
  }

  double _getPointEntryProgress(VitalPointData vp) {
    final index = vitalPoints.indexOf(vp);
    final staggerDelay = index * 0.10;
    final adjustedProgress =
        ((entryProgress - staggerDelay) / (1.0 - staggerDelay)).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(adjustedProgress);
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final opacity = p.opacity * entryProgress;
      if (opacity <= 0) continue;

      final px = imageRect.left + p.x * imageRect.width;
      final py = imageRect.top + p.y * imageRect.height;

      final paint = Paint()
        ..color = _primaryBlue.withValues(alpha: opacity * (isDark ? 0.5 : 0.35))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), p.radius, paint);
    }
  }

  void _drawConnectionLine(Canvas canvas, VitalPointData vp, double progress) {
    final bodyPoint = getScreenPoint(vp.bodyPosition);
    final anchor = vp.cardAnchor;

    final strokeAlpha = (vp.isSelected
            ? (isDark ? 0.8 : 0.7)
            : (isDark ? 0.4 : 0.3)) *
        progress;

    final linePaint = Paint()
      ..color = vp.color.withValues(alpha: strokeAlpha)
      ..strokeWidth = vp.isSelected ? 1.4 : 1.0
      ..style = PaintingStyle.stroke;

    // Leader path: subtle horizontal dogleg to hotspot
    final path = Path();
    path.moveTo(anchor.dx, anchor.dy);

    // Horizontal elbow towards the hotspot
    final double midX = vp.isLeft
        ? min(anchor.dx + 25, bodyPoint.dx - 8)
        : max(anchor.dx - 25, bodyPoint.dx + 8);

    path.lineTo(midX, anchor.dy);
    path.lineTo(bodyPoint.dx, bodyPoint.dy);

    // Draw dashed path for high-tech holographic aesthetic
    _drawDashedPath(canvas, path, linePaint, dashLength: 3.5, gapLength: 3.0);

    // Anchor connector dot at the pill end
    final anchorDotPaint = Paint()
      ..color = vp.color.withValues(alpha: 0.8 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(anchor, 2.0 * progress, anchorDotPaint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = min(dashLength, metric.length - distance);
        final Path extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  void _drawVitalHotspot(Canvas canvas, VitalPointData vp, double progress) {
    final center = getScreenPoint(vp.bodyPosition);
    final baseRadius = (vp.isSelected ? 9.0 : 7.0) * progress;

    // 1. Outer pulsating aura
    final glowPulse = sin(vp.pulsePhase * 2 * pi) * 2.5;
    final glowRadius = baseRadius + (vp.isSelected ? 9.0 : 6.0) + glowPulse;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          vp.color.withValues(alpha: vp.isSelected ? 0.45 : (vp.hasData ? 0.30 : 0.15)),
          vp.color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // 2. Expanding radar ripple ring
    final rippleRadius = baseRadius + ((vp.pulsePhase * 8.0) % 8.0);
    final rippleOpacity = (1.0 - (vp.pulsePhase % 1.0)) * 0.5 * progress;
    final ripplePaint = Paint()
      ..color = vp.color.withValues(alpha: rippleOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, rippleRadius, ripplePaint);

    // 3. Crisp outer ring
    final ringPaint = Paint()
      ..color = vp.color.withValues(alpha: (vp.hasData ? 0.75 : 0.4) * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = vp.isSelected ? 1.8 : 1.2;
    canvas.drawCircle(center, baseRadius + 1.5, ringPaint);

    // 4. Solid glowing core dot
    final corePaint = Paint()
      ..color = vp.color.withValues(alpha: vp.hasData ? 0.95 : 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius * 0.5, corePaint);

    // 5. White center micro-beacon
    final beaconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius * 0.22, beaconPaint);

    // 6. If selected: high-tech HUD crosshair brackets
    if (vp.isSelected) {
      _drawReticleBrackets(canvas, center, baseRadius + 7.0, vp.color);
    }
  }

  void _drawReticleBrackets(
      Canvas canvas, Offset center, double radius, Color color) {
    final reticlePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const cornerLen = 4.0;
    final r = radius;

    // Top-left bracket
    canvas.drawLine(
        Offset(center.dx - r, center.dy - r + cornerLen),
        Offset(center.dx - r, center.dy - r),
        reticlePaint);
    canvas.drawLine(
        Offset(center.dx - r, center.dy - r),
        Offset(center.dx - r + cornerLen, center.dy - r),
        reticlePaint);

    // Top-right bracket
    canvas.drawLine(
        Offset(center.dx + r - cornerLen, center.dy - r),
        Offset(center.dx + r, center.dy - r),
        reticlePaint);
    canvas.drawLine(
        Offset(center.dx + r, center.dy - r),
        Offset(center.dx + r, center.dy - r + cornerLen),
        reticlePaint);

    // Bottom-left bracket
    canvas.drawLine(
        Offset(center.dx - r, center.dy + r - cornerLen),
        Offset(center.dx - r, center.dy + r),
        reticlePaint);
    canvas.drawLine(
        Offset(center.dx - r, center.dy + r),
        Offset(center.dx - r + cornerLen, center.dy + r),
        reticlePaint);

    // Bottom-right bracket
    canvas.drawLine(
        Offset(center.dx + r - cornerLen, center.dy + r),
        Offset(center.dx + r, center.dy + r),
        reticlePaint);
    canvas.drawLine(
        Offset(center.dx + r, center.dy + r),
        Offset(center.dx + r, center.dy + r - cornerLen),
        reticlePaint);
  }

  void _drawHeartRipples(Canvas canvas, VitalPointData heartVp) {
    final center = getScreenPoint(heartVp.bodyPosition);

    // Two staggered concentric cardiac ripple waves
    for (int i = 0; i < 2; i++) {
      final phase = (heartPulse + i * 0.5) % 1.0;
      final radius = 9 + phase * 22;
      final opacity = (1.0 - phase) * 0.45 * entryProgress;

      if (opacity <= 0) continue;

      final ripplePaint = Paint()
        ..color = const Color(0xFFE11D48).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * (1.0 - phase);

      canvas.drawCircle(center, radius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VitalPointPainter oldDelegate) => true;
}

/// Particle data for the ambient floating particles.
class VitalParticle {
  double x, y;
  double vx, vy;
  double radius;
  double opacity;
  double life;

  VitalParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
    required this.life,
  });
}

/// Manages a pool of particles floating around the 3D human body.
class ParticleSystem {
  final List<VitalParticle> particles = [];
  final Random _rng = Random();
  static const int maxParticles = 24;

  ParticleSystem() {
    _initParticles();
  }

  void _initParticles() {
    for (int i = 0; i < maxParticles; i++) {
      particles.add(_createParticle());
    }
  }

  VitalParticle _createParticle() {
    return VitalParticle(
      x: 0.2 + _rng.nextDouble() * 0.6,
      y: 0.05 + _rng.nextDouble() * 0.9,
      vx: (_rng.nextDouble() - 0.5) * 0.0016,
      vy: (_rng.nextDouble() - 0.5) * 0.001 - 0.0004,
      radius: 1.0 + _rng.nextDouble() * 1.8,
      opacity: 0.2 + _rng.nextDouble() * 0.4,
      life: _rng.nextDouble(),
    );
  }

  void update() {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.life -= 0.003;

      p.opacity = (0.2 + sin(p.life * 10) * 0.3).clamp(0.0, 0.6);

      if (p.life <= 0 || p.x < 0.05 || p.x > 0.95 || p.y < 0 || p.y > 1) {
        particles[i] = _createParticle();
      }
    }
  }

  List<VitalParticle> get activeParticles => particles;
}
