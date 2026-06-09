
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import 'patient_info_card.dart';

class PatientSummaryCard extends StatelessWidget {
  final PatientProfileEntity patient;
  final bool isTab;
  const PatientSummaryCard({super.key, required this.patient, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PatientInfoCard(
      isTab: isTab,
      title: 'Summary',
      titleIcon: Icons.description_outlined,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.blueGrey.withOpacity(0.1) : const Color(0xFFF0F4F9),
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border(
            left: BorderSide(
              color: isDark ? Colors.blue : const Color(0xFF1A73E8),
              width: 4,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: isDark ? Colors.blue.withOpacity(0.4) : const Color(0xFF1A73E8).withOpacity(0.3),
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                patient.summary,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize:isTab? displayWidth(context) * 0.02: displayWidth(context) * 0.032,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: isDark ? Colors.grey : Colors.grey[800],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}