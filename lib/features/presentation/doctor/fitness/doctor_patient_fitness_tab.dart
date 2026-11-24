import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/widgets/huge_icons.dart';
import 'package:yiraclinics/core/widgets/ios_icons.dart';
import 'package:yiraclinics/features/presentation/patient/fitness/patient_fitness_dashboard_screen.dart';

/// A patient's fitness (steps, sleep, heart rate and more, synced from their phone) on the doctor's
/// patient screen. It opens only when the patient has shared access with this doctor; until then
/// the tab says how to get it.
class DoctorPatientFitnessTab extends StatelessWidget {
  const DoctorPatientFitnessTab({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.hasAccess,
    this.onRequestAccess,
  });

  final String patientId;
  final String patientName;
  final bool hasAccess;
  final VoidCallback? onRequestAccess;

  @override
  Widget build(BuildContext context) {
    if (hasAccess) {
      return PatientFitnessDashboardScreen(
        key: ValueKey('DoctorFitness$patientId'),
        viewPatientId: patientId,
        viewPatientName: patientName,
        embedded: true,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    final name = patientName.trim().isNotEmpty ? patientName.trim() : 'The patient';
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232323) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(HugeIcons.workoutRun, size: 22, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fitness is shared with access',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF121212),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$name's steps, sleep, heart rate and other readings from their phone show here once they give you access.",
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, height: 1.45, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (onRequestAccess != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRequestAccess,
                    icon: const Icon(IosIcons.lock_open_rounded, size: 17),
                    label: const Text('Ask for access',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
