import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

import 'patient_info_card.dart';

class PatientSummaryCard extends StatelessWidget {
  final String summary;
  final bool isTab;
  const PatientSummaryCard({super.key, required this.summary, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PatientInfoCard(
      isTab: isTab,
      title: 'Summary',
      titleIcon: Icons.description_outlined,
      child: Text(summary, style: DietUi.text(13, FontWeight.w400, DietUi.body(isDark), height: 1.45)),
    );
  }
}
