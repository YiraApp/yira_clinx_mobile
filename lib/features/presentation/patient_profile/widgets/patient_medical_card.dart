
import 'package:flutter/material.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import 'metric_tile_item.dart';
import 'patient_info_card.dart';

class PatientMedicalCard extends StatelessWidget {
  final PatientProfileEntity patient;
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
            icon: Icons.healing_outlined,
            label: 'Condition',
            value: patient.condition,
            accentColor: Colors.orange,
          ),
          _buildDivider(isDark),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.warning_amber_rounded,
            label: 'Allergies',
            value: patient.allergies,
            accentColor: Colors.red,
            valueColor: isDark ? Colors.red[300] : Colors.red[700],
          ),
          _buildDivider(isDark),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.bloodtype_outlined,
            label: 'Blood Group',
            value: patient.bloodGroup,
            accentColor: Colors.red,
          ),
          _buildDivider(isDark),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.calendar_today_outlined,
            label: 'Total Visits',
            value: '${patient.totalVisits}',
            accentColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.grey[850] : const Color(0xFFF1F3F5),
        indent: 52,
      ),
    );
  }
}