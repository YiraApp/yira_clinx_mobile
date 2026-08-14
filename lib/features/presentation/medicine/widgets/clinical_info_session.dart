import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_widgets/snomed_search_picker.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/section_header.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: "Clinical Information", isTab: isTab),
        const SizedBox(height: 12),

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

        const SizedBox(height: fieldSpace),

        SnomedMultiSearchPicker(
          label: "Symptoms",
          hintText: "Search symptoms (SNOMED CT)...",
          initialValue: symptomsController.text,
          snomedType: "finding",
          onSelected: (selectedTerms) {
            symptomsController.text = selectedTerms.join(', ');
            if (onSymptomConceptSelected != null && selectedTerms.isNotEmpty) {
              onSymptomConceptSelected!(selectedTerms.last, null);
            }
          },
        ),

        const SizedBox(height: fieldSpace),

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
    );
  }
}