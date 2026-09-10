import 'package:flutter/material.dart';

enum ServiceAnimationType {
  pulse,
  float,
  heartbeat,
  bob,
  glow,
}

enum ServiceIconType {
  appointment,
  records,
  vitals,
  family,
  suggestions,
}

/// Clean, monochromatic static service icon widget.
///
/// Retains StatefulWidget structure with State class to guarantee Flutter
/// hot reload and reassembly succeed smoothly without state type mismatch.
class AnimatedServiceIcon extends StatefulWidget {
  final IconData icon;
  final ServiceAnimationType animationType;
  final int staggerDelayMs;
  final double size;
  final Color? color;

  // Backwards compatibility optional fields
  final ServiceIconType? iconType;
  final String? assetPath;
  final IconData? fallbackIcon;
  final List<Color>? gradientColors;

  const AnimatedServiceIcon({
    super.key,
    required this.icon,
    this.animationType = ServiceAnimationType.pulse,
    this.staggerDelayMs = 0,
    this.size = 46.0,
    this.color,
    this.iconType,
    this.assetPath,
    this.fallbackIcon,
    this.gradientColors,
  });

  @override
  State<AnimatedServiceIcon> createState() => _AnimatedServiceIconState();
}

class _AnimatedServiceIconState extends State<AnimatedServiceIcon> {
  // ignore: unused_element
  AnimationController? get _controller => null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.color ?? Theme.of(context).primaryColor;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: primaryColor.withValues(
          alpha: isDark ? 0.16 : 0.08,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: primaryColor.withValues(
            alpha: isDark ? 0.26 : 0.14,
          ),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(
              alpha: isDark ? 0.12 : 0.06,
            ),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          widget.icon,
          size: widget.size * 0.52,
          color: primaryColor,
        ),
      ),
    );
  }
}
