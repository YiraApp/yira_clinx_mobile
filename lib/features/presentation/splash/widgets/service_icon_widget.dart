import 'package:flutter/material.dart';

import '../../../../core/widgets/phosphor_icons.dart';

/// Card for one healthcare service in the splash: a frosted white tile holding a glossy gradient
/// chip with a crisp two-tone glyph, and the service name underneath.
/// Built once and cached, so animation ticks don't rebuild it.
class ServiceCardVisual extends StatelessWidget {
  final HealthcareService service;

  /// Dark glass tile and label for the dark splash.
  final bool dark;

  const ServiceCardVisual({super.key, required this.service, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final (light, dark) = service.gradient;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: this.dark ? const [Color(0xFF2A2A2F), Color(0xFF1A1A1D)] : const [Colors.white, Color(0xFFF4F7FC)],
            ),
            border: Border.all(color: this.dark ? Colors.white.withValues(alpha: 0.10) : Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: this.dark ? const Color(0x66000000) : const Color(0x14000000), blurRadius: 10, offset: const Offset(0, 4)),
              BoxShadow(color: dark.withValues(alpha: this.dark ? 0.35 : 0.22), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [light, dark],
              ),
              boxShadow: [BoxShadow(color: dark.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glossy highlight across the top of the chip
                Positioned(
                  top: 2,
                  left: 4,
                  right: 4,
                  height: 18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: 0.38), Colors.white.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
                PhosphorIcon(service.icon, size: 26, color: Colors.white, duotoneSecondaryOpacity: 0.32),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: this.dark ? const Color(0xFF1E1E22).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: this.dark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE6EBF3)),
            boxShadow: [BoxShadow(color: this.dark ? const Color(0x55000000) : const Color(0x0F000000), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Text(
            service.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: this.dark ? Colors.white : const Color(0xFF111111),
              letterSpacing: 0.1,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// A service node with its current opacity and scale.
class ServiceIconWidget extends StatelessWidget {
  final HealthcareService service;
  final double opacity;
  final double scale;
  final Widget? child;

  const ServiceIconWidget({
    super.key,
    required this.service,
    required this.opacity,
    this.scale = 1.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.005 || scale <= 0.005) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: child ?? ServiceCardVisual(service: service),
      ),
    );
  }
}

/// One healthcare service shown around the hand: its glyph, name and chip gradient.
class HealthcareService {
  final IconData icon;
  final String label;

  /// Chip gradient, (light, dark).
  final (Color, Color) gradient;

  const HealthcareService({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  /// The colour of the glow and connecting accents for this service.
  Color get glowColor => gradient.$2;
}

/// The 8 services, in orbit order (starting at the top, clockwise).
const List<HealthcareService> splashHealthcareServices = [
  HealthcareService(
    icon: PhosphorIconsDuotone.bowlFood,
    label: 'Diet & Food',
    gradient: (Color(0xFF34D399), Color(0xFF059669)),
  ),
  HealthcareService(
    icon: PhosphorIconsDuotone.stethoscope,
    label: 'Specialists',
    gradient: (Color(0xFF60A5FA), Color(0xFF1D4ED8)),
  ),
  HealthcareService(
    icon: PhosphorIconsDuotone.heartbeat,
    label: 'Heart & Vitals',
    gradient: (Color(0xFFFB7185), Color(0xFFE11D48)),
  ),
  HealthcareService(
    icon: PhosphorIconsFill.footprints,
    label: 'Fitness',
    gradient: (Color(0xFFFDBA74), Color(0xFFEA580C)),
  ),
  HealthcareService(
    icon: PhosphorIconsDuotone.calendarCheck,
    label: 'Appointments',
    gradient: (Color(0xFF818CF8), Color(0xFF4338CA)),
  ),
  HealthcareService(
    icon: PhosphorIconsDuotone.sparkle,
    label: 'AI Diagnosis',
    gradient: (Color(0xFFC4B5FD), Color(0xFF7C3AED)),
  ),
  HealthcareService(
    icon: PhosphorIconsDuotone.videoCamera,
    label: 'Video Consult',
    gradient: (Color(0xFF67E8F9), Color(0xFF0891B2)),
  ),
  HealthcareService(
    icon: PhosphorIconsDuotone.fileText,
    label: 'Health Records',
    gradient: (Color(0xFF93C5FD), Color(0xFF2563EB)),
  ),
];
