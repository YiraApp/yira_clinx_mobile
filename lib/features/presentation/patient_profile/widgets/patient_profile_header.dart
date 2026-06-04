
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';

class PatientProfileHeader extends StatelessWidget {
  final PatientProfileEntity patient;

  const PatientProfileHeader({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                patient.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase(),
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  color: isDark ? Colors.blue[300] : primaryColor,
                  fontSize: displayWidth(context) * 0.035,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      patient.name,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: displayWidth(context) * 0.035,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green.withOpacity(0.4) : Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          fontSize: displayWidth(context) * 0.032,
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.green[300] : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.id} | ${patient.dob} | ${patient.gender} | ${patient.bloodGroup}',
                  style: TextStyle(
                    fontSize: displayWidth(context) * 0.032,
                    fontFamily: appPoppinFont,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}