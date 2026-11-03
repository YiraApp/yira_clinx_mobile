import 'package:flutter/material.dart';

import '../../patient_profile/widgets/record_tab_ui.dart';

class MedicalRecordCard extends StatelessWidget {
  final String title;
  final String formattedDate;
  final String doctorName;
  final String status;
  final String chiefComplaint;
  final String diagnosis;
  final String vitalsSummary;
  final VoidCallback onDetailsPressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onEditPressed;
  final bool isTab;

  const MedicalRecordCard({
    super.key,
    required this.title,
    required this.formattedDate,
    required this.doctorName,
    required this.status,
    required this.chiefComplaint,
    required this.diagnosis,
    required this.vitalsSummary,
    required this.onDetailsPressed,
    this.onDeletePressed,
    this.onEditPressed,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final hasEdit = onEditPressed != null;
    final hasDelete = onDeletePressed != null;
    return RecordCard(
      onTap: onDetailsPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecordCardHeader(
            icon: Icons.description_outlined,
            title: title,
            subtitle: doctorName.trim().isEmpty ? formattedDate : '$formattedDate · $doctorName',
            trailing: RecordStatusPill(status),
          ),
          // Only what this record has; a vitals check has no complaint or diagnosis.
          if (chiefComplaint.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            RecordField(label: 'Chief complaint', value: chiefComplaint),
          ],
          if (diagnosis.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            RecordField(label: 'Diagnosis', value: diagnosis),
          ],
          if (vitalsSummary.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            RecordVitalsRow(summary: vitalsSummary),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasEdit) RecordIconAction(icon: Icons.edit_outlined, tooltip: 'Edit record', onTap: onEditPressed!),
              if (hasDelete)
                RecordIconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete record',
                  danger: true,
                  onTap: onDeletePressed!,
                ),
              const Expanded(child: RecordCardLink()),
            ],
          ),
        ],
      ),
    );
  }
}
