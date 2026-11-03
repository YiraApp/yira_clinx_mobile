import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/data_sources/patient_history/past_records_remote_data_source.dart';
import 'record_tab_ui.dart';

/// Every prescription the doctor may see for a patient, newest first, each
/// with its real date, prescriber, diagnoses, medicines and PDF. Read-only:
/// prescribing happens from an appointment.
class PrescriptionHistoryTab extends StatefulWidget {
  const PrescriptionHistoryTab({super.key, required this.patientId, this.hospitalId, this.dataSource});

  final String patientId;
  final String? hospitalId;
  final PastRecordsRemoteDataSource? dataSource;

  @override
  State<PrescriptionHistoryTab> createState() => _PrescriptionHistoryTabState();
}

class _PrescriptionHistoryTabState extends State<PrescriptionHistoryTab> {
  late Future<PastRecordsResult> _future = _load();

  Future<PastRecordsResult> _load() =>
      (widget.dataSource ?? PastRecordsRemoteDataSource()).fetch(patientId: widget.patientId, hospitalId: widget.hospitalId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PastRecordsResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
        }
        final records = snap.data?.records;
        if (snap.hasError || records == null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RecordEmptyState(icon: Icons.error_outline_rounded, title: "Couldn't load prescriptions."),
              const SizedBox(height: 12),
              RecordSecondaryButton(label: 'Try again', onPressed: () => setState(() => _future = _load())),
            ],
          );
        }
        final list = [...records.prescriptions]..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
        if (list.isEmpty) return const RecordEmptyState(icon: Icons.medication_outlined, title: 'No prescriptions yet.');

        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = list[i];
              final by = [p.doctor, p.hospital].whereType<String>().join(' · ');
              return RecordCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecordCardHeader(
                      icon: Icons.medication_outlined,
                      title: p.date == null ? 'Prescription' : DateFormat('d MMM yyyy').format(p.date!),
                      subtitle: by,
                      trailing: p.pdfUrl == null
                          ? null
                          : RecordIconAction(
                              icon: Icons.picture_as_pdf_outlined,
                              tooltip: 'PDF',
                              onTap: () => launchUrl(Uri.parse(p.pdfUrl!), mode: LaunchMode.externalApplication),
                            ),
                    ),
                    if (p.diagnoses.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      RecordField(label: 'Diagnosis', value: p.diagnoses.join(', ')),
                    ],
                    if (p.medicineDetails.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      for (final (name, detail) in p.medicineDetails) ...[
                        const SizedBox(height: 8),
                        RecordMedicineLine(name: name, detail: detail),
                      ],
                    ],
                    if (p.labTests.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const RecordSectionTitle(icon: Icons.biotech_outlined, title: 'Lab Tests'),
                      const SizedBox(height: 8),
                      RecordLabTestLines(tests: p.labTests),
                    ],
                    if (p.notes != null) ...[
                      const SizedBox(height: 10),
                      RecordField(label: 'Notes', value: p.notes!),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
