import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_widgets/snomed_search_picker.dart';
import '../../../../core/constants/constants.dart';

class ClinicalInfoSection extends StatelessWidget {
  final TextEditingController chiefComplaintController;
  final TextEditingController symptomsController;
  final TextEditingController physicalExamController;
  final bool isTab;
  final Function(String term, String? code)? onChiefComplaintConceptSelected;
  final Function(String term, String? code)? onSymptomConceptSelected;
  final Function(String term, String? code)? onExamConceptSelected;

  const ClinicalInfoSection({
    super.key,
    required this.chiefComplaintController,
    required this.symptomsController,
    required this.physicalExamController,
    required this.isTab,
    this.onChiefComplaintConceptSelected,
    this.onSymptomConceptSelected,
    this.onExamConceptSelected,
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
                  Icons.medical_information_outlined,
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
                      "Clinical Assessment",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 17 : 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Chief complaints, symptoms & findings",
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

          // Chief Complaint
          SnomedMultiSearchPicker(
            label: "Chief Complaint",
            hintText: "Search chief complaints (SNOMED CT)...",
            initialValue: chiefComplaintController.text,
            snomedType: "finding",
            isRequired: true,
            onSelected: (selectedTerms) {
              chiefComplaintController.text = selectedTerms.join(', ');
              if (onChiefComplaintConceptSelected != null && selectedTerms.isNotEmpty) {
                onChiefComplaintConceptSelected!(selectedTerms.last, null);
              }
            },
          ),

          const SizedBox(height: 16),

          // Symptoms
          SnomedMultiSearchPicker(
            label: "Symptoms & History",
            hintText: "Search symptoms & observations (SNOMED CT)...",
            initialValue: symptomsController.text,
            snomedType: "finding",
            onSelected: (selectedTerms) {
              symptomsController.text = selectedTerms.join(', ');
              if (onSymptomConceptSelected != null && selectedTerms.isNotEmpty) {
                onSymptomConceptSelected!(selectedTerms.last, null);
              }
            },
          ),

          const SizedBox(height: 16),

          // Physical Exam
          SnomedMultiSearchPicker(
            label: "Physical Examination",
            hintText: "Search examination findings (SNOMED CT)...",
            initialValue: physicalExamController.text,
            snomedType: "finding",
            onSelected: (selectedTerms) {
              physicalExamController.text = selectedTerms.join(', ');
              if (onExamConceptSelected != null && selectedTerms.isNotEmpty) {
                onExamConceptSelected!(selectedTerms.last, null);
              }
            },
          ),
        ],
      ),
    );
  }
}