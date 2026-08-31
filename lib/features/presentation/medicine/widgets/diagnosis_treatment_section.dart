import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class DiagnosisTreatmentSection extends StatelessWidget {
  final TextEditingController diagnosisController;
  final TextEditingController treatmentPlanController;
  final TextEditingController? doctorNotesController;
  final bool isTab;
  final Function(String term, String? code)? onDiagnosisConceptSelected;

  const DiagnosisTreatmentSection({
    super.key,
    required this.diagnosisController,
    required this.treatmentPlanController,
    this.doctorNotesController,
    required this.isTab,
    this.onDiagnosisConceptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Icon Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.healing_outlined,
                  size: 20,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Diagnosis & Treatment Plan",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 17 : 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Clinical diagnosis, doctor notes & advice",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12 : 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
          ),
          const SizedBox(height: 16),

          // Diagnosis Standard Text Input Field
          Row(
            children: [
              const Icon(Icons.local_hospital_outlined, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(
                "Clinical Diagnosis",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: diagnosisController,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 14 : 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: "Enter clinical diagnosis...",
                hintStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13 : 12,
                  color: Colors.grey.shade400,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mandatory Doctor Clinical Notes
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(
                "Doctor Observations & Notes",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 4),
              const Text("*", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "Required",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: doctorNotesController ?? treatmentPlanController,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 14 : 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: "Enter clinical consultation notes, findings, and observations...",
                hintStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13 : 12,
                  color: Colors.grey.shade400,
                ),
                contentPadding: const EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Treatment Plan & Recommendations
          Row(
            children: [
              const Icon(Icons.medication_liquid_outlined, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(
                "Treatment Plan & Recommendations",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: treatmentPlanController,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 14 : 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: "Enter recommended treatment, lifestyle care, or follow-up plans...",
                hintStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13 : 12,
                  color: Colors.grey.shade400,
                ),
                contentPadding: const EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}