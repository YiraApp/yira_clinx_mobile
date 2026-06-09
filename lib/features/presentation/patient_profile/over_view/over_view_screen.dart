import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_contact_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_medical_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_insurance_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_history_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_summary_card.dart';

import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../widgets/add_records_buttons.dart';
class OverviewScreen extends StatelessWidget {
  final PatientProfileEntity patient;

  final VoidCallback onPrescribeTap;
  final VoidCallback onNoteTap;
  final VoidCallback onScheduleTap;
  final bool isTab;

  const OverviewScreen({
    super.key,
    required this.patient,
    required this.onPrescribeTap,
    required this.onNoteTap,
    required this.onScheduleTap, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: ClinicalSpeedDialFab(
        onAddNoteTapped: onNoteTap,
        onScheduleTapped: onScheduleTap,
        onPrescribeTapped: onPrescribeTap,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            PatientContactCard(patient: patient,isTab:isTab),
            PatientMedicalCard(patient: patient,isTab:isTab),
            PatientInsuranceCard(patient: patient,isTab:isTab),
            PatientHistoryCard(patient: patient,isTab:isTab),
            PatientSummaryCard(patient: patient,isTab:isTab),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}