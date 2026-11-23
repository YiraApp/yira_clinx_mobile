import 'dart:math';

import 'package:flutter/material.dart';

/// Small points of light that rise from the open palm into the glowing orb above it.
class PalmSparklesPainter extends CustomPainter {
  PalmSparklesPainter({
    required this.progress,
    required this.opacity,
    required this.normalizedCenter,
    this.dark = false,
  });

  /// Looping 0 → 1 clock that drives the rise.
  final double progress;

  /// Overall visibility (follows the hand, gone once the cards converge).
  final double opacity;

  /// The hand's centre as a fraction of the screen.
  final Offset normalizedCenter;

  final bool dark;

  static final List<(double, double, double, double)> _sparks = () {
    final random = Random(11);
    // (start x offset, phase, size, speed)
    return List.generate(18, (_) => ((random.nextDouble() - 0.5) * 0.22, random.nextDouble(), 1.2 + random.nextDouble() * 2.2, 0.8 + random.nextDouble() * 0.7));
  }();

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final orb = Offset(size.width * (normalizedCenter.dx + 0.01), size.height * (normalizedCenter.dy - 0.07));
    final palmY = size.height * (normalizedCenter.dy + 0.05);
    final glow = Paint();
    final core = Paint();
    final glowColor = dark ? const Color(0xFF7DD3FC) : const Color(0xFF38BDF8);
    final coreColor = dark ? Colors.white : const Color(0xFF2563EB);

    for (final (dx, phase, radius, speed) in _sparks) {
      final t = (progress * 3 * speed + phase) % 1.0;
      // Rise from the palm, drifting in toward the orb's centre.
      final start = Offset(size.width * (normalizedCenter.dx + dx), palmY);
      final eased = Curves.easeOut.transform(t);
      final position = Offset.lerp(start, orb, eased)!;
      final fade = sin(t * pi) * opacity;
      if (fade <= 0.01) continue;
      glow.color = glowColor.withValues(alpha: 0.30 * fade);
      canvas.drawCircle(position, radius * 2.6, glow);
      core.color = coreColor.withValues(alpha: 0.85 * fade);
      canvas.drawCircle(position, radius * (1 - 0.4 * eased), core);
    }
  }

  @override
  bool shouldRepaint(PalmSparklesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity || oldDelegate.dark != dark;
}
