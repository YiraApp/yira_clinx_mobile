import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/features/domain/entities/medicine/medical_history_entity.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/detail_display_card.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/section_label_text.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/vital_sign_tile.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';

class MedicalRecordDetailsScreen extends StatelessWidget {
  final MedicalRecordBriefEntity? record;

  const MedicalRecordDetailsScreen({super.key, this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    final String chiefComplaintText = (record?.chiefComplaint != null && record!.chiefComplaint.isNotEmpty)
        ? record!.chiefComplaint
        : "N/A";
    final String diagnosisText = (record?.diagnosis != null && record!.diagnosis.isNotEmpty)
        ? record!.diagnosis
        : "N/A";
    final String symptomsText = (record?.symptoms != null && record!.symptoms!.isNotEmpty)
        ? record!.symptoms!
        : "N/A";
    final String physicalExamText = (record?.physicalExamination != null && record!.physicalExamination!.isNotEmpty)
        ? record!.physicalExamination!
        : "N/A";
    final String treatmentPlanText = (record?.treatmentPlan != null && record!.treatmentPlan!.isNotEmpty)
        ? record!.treatmentPlan!
        : "N/A";

    final String bpValue = (record?.bloodPressure != null && record!.bloodPressure!.isNotEmpty)
        ? record!.bloodPressure!
        : "--";
    final String hrValue = (record?.heartRate != null && record!.heartRate!.isNotEmpty)
        ? record!.heartRate!
        : "--";
    final String tempValue = (record?.temperature != null && record!.temperature!.isNotEmpty)
        ? record!.temperature!
        : "--";
    final String weightValue = (record?.weight != null && record!.weight!.isNotEmpty)
        ? record!.weight!
        : "--";
    final String heightValue = (record?.height != null && record!.height!.isNotEmpty)
        ? record!.height!
        : "--";

    final String formattedDate = record?.recordDate != null
        ? DateFormat('MMMM dd, yyyy').format(record!.recordDate)
        : '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(
        titleText: (record?.title != null && record!.title.isNotEmpty) ? record!.title : "Record Details",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: screenHorizontalSpacePadding, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (record!.doctorName.isNotEmpty)
                    CommonText(
                      record!.doctorName,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 18 : 15,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  if (formattedDate.isNotEmpty)
                    CommonText(
                      formattedDate,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 14 : 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? darkModeCardColor : Colors.white,
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, top: 20, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabelText(text: "Chief Complaint", isTab: isTab),
                        const SizedBox(height: 8),
                        CommonText(
                          chiefComplaintText,
                          maxLines: null,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab
                                ? displayWidth(context) * 0.018
                                : displayWidth(context) * 0.032,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.withOpacity(0.12), height: 1.0),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, top: 10, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabelText(text: "Diagnosis", isTab: isTab),
                        const SizedBox(height: 8),
                        CommonText(
                          diagnosisText,
                          maxLines: null,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab
                                ? displayWidth(context) * 0.018
                                : displayWidth(context) * 0.032,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: fieldSpace),
            SectionLabelText(text: "Vital Signs", isTab: isTab),
            const SizedBox(height: fieldSpace),
            Row(
              children: [
                Expanded(
                  child: VitalSignTile(
                    isTab: isTab,
                    label: "Blood Pressure",
                    value: bpValue,
                    accentColor: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VitalSignTile(
                    isTab: isTab,
                    label: "Heart Rate",
                    value: hrValue,
                    accentColor: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: VitalSignTile(
                    isTab: isTab,
                    label: "Temperature",
                    value: tempValue,
                    unit: "°C",
                    accentColor: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VitalSignTile(
                    isTab: isTab,
                    label: "Weight",
                    value: weightValue,
                    unit: "kg",
                    accentColor: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            VitalSignTile(
              isTab: isTab,
              label: "Height",
              value: heightValue,
              unit: "cm",
              accentColor: const Color(0xFF9333EA),
            ),
            const SizedBox(height: 28),
            SectionLabelText(text: "Symptoms", isTab: isTab),
            const SizedBox(height: 8),
            DetailDisplayCard(text: symptomsText),
            const SizedBox(height: 28),
            SectionLabelText(text: "Physical Examination", isTab: isTab),
            const SizedBox(height: 8),
            DetailDisplayCard(text: physicalExamText),
            const SizedBox(height: 28),
            SectionLabelText(text: "Treatment Plan", isTab: isTab),
            const SizedBox(height: 8),
            DetailDisplayCard(text: treatmentPlanText),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}