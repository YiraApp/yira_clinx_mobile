import 'package:flutter/material.dart';
import '../../../domain/entities/prescriptions/lab_test_entity.dart';
import '../../../domain/entities/prescriptions/prescription_item.dart';
import '../../patient/diet/diet_ui.dart';
import '../../patient_profile/widgets/record_tab_ui.dart';

class SinglePrescriptionCard extends StatelessWidget {
  final List<MedicationItem> medications;
  final List<PrescribedLabTest> labTests;
  final String date;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final VoidCallback? onPdfView;
  final bool isTab;

  const SinglePrescriptionCard({
    super.key,
    required this.medications,
    this.labTests = const [],
    required this.date,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.onPdfView,
    required this.isTab,
  });

  String _timing(MedicationItem med) => [med.dosage, med.frequency, med.duration, med.route]
      .map((part) => (part ?? '').trim())
      .where((part) => part.isNotEmpty)
      .join(' · ');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int count = medications.length;
    final open = onPdfView ?? onView;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RecordCard(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecordCardHeader(
              icon: Icons.medication_outlined,
              title: "Prescription Record",
              subtitle: date,
            ),
            if (count > 0) ...[
              const SizedBox(height: 12),
              Text(
                "$count ${count == 1 ? 'Medicine' : 'Medicines'}",
                style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
              ),
            ],
            for (final med in medications.take(3)) ...[
              const SizedBox(height: 8),
              RecordMedicineLine(name: med.name, detail: _timing(med)),
            ],
            if (medications.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                "+ ${medications.length - 3} more medications",
                style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
              ),
            ],
            if (labTests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "${labTests.length} ${labTests.length == 1 ? 'Lab Test' : 'Lab Tests'}",
                style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
              ),
              const SizedBox(height: 8),
              RecordLabTestLines(tests: labTests, limit: 3),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (onEdit != null) RecordIconAction(icon: Icons.edit_outlined, tooltip: 'Edit prescription', onTap: onEdit!),
                if (onDelete != null)
                  RecordIconAction(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete prescription',
                    danger: true,
                    onTap: onDelete!,
                  ),
                if (open != null) const Expanded(child: RecordCardLink(label: "View Full Prescription")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
