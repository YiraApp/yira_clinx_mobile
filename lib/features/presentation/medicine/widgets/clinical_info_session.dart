
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_input_fields/common_input_field_unlimited.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/section_header.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
class ClinicalInfoSection extends StatelessWidget {
  final TextEditingController chiefComplaintController;
  final TextEditingController symptomsController;
  final TextEditingController physicalExamController;

  const ClinicalInfoSection({
    super.key,
    required this.chiefComplaintController,
    required this.symptomsController,
    required this.physicalExamController,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontFamily: appPoppinFont,color: Colors.grey,
      fontSize: displayWidth(context) * 0.032,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Clinical Information"),
        const SizedBox(height: 12),

        CommonText("Chief Complaint", style: TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: appPoppinFont,color: Colors.grey,
          fontSize: displayWidth(context) * 0.032,
        )),
        const SizedBox(height: 6),
        SizedBox(
          height: 80,
          child: CommonInputFieldUnlimited(
            suffixIcon: null,
            borderRadius: 8,
            controller: chiefComplaintController,
            hintText: "Search complaints...",
            textInputAction: TextInputAction.next,
          ),
        ),

        const SizedBox(height: fieldSpace),

        CommonText("Symptoms", style: labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          height: 80,
          child: CommonInputFieldUnlimited(
            suffixIcon: null,
            borderRadius: 8,
            controller: symptomsController,
            hintText: "Search Symptoms...",
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: fieldSpace),

        CommonText("Physical Examination", style: labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          height: 80,
          child: CommonInputFieldUnlimited(
            controller: physicalExamController,
            hintText: "Search examination findings...",
          ),
        ),
      ],
    );
  }
}