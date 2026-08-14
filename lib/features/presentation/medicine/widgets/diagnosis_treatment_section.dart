import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_widgets/snomed_search_picker.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/section_header.dart';
import '../../../../core/common_input_fields/common_input_field_unlimited.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class DiagnosisTreatmentSection extends StatelessWidget {
  final TextEditingController diagnosisController;
  final TextEditingController treatmentPlanController;
  final bool isTab;
  final Function(String term, String? code)? onDiagnosisConceptSelected;

  const DiagnosisTreatmentSection({
    super.key,
    required this.diagnosisController,
    required this.treatmentPlanController,
    required this.isTab,
    this.onDiagnosisConceptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontFamily: appPoppinFont,
      color: Colors.grey,
      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
    );
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: "Diagnosis & Treatment", isTab: isTab),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SnomedMultiSearchPicker(
                label: "Diagnosis",
                hintText: "Search diagnoses & disorders (SNOMED CT)...",
                initialValue: diagnosisController.text,
                snomedType: "disorder",
                onSelected: (selectedTerms) {
                  diagnosisController.text = selectedTerms.join(', ');
                  if (onDiagnosisConceptSelected != null && selectedTerms.isNotEmpty) {
                    onDiagnosisConceptSelected!(selectedTerms.last, null);
                  }
                },
              ),
              const SizedBox(height: 16),

              CommonText("Treatment Plan", style: labelStyle),
              const SizedBox(height: 6),
              SizedBox(
                height: 80,
                child: CommonInputFieldUnlimited(
                  suffixIcon: null,
                  borderRadius: fieldBorderRadius,
                  textInputAction: TextInputAction.done,
                  controller: treatmentPlanController,
                  hintText: "Enter treatment plan...",
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}