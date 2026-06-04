
import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/section_header.dart';
import '../../../../core/common_input_fields/common_input_field_unlimited.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
class DiagnosisTreatmentSection extends StatelessWidget {
  final TextEditingController diagnosisController;
  final TextEditingController treatmentPlanController;

  const DiagnosisTreatmentSection({
    super.key,
    required this.diagnosisController,
    required this.treatmentPlanController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontFamily: appPoppinFont,color: Colors.grey,
      fontSize: displayWidth(context) * 0.032,
    );
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Diagnosis & Treatment"),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText("Diagnosis", style: labelStyle),
              const SizedBox(height: 6),
              SizedBox(
                height: 80,
                child: CommonInputFieldUnlimited(
                  suffixIcon: null,
                  borderRadius: 12,
                  textInputAction: TextInputAction.next,
                  controller: diagnosisController,
                  hintText: "Search diagnosis...",
                ),
              ),
              const SizedBox(height: 16),

              CommonText("Treatment Plan", style: labelStyle),
              const SizedBox(height: 6),
              // Constraining the heights boundary structure for the expands layout widget setup
              SizedBox(
                height: 80,
                child: CommonInputFieldUnlimited(
                  suffixIcon: null,
                  borderRadius: 12,
                  textInputAction: TextInputAction.done,
                  controller: treatmentPlanController,
                  hintText: "Treatment plan...",
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}