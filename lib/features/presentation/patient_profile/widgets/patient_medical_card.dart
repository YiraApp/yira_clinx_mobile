import 'package:flutter/material.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import 'metric_tile_item.dart';
import 'patient_info_card.dart';
import 'record_tab_ui.dart';

class PatientMedicalCard extends StatelessWidget {
  final MedicalInformationEntity patient;
  final bool isTab;
  const PatientMedicalCard({super.key, required this.patient, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PatientInfoCard(
      isTab: isTab,
      title: 'Medical Information',
      titleIcon: Icons.medical_services_outlined,
      child: Column(
        children: [
          MetricTileItem(
            isTab: isTab,
            icon: Icons.warning_amber_rounded,
            label: 'Allergies',
            value: (patient.allergies?.isNotEmpty == true && patient.allergies != 'None') ? patient.allergies! : 'None Reported',
            accentColor: Colors.red,
            valueColor: (patient.allergies?.isNotEmpty == true && patient.allergies != 'None')
                ? (isDark ? Colors.red[300] : Colors.red[700])
                : null,
          ),
          const RecordDivider(indent: 30),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.bloodtype_outlined,
            label: 'Blood Group',
            value: patient.bloodGroup ?? 'Not Set',
            accentColor: Colors.red,
          ),
          const RecordDivider(indent: 30),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.calendar_today_outlined,
            label: 'Total Visits',
            value: '${patient.totalVisits ?? 0}',
            accentColor: Colors.purple,
          ),
        ],
      ),
    );
  }
}
