import 'dart:ui';

import 'package:flutter/material.dart';

/// An attractive, vibrant 3D PNG healthcare service node widget for Light Mode.
///
/// Features large, high-res colorful 3D PNG illustrations
/// on elevated glassmorphic circular/rounded cards with drop shadows.
class ServiceIconWidget extends StatelessWidget {
  final HealthcareService service;
  final double opacity;
  final double scale;

  const ServiceIconWidget({
    super.key,
    required this.service,
    required this.opacity,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.01) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3D Elevated Glassmorphic Card (Enlarged Size: 70x70)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.92),
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                boxShadow: [
                  // Soft ambient shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  // Rich vibrant color glow
                  BoxShadow(
                    color: service.glowColor.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: Image.asset(
                        service.assetPath,
                        width: 54,
                        height: 54,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 5),

            // High-Contrast Bold Text Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                service.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  color: Color(0xFF0F172A), // Crisp dark slate
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class representing a healthcare ecosystem node with PNG illustration.
class HealthcareService {
  final String assetPath;
  final String label;
  final Color glowColor;

  const HealthcareService({
    required this.assetPath,
    required this.label,
    required this.glowColor,
  });
}

/// The 8 primary healthcare services with vivid 3D PNG illustrations.
const List<HealthcareService> splashHealthcareServices = [
  // 1. Diet & Food: Fresh salad bowl + apple + chicken combined illustration!
  HealthcareService(
    assetPath: 'assets/images/ic_3d_diet.png',
    label: 'Diet & Food',
    glowColor: Color(0xFF10B981), // Emerald Green
  ),

  // 2. Doctor & Specialists: Friendly 3D doctor with stethoscope
  HealthcareService(
    assetPath: 'assets/images/ic_3d_doctor.png',
    label: 'Specialists',
    glowColor: Color(0xFF2563EB), // Royal Blue
  ),

  // 3. Heart & Vitals: 3D glossy red beating heart with acoustic pulse
  HealthcareService(
    assetPath: 'assets/images/ic_3d_vitals.png',
    label: 'Heart & Vitals',
    glowColor: Color(0xFFEF4444), // Ruby Red
  ),

  // 4. Fitness & Gym: 3D athletic strength
  HealthcareService(
    assetPath: 'assets/images/ic_3d_fitness.png',
    label: 'Fitness & Gym',
    glowColor: Color(0xFFF97316), // Flame Orange
  ),

  // 5. Appointments & Scheduling: 3D calendar
  HealthcareService(
    assetPath: 'assets/images/ic_3d_calendar.png',
    label: 'Appointments',
    glowColor: Color(0xFFF59E0B), // Golden Amber
  ),

  // 6. AI Diagnosis: 3D vibrant brain
  HealthcareService(
    assetPath: 'assets/images/ic_3d_ai.png',
    label: 'AI Diagnosis',
    glowColor: Color(0xFF8B5CF6), // Violet Purple
  ),

  // 7. Video Consultation: 3D smartphone live doctor call + 3D video camera + stethoscope
  HealthcareService(
    assetPath: 'assets/images/ic_3d_teleconsult.png',
    label: 'Video Consult',
    glowColor: Color(0xFF06B6D4), // Cyan
  ),

  // 8. Health Records: 3D medical records clipboard
  HealthcareService(
    assetPath: 'assets/images/ic_3d_records.png',
    label: 'Health Records',
    glowColor: Color(0xFF4F46E5), // Indigo
  ),
];
