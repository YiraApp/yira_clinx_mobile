
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_bloc/medical_record_bloc.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/detail_display_card.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/section_label_text.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/vital_sign_tile.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';

class MedicalRecordDetailsScreen extends StatelessWidget {
  const MedicalRecordDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    const String chiefComplaintText = "Fever";
    const String diagnosisText = "Hypermetropia";
    const String symptomsText = "Cough";
    const String physicalExamText = "Breath smells unpleasant";
    const String treatmentPlanText = "treat ment plan";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:  CommonText("Details",style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: displayWidth(context) * 0.045,
          fontWeight: FontWeight.w600,
        ),),
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<MedicalRecordBloc, MedicalRecordState>(
  listener: (context, state) {
  },
  builder: (context, state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20,right: 20,top: 20,bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabelText(text: "Chief Complaint"),
                      const SizedBox(height: 8),
                      CommonText(
                        chiefComplaintText,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey.withOpacity(0.12), height: 1.0),
                Padding(
                  padding: const EdgeInsets.only(left: 20,right: 20,top: 10,bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabelText(text: "Diagnosis"),
                      const SizedBox(height: 8),
                      CommonText(
                        diagnosisText,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: fieldSpace),

          const SectionLabelText(text: "Vital Signs"),
          const SizedBox(height: fieldSpace),
          Row(
            children: [
              Expanded(
                child: VitalSignTile(
                  label: "Blood Pressure",
                  value: "145/90",
                  accentColor: const Color(0xFF2563EB), // Primary Blue
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VitalSignTile(
                  label: "Heart Rate",
                  value: "74",
                  accentColor: const Color(0xFFDC2626), // Alert Red
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: VitalSignTile(
                  label: "Temperature",
                  value: "99",
                  unit: "°C",
                  accentColor: const Color(0xFFD97706), // Warning Amber
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VitalSignTile(
                  label: "Weight",
                  value: "83",
                  unit: "kg",
                  accentColor: const Color(0xFF059669), // Success Green
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VitalSignTile(
            label: "Height",
            value: "176",
            unit: "cm",
            accentColor: const Color(0xFF9333EA), // Purple Accent
          ),
          const SizedBox(height: 28),

          const SectionLabelText(text: "Symptoms"),
          const SizedBox(height: 8),
          DetailDisplayCard(text: symptomsText),
          const SizedBox(height: 28),

          const SectionLabelText(text: "Physical Examination"),
          const SizedBox(height: 8),
          DetailDisplayCard(text: physicalExamText),
          const SizedBox(height: 28),

          const SectionLabelText(text: "Treatment Plan"),
          const SizedBox(height: 8),
          DetailDisplayCard(text: treatmentPlanText),
          const SizedBox(height: 20),
        ],
      ),
    );
  },
),
    );
  }
}