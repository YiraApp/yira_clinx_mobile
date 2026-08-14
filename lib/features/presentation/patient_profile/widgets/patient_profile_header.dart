import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';

class PatientProfileHeader extends StatelessWidget {
  final PatientProfileEntity patient;
  final bool isTab;
  final VoidCallback? onBack;
  final Widget? tabBar;

  const PatientProfileHeader({
    super.key,
    required this.patient,
    required this.isTab,
    this.onBack,
    this.tabBar,
  });

  @override
  Widget build(BuildContext context) {
    final initials = patient.name.trim().isNotEmpty
        ? patient.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'PT';

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onBack != null)
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'CONFIRMED',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Patient details row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Patient Avatar (White Circle, Blue Initials)
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Patient Name & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(patient.gender).toUpperCase()}, ${patient.dob} | ${patient.bloodGroup}',
                        style: TextStyle(
                          fontSize: isTab ? 13 : 12,
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '11:00 AM',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: appPoppinFont,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.medical_services_outlined, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            'DR. RAJESH NAGALINGAM',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: appPoppinFont,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (tabBar != null) ...[
              const SizedBox(height: 16),
              tabBar!,
            ],
          ],
        ),
      ),
    );
  }
}