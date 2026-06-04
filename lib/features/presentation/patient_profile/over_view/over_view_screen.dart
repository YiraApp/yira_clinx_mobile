import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_contact_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_medical_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_insurance_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_history_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_summary_card.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../widgets/add_records_buttons.dart';

class OverviewScreen extends StatelessWidget {
  final PatientProfileEntity patient;

  const OverviewScreen({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Theme.of(context).scaffoldBackgroundColor,
     /* appBar: PreferredSize(
        preferredSize: Size.fromHeight(isTablet(context) ? 68.0 : 30.0),
        child: AppBar(
          title: CommonText(
            "Overview",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.035,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),*/
        floatingActionButton:ClinicalSpeedDialFab(
          onAddNoteTapped: () => debugPrint(
            'Clean Architecture: Triggering Add Note event payload.',
          ),
          onScheduleTapped: () => debugPrint(
            'Clean Architecture: Launching appointment booking engine.',
          ),
          onPrescribeTapped: () => debugPrint(
            'Clean Architecture: Activating medical drug selector routine.',
          ),
        ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            PatientContactCard(patient: patient),
            PatientMedicalCard(patient: patient),
            PatientInsuranceCard(patient: patient),
            PatientHistoryCard(patient: patient),
            PatientSummaryCard(patient: patient),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}