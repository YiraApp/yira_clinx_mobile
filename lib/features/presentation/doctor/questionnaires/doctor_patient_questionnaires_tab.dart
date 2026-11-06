import 'package:flutter/material.dart';

import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/questionnaires/questionnaire_remote_data_source.dart';
import '../../../data/models/questionnaires/questionnaire_models.dart';
import '../../patient/questionnaires/questionnaire_history_screen.dart';
import '../../patient/questionnaires/questionnaire_ui.dart';
import '../../patient_profile/widgets/record_tab_ui.dart';
import 'send_questionnaire_sheet.dart';

/// The questionnaires a patient filled in, for their doctor: one card per
/// questionnaire, every attempt, with answers that changed since the attempt
/// before marked. By default only this hospital's; the full history needs consent.
class DoctorPatientQuestionnairesTab extends StatefulWidget {
  final String patientId;
  final String? hospitalId;
  final String? appointmentId;
  final bool fullHistory;
  final QuestionnaireRemoteDataSource? dataSource;

  const DoctorPatientQuestionnairesTab({
    super.key,
    required this.patientId,
    this.hospitalId,
    this.appointmentId,
    this.fullHistory = false,
    this.dataSource,
  });

  @override
  State<DoctorPatientQuestionnairesTab> createState() => _DoctorPatientQuestionnairesTabState();
}

class _DoctorPatientQuestionnairesTabState extends State<DoctorPatientQuestionnairesTab> {
  late final QuestionnaireRemoteDataSource _source = widget.dataSource ?? QuestionnaireRemoteDataSource();
  List<DoctorQuestionnaireGroup>? _groups;
  String? _error;
  bool _locked = false;
  final Map<int, int> _attemptIndex = {};
  final Set<int> _open = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _locked = false;
    });
    try {
      final groups = await _source.forDoctor(
        widget.patientId,
        hospitalId: widget.fullHistory ? null : widget.hospitalId,
        appointmentId: widget.fullHistory ? null : widget.appointmentId,
      );
      if (!mounted) return;
      setState(() {
        _groups = groups;
        // The most recent questionnaire starts open.
        if (groups.isNotEmpty && _open.isEmpty) _open.add(groups.first.questionnaireId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locked = questionnaireNeedsConsent(e);
        _error = questionnaireErrorMessage(e, "Couldn't load questionnaires.");
        _groups = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = _groups;
    if (groups == null) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (_canSend) ...[
            _sendButton(isDark),
            const SizedBox(height: 12),
          ],
          if (_locked)
            RecordEmptyState(
              icon: PhosphorIconsBold.shieldWarning,
              title: 'Questionnaires are private',
              message: widget.fullHistory
                  ? "The patient hasn't given you access to their full history."
                  : 'You can see questionnaires from your hospital for patients who visit it.',
            )
          else if (_error != null)
            RecordEmptyState(icon: PhosphorIconsBold.warningCircle, title: "Couldn't load", message: _error)
          else if (groups.isEmpty)
            RecordEmptyState(
              icon: PhosphorIconsBold.fileText,
              title: 'No questionnaires yet',
              message: widget.fullHistory
                  ? "This patient hasn't filled in any questionnaires."
                  : "This patient hasn't filled in any of this hospital's questionnaires.",
            )
          else
            for (final g in groups) ...[
              _card(g, isDark),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  /// Sending needs the hospital the doctor is working at.
  bool get _canSend => (widget.hospitalId ?? '').isNotEmpty && widget.hospitalId != '0' && !_locked;

  Future<void> _openSend() async {
    final sent = await SendQuestionnaireSheet.show(context, patientId: widget.patientId, hospitalId: widget.hospitalId!);
    if (!mounted || sent == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent "$sent". The patient will get a notification.'), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _sendButton(bool isDark) {
    return QCard(
      onTap: _openSend,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: QUi.blueSoft(isDark), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.send_rounded, size: 18, color: QUi.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send a questionnaire', style: QUi.text(14.5, FontWeight.w600, QUi.ink(isDark))),
                const SizedBox(height: 2),
                Text('Ask this patient to fill one in from the app', style: QUi.text(12, FontWeight.w400, QUi.muted(isDark))),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: QUi.muted(isDark)),
        ],
      ),
    );
  }

  Widget _card(DoctorQuestionnaireGroup g, bool isDark) {
    final open = _open.contains(g.questionnaireId);
    final index = (_attemptIndex[g.questionnaireId] ?? 0).clamp(0, g.attempts.isEmpty ? 0 : g.attempts.length - 1);
    final latest = g.attempts.isEmpty ? null : g.attempts.first;
    final subtitle = [
      if (widget.fullHistory) g.hospitalName,
      g.categoryName,
      if (latest != null) 'Last sent ${QUi.day(latest.submittedAt)}',
    ].whereType<String>().join('  ·  ');
    final changed = g.attempts.length > 1 ? changedSincePrevious(g.attempts, 0).length : 0;

    return RecordCard(
      onTap: () => setState(() => open ? _open.remove(g.questionnaireId) : _open.add(g.questionnaireId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecordCardHeader(
            icon: PhosphorIconsBold.fileText,
            title: g.title,
            subtitle: subtitle.isEmpty ? null : subtitle,
            trailing: Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: RecordUi.ink(isDark)),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            RecordPill('${g.attempts.length} attempt${g.attempts.length == 1 ? '' : 's'}'),
            if (g.repeatAfterDays != null) RecordPill('Every ${g.repeatAfterDays} days'),
            if (changed > 0) RecordPill('$changed changed since last time', color: QUi.blue),
          ]),
          if (open && g.attempts.isNotEmpty) ...[
            const SizedBox(height: 14),
            AttemptAnswers(
              attempts: g.attempts,
              index: index,
              shrinkWrap: true,
              onSelect: (i) => setState(() => _attemptIndex[g.questionnaireId] = i),
            ),
          ],
        ],
      ),
    );
  }
}
