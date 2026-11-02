import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yiraclinics/core/colors/colors.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/patient_history/past_records_remote_data_source.dart';

/// The patient's earlier visits, prescriptions, records, documents and
/// latest readings, shown on the doctor's appointment page.
///
/// With the patient's consent (or as their treating doctor) this covers every
/// hospital; otherwise it shows this hospital's own records and offers to ask
/// for the rest.
class PatientPastRecordsSection extends StatefulWidget {
  const PatientPastRecordsSection({
    super.key,
    required this.patientId,
    this.appointmentId,
    this.hospitalId,
    required this.onOpenTab,
    required this.onRequestAccess,
    this.dataSource,
  });

  final String patientId;
  final String? appointmentId;
  final String? hospitalId;

  /// Opens a record tab ('Appointments', 'Medical Record', 'Prescribe', 'Documents') at full history.
  final void Function(String tab) onOpenTab;
  final VoidCallback onRequestAccess;
  final PastRecordsRemoteDataSource? dataSource;

  @override
  State<PatientPastRecordsSection> createState() => _PatientPastRecordsSectionState();
}

class _PatientPastRecordsSectionState extends State<PatientPastRecordsSection> {
  late Future<PastRecordsResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PastRecordsResult> _load() => (widget.dataSource ?? PastRecordsRemoteDataSource())
      .fetch(patientId: widget.patientId, appointmentId: widget.appointmentId, hospitalId: widget.hospitalId);

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<PastRecordsResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _card(isDark, child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
          ));
        }
        if (snap.hasError) {
          return _card(isDark, child: _message(isDark, PhosphorIconsBold.warningCircle, 'Couldn\'t load past records.',
              action: TextButton(onPressed: _retry, child: const Text('Retry'))));
        }
        final result = snap.data!;
        if (result.needsConsent) return _locked(isDark, result.consentStatus);
        return _records(isDark, result.records!);
      },
    );
  }

  Widget _card(bool isDark, {required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: fieldSpace),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor : Colors.white,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        child: child,
      );

  Color _muted(bool isDark) => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color _fg(bool isDark) => isDark ? Colors.white : const Color(0xFF0F172A);

  Widget _header(bool isDark, {required String scope, required Color scopeColor}) => Row(
        children: [
          Icon(PhosphorIconsBold.clockCounterClockwise, size: 18, color: _muted(isDark)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Past records',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: _fg(isDark))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: scopeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(scope,
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, fontWeight: FontWeight.w700, color: scopeColor)),
          ),
        ],
      );

  Widget _message(bool isDark, IconData icon, String text, {Widget? action}) => Row(
        children: [
          Icon(icon, size: 18, color: _muted(isDark)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: _muted(isDark)))),
          ?action,
        ],
      );

  Widget _locked(bool isDark, String? status) {
    final pending = (status ?? '').toUpperCase() == 'PENDING';
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(isDark, scope: 'Locked', scopeColor: const Color(0xFFF59E0B)),
          const SizedBox(height: 10),
          Text(
            pending
                ? 'You\'ve asked for access. Past records from other hospitals appear here once the patient approves.'
                : 'Records from this patient\'s other hospitals need their approval. Ask once and they show up here.',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, height: 1.45, color: _muted(isDark)),
          ),
          if (!pending) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onRequestAccess,
              icon: const Icon(PhosphorIconsBold.lockKeyOpen, size: 16),
              label: const Text('Ask for access'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _records(bool isDark, PastRecords r) {
    final fmt = DateFormat('d MMM yyyy');
    final fitness = r.weekFitness;
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            isDark,
            scope: r.allHospitals ? 'All hospitals' : 'This hospital',
            scopeColor: r.allHospitals ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
          ),
          if (!r.allHospitals) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: widget.onRequestAccess,
              child: Text('Ask the patient to see records from other hospitals',
                  style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor)),
            ),
          ],
          const SizedBox(height: 12),
          if (r.isEmpty && fitness == null)
            _message(isDark, PhosphorIconsBold.fileDashed, 'No earlier visits or records yet.')
          else ...[
            _counts(isDark, r),
            if (r.vitals.isNotEmpty) ...[
              _subhead(isDark, 'Latest vitals'),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final v in r.vitals) _vitalChip(isDark, v)]),
            ],
            if (r.activeMedicines.isNotEmpty) ...[
              _subhead(isDark, 'Currently taking'),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final m in r.activeMedicines.take(8)) _pill(isDark, m)]),
            ],
            if (r.visits.isNotEmpty) ...[
              _subhead(isDark, 'Earlier visits', tab: 'Appointments'),
              for (final v in r.visits.take(3))
                _row(isDark,
                    icon: PhosphorIconsDuotone.calendarCheck,
                    color: const Color(0xFF6366F1),
                    title: v.reason ?? v.type ?? 'Consultation',
                    subtitle: [v.doctor, v.hospital].whereType<String>().join(' · '),
                    trailing: v.date == null ? null : fmt.format(v.date!)),
            ],
            if (r.records.isNotEmpty) ...[
              _subhead(isDark, 'Diagnoses & records', tab: 'Medical Record'),
              for (final m in r.records.take(3))
                _row(isDark,
                    icon: PhosphorIconsDuotone.stethoscope,
                    color: const Color(0xFF0D9488),
                    title: m.diagnosis ?? m.complaint ?? m.type ?? 'Medical record',
                    subtitle: [m.doctor, m.hospital].whereType<String>().join(' · '),
                    trailing: m.date == null ? null : fmt.format(m.date!)),
            ],
            if (r.prescriptions.isNotEmpty) ...[
              _subhead(isDark, 'Prescriptions', tab: 'Prescribe'),
              for (final p in r.prescriptions.take(3))
                _row(isDark,
                    icon: PhosphorIconsDuotone.prescription,
                    color: const Color(0xFFDB2777),
                    title: p.medicines.isEmpty ? (p.diagnoses.isEmpty ? 'Prescription' : p.diagnoses.join(', ')) : p.medicines.take(3).join(', ') + (p.medicines.length > 3 ? ' +${p.medicines.length - 3}' : ''),
                    subtitle: [if (p.diagnoses.isNotEmpty && p.medicines.isNotEmpty) p.diagnoses.join(', '), p.doctor, p.hospital].whereType<String>().join(' · '),
                    trailing: p.date == null ? null : fmt.format(p.date!),
                    url: p.pdfUrl),
            ],
            if (r.documents.isNotEmpty) ...[
              _subhead(isDark, 'Documents', tab: 'Documents'),
              for (final d in r.documents.take(3))
                _row(isDark,
                    icon: PhosphorIconsDuotone.fileText,
                    color: const Color(0xFF7C3AED),
                    title: d.name,
                    subtitle: [d.category, d.hospital].whereType<String>().join(' · '),
                    trailing: d.date == null ? null : fmt.format(d.date!),
                    url: d.url),
            ],
            if (fitness != null) ...[
              _subhead(isDark, 'From their phone (last 7 days synced)'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (fitness.steps != null) _pill(isDark, '${NumberFormat.decimalPattern().format(fitness.steps)} steps/day'),
                if (fitness.sleepMinutes != null)
                  _pill(isDark, '${fitness.sleepMinutes! ~/ 60}h ${fitness.sleepMinutes! % 60}m sleep'),
                if (fitness.restingHr != null) _pill(isDark, 'Resting HR ${fitness.restingHr} bpm'),
              ]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _counts(bool isDark, PastRecords r) {
    Widget stat(String label, int n, String tab) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onOpenTab(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('$n', style: TextStyle(fontFamily: appPoppinFont, fontSize: 17, fontWeight: FontWeight.w800, color: _fg(isDark))),
                  FittedBox(
                    child: Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, color: _muted(isDark))),
                  ),
                ],
              ),
            ),
          ),
        );
    return Row(children: [
      stat('Visits', r.visits.length, 'Appointments'),
      const SizedBox(width: 6),
      stat('Records', r.records.length, 'Medical Record'),
      const SizedBox(width: 6),
      stat('Rx', r.prescriptions.length, 'Prescribe'),
      const SizedBox(width: 6),
      stat('Docs', r.documents.length, 'Documents'),
    ]);
  }

  Widget _subhead(bool isDark, String text, {String? tab}) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(text.toUpperCase(),
                  style: TextStyle(
                      fontFamily: appPoppinFont, fontSize: 10.5, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: _muted(isDark))),
            ),
            if (tab != null)
              GestureDetector(
                onTap: () => widget.onOpenTab(tab),
                child: Text('View all',
                    style: TextStyle(
                        fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
              ),
          ],
        ),
      );

  Widget _row(bool isDark,
      {required IconData icon, required Color color, required String title, String subtitle = '', String? trailing, String? url}) {
    final canOpen = url != null && url.startsWith('http');
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: canOpen ? () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: _fg(isDark))),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: _muted(isDark))),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(trailing, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: _muted(isDark))),
            ],
            if (canOpen) ...[
              const SizedBox(width: 4),
              Icon(PhosphorIconsBold.arrowSquareOut, size: 14, color: _muted(isDark)),
            ],
          ],
        ),
      ),
    );
  }

  static const _vitalNames = {
    'bloodPressure': 'BP',
    'heartRate': 'Pulse',
    'temperature': 'Temp',
    'spo2': 'SpO2',
    'weight': 'Weight',
    'height': 'Height',
  };

  Widget _vitalChip(bool isDark, LatestVital v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_vitalNames[v.key] ?? v.key, style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, color: _muted(isDark))),
            Text('${v.value} ${v.unit}'.trim(),
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700, color: _fg(isDark))),
            if (v.date != null)
              Text(DateFormat('d MMM').format(v.date!), style: TextStyle(fontFamily: appPoppinFont, fontSize: 9.5, color: _muted(isDark))),
          ],
        ),
      );

  Widget _pill(bool isDark, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w600, color: _fg(isDark))),
      );
}
