import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Animated background painter for the Yira Light Mode splash screen.
///
/// Renders a soft, luminous healthcare gradient (pristine white + soft ice blue)
/// with subtle floating bioluminescent particles.
class SplashBackgroundPainter extends CustomPainter {
  final double animationValue;
  final double fadeIn;
  final List<SplashParticle> _particles;

  SplashBackgroundPainter({
    required this.animationValue,
    this.fadeIn = 1.0,
    required List<SplashParticle> particles,
  }) : _particles = particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (fadeIn <= 0.005) return;
    _drawGradientBackground(canvas, size);
    _drawParticles(canvas, size);
  }

  void _drawGradientBackground(Canvas canvas, Size size) {
    // Gentle shifting center of the light radial glow
    final centerX = size.width * 0.5 + sin(animationValue * 2 * pi) * 15;
    final centerY = size.height * 0.42 + cos(animationValue * 2 * pi) * 12;

    // Clean, crisp medical light background with fadeIn alpha
    final baseGradient = ui.Gradient.radial(
      Offset(centerX, centerY),
      size.height * 0.85,
      [
        Color(0xFFE6F0FA).withValues(alpha: fadeIn), // Soft luminous ice blue aura
        Color(0xFFF1F6FD).withValues(alpha: fadeIn), // Delicate sky white
        Color(0xFFF8FAFC).withValues(alpha: fadeIn), // Crisp clinical white
      ],
      [0.0, 0.55, 1.0],
    );

    final paint = Paint()..shader = baseGradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle royal blue ambient energy pulse at center
    final pulse = (0.05 + 0.03 * sin(animationValue * 2 * pi)) * fadeIn;
    final accentGradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.42),
      size.width * 0.75,
      [
        Color(0xFF2563EB).withValues(alpha: pulse),
        Color(0xFF38BDF8).withValues(alpha: pulse * 0.5),
        Colors.transparent,
      ],
      [0.0, 0.45, 1.0],
    );
    final accentPaint = Paint()..shader = accentGradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), accentPaint);
  }

  void _drawParticles(Canvas canvas, Size size) {
    final glowPaint = Paint()..style = PaintingStyle.fill;
    final corePaint = Paint()..style = PaintingStyle.fill;

    for (final particle in _particles) {
      final progress = (animationValue + particle.phaseOffset) % 1.0;

      final x = particle.baseX * size.width +
          sin(progress * 2 * pi * particle.wobbleFreq) *
              particle.wobbleAmp *
              size.width;
      final y = (particle.baseY - progress * particle.speed) % 1.0 * size.height;

      final opacity =
          ((sin(progress * pi) * particle.maxOpacity) * fadeIn).clamp(0.0, 1.0);

      if (opacity <= 0.005) continue;

      final pos = Offset(x, y);

      // Hardware-accelerated soft halo (no expensive raster blur pass)
      glowPaint.color = particle.color.withValues(alpha: opacity * 0.25);
      canvas.drawCircle(pos, particle.radius * 2.2, glowPaint);

      // Core particle
      corePaint.color = particle.color.withValues(alpha: opacity * 0.90);
      canvas.drawCircle(pos, particle.radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(SplashBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.fadeIn != fadeIn;
  }
}

/// Generates a list of particles for the light mode background.
List<SplashParticle> generateSplashParticles({int count = 32}) {
  final random = Random(42);
  final colors = [
    const Color(0xFF2563EB), // Royal Blue
    const Color(0xFF0284C7), // Sky Cerulean
    const Color(0xFF3B82F6), // Vibrant Blue
    const Color(0xFF60A5FA), // Soft Blue
    const Color(0xFF06B6D4), // Cyan
  ];

  return List.generate(count, (i) {
    return SplashParticle(
      baseX: random.nextDouble(),
      baseY: random.nextDouble(),
      radius: 1.5 + random.nextDouble() * 2.8,
      speed: 0.10 + random.nextDouble() * 0.22,
      maxOpacity: 0.15 + random.nextDouble() * 0.25, // Gentle in light mode
      phaseOffset: random.nextDouble(),
      wobbleFreq: 1.0 + random.nextDouble() * 2.0,
      wobbleAmp: 0.01 + random.nextDouble() * 0.02,
      color: colors[random.nextInt(colors.length)],
    );
  });
}

/// A single floating particle in the background.
class SplashParticle {
  final double baseX;
  final double baseY;
  final double radius;
  final double speed;
  final double maxOpacity;
  final double phaseOffset;
  final double wobbleFreq;
  final double wobbleAmp;
  final Color color;

  const SplashParticle({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.speed,
    required this.maxOpacity,
    required this.phaseOffset,
    required this.wobbleFreq,
    required this.wobbleAmp,
    required this.color,
  });
}
