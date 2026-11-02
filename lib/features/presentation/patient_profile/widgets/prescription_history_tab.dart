import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/colors/colors.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/patient_history/past_records_remote_data_source.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final ink = isDark ? Colors.white : const Color(0xFF0F172A);
    final primary = Theme.of(context).primaryColor;

    Widget message(IconData icon, String text, {Widget? action}) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(icon, size: 36, color: muted),
                const SizedBox(height: 10),
                Text(text, textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: muted)),
                if (action != null) ...[const SizedBox(height: 10), action],
              ],
            ),
          ),
        );

    return FutureBuilder<PastRecordsResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
        }
        final records = snap.data?.records;
        if (snap.hasError || records == null) {
          return message(PhosphorIconsBold.warningCircle, "Couldn't load prescriptions.",
              action: OutlinedButton(onPressed: () => setState(() => _future = _load()), child: const Text('Try again')));
        }
        final list = [...records.prescriptions]..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
        if (list.isEmpty) return message(PhosphorIconsDuotone.prescription, 'No prescriptions yet.');

        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = list[i];
              final by = [p.doctor, p.hospital].whereType<String>().join(' · ');
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? darkModeCardColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
                          child: PhosphorIcon(PhosphorIconsDuotone.prescription, size: 20, color: primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.date == null ? 'Prescription' : DateFormat('d MMM yyyy').format(p.date!),
                                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
                              if (by.isNotEmpty)
                                Text(by, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted)),
                            ],
                          ),
                        ),
                        if (p.pdfUrl != null)
                          TextButton.icon(
                            onPressed: () => launchUrl(Uri.parse(p.pdfUrl!), mode: LaunchMode.externalApplication),
                            icon: PhosphorIcon(PhosphorIconsBold.filePdf, size: 15, color: primary),
                            label: const Text('PDF'),
                          ),
                      ],
                    ),
                    if (p.diagnoses.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(p.diagnoses.join(', '),
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: ink)),
                    ],
                    if (p.medicineDetails.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final (name, detail) in p.medicineDetails)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6, right: 8),
                                child: Container(width: 5, height: 5, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
                              ),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: name,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: ink),
                                    children: [
                                      if (detail.isNotEmpty) TextSpan(text: '\n$detail', style: TextStyle(fontWeight: FontWeight.w400, color: muted, fontSize: 11.5)),
                                    ],
                                  ),
                                  style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (p.notes != null) ...[
                      const SizedBox(height: 8),
                      Text(p.notes!, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: muted)),
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
