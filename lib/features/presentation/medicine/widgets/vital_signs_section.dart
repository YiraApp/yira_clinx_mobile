
import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/section_header.dart';

import '../../../../core/common_input_fields/common_input_field.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class VitalSignsSection extends StatelessWidget {
  final TextEditingController bpController;
  final TextEditingController hrController;
  final TextEditingController tempController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController oxygenSaturationController;


  const VitalSignsSection({
    super.key,
    required this.bpController,
    required this.hrController,
    required this.tempController,
    required this.weightController,
    required this.heightController, required this.oxygenSaturationController,
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
        const SectionHeader(title: "Vital Signs"),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText("BP", style: labelStyle),
                  const SizedBox(height: 6),
                  CommonInputAddRecordTextField(suffixIcon: null,
                      isRecord: true,
                      borderRadius: 8,
                      hintText: "Enter Blood Pressure (120/80)",
                      textInputAction: TextInputAction.next,
                      controller: bpController),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText("HR", style: labelStyle),
                  const SizedBox(height: 6),
                  CommonInputAddRecordTextField(suffixIcon: null,
                      borderRadius: 8,
                      isRecord: true,
                      hintText: "Enter Heart Rate",
                      textInputAction: TextInputAction.next,
                      controller: hrController),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText("Temp", style: labelStyle),
                  const SizedBox(height: 6),
                  CommonInputAddRecordTextField(
                    suffixIcon: null,
                    borderRadius: 8,
                    isRecord: true,
                    hintText: "Enter Temperature",
                    controller: tempController,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText("Weight", style: labelStyle),
                  const SizedBox(height: 6),
                  CommonInputAddRecordTextField(
                      suffixIcon: null,
                      borderRadius: 8,
                      isRecord: true,
                      hintText: "Enter Weight",
                      textInputAction: TextInputAction.next,
                      controller: weightController),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText("Spo2", style: labelStyle),
                  const SizedBox(height: 6),
                  CommonInputAddRecordTextField(
                    suffixIcon: null,
                    borderRadius: 8,
                    isRecord: true,
                    hintText: "Enter Spo2",
                    controller: oxygenSaturationController,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText("HEIGHT", style: labelStyle),
                  const SizedBox(height: 6),
                  CommonInputAddRecordTextField(suffixIcon: null,
                      borderRadius: 8,
                      hintText: "Enter Height",
                      isRecord: true,
                      textInputAction: TextInputAction.next,
                      controller: heightController),
                ],
              ),
            ),
          ],
        ),

      ],
    );
  }
}