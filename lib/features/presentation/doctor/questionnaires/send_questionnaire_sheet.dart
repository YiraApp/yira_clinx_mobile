import 'package:flutter/material.dart';

import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/questionnaires/questionnaire_remote_data_source.dart';
import '../../../data/models/questionnaires/questionnaire_models.dart';
import '../../patient/questionnaires/questionnaire_ui.dart';

/// Bottom sheet for a doctor (or other staff) to send one of the hospital's
/// published questionnaires to this patient. Returns the title sent, or null.
class SendQuestionnaireSheet extends StatefulWidget {
  final String patientId;
  final String hospitalId;
  final String? patientName;
  final QuestionnaireRemoteDataSource? dataSource;

  const SendQuestionnaireSheet({
    super.key,
    required this.patientId,
    required this.hospitalId,
    this.patientName,
    this.dataSource,
  });

  static Future<String?> show(BuildContext context, {required String patientId, required String hospitalId, String? patientName}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SendQuestionnaireSheet(patientId: patientId, hospitalId: hospitalId, patientName: patientName),
    );
  }

  @override
  State<SendQuestionnaireSheet> createState() => _SendQuestionnaireSheetState();
}

class _SendQuestionnaireSheetState extends State<SendQuestionnaireSheet> {
  late final QuestionnaireRemoteDataSource _source = widget.dataSource ?? QuestionnaireRemoteDataSource();
  List<SendableQuestionnaire>? _items;
  String? _error;
  int? _selected;
  int? _dueInDays = 7;
  bool _sending = false;

  static const _dueChoices = <int?>[null, 3, 7, 14];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await _source.sendable(widget.patientId, hospitalId: widget.hospitalId);
      if (!mounted) return;
      setState(() {
        _items = items;
        if (_selected == null || !items.any((q) => q.id == _selected && q.canSend)) {
          _selected = items.where((q) => q.canSend).map((q) => q.id).firstOrNull;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _error = questionnaireErrorMessage(e, "Couldn't load the questionnaires.");
      });
    }
  }

  Future<void> _send() async {
    final chosen = _items?.where((q) => q.id == _selected).firstOrNull;
    if (chosen == null) return;
    setState(() => _sending = true);
    try {
      await _source.sendToPatient(widget.patientId, chosen.id, hospitalId: widget.hospitalId, dueInDays: _dueInDays);
      if (!mounted) return;
      Navigator.of(context).pop(chosen.title);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(questionnaireErrorMessage(e, "Couldn't send the questionnaire.")), behavior: SnackBarBehavior.floating),
      );
      _load();
    }
  }

  String _standing(SendableQuestionnaire q) {
    if (q.pending) {
      final by = q.pendingSentBy != null ? ' by ${q.pendingSentBy}' : '';
      final due = q.pendingDueAt != null ? ', due ${QUi.day(q.pendingDueAt)}' : '';
      return 'Waiting for an answer: sent$by on ${QUi.day(q.pendingSentAt)}$due.';
    }
    if (q.reason != null) return q.reason!;
    if (q.attempts == 0) return 'Not filled in yet.';
    final times = q.attempts == 1 ? 'once' : '${q.attempts} times';
    return 'Filled in $times, last on ${QUi.day(q.lastSubmittedAt)}.${q.allowMultiple ? '' : ' Sending asks them to fill it in again.'}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _items;
    final chosen = items?.where((q) => q.id == _selected).firstOrNull;
    final name = (widget.patientName ?? '').trim();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(color: QUi.card(isDark), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: QUi.line(isDark), borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send a questionnaire', style: QUi.text(18, FontWeight.w700, QUi.ink(isDark))),
                        const SizedBox(height: 2),
                        Text(
                          '${name.isEmpty ? 'The patient' : name} gets a notification and fills it in from Questionnaires.',
                          style: QUi.text(13, FontWeight.w400, QUi.muted(isDark)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: QUi.muted(isDark)),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Flexible(
              child: items == null
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  : _error != null
                      ? QMessage(icon: PhosphorIconsBold.warningCircle, title: "Couldn't load", message: _error!, actionLabel: 'Try again', onAction: _load)
                      : items.isEmpty
                          ? const QMessage(
                              icon: PhosphorIconsBold.fileText,
                              title: 'No questionnaires to send',
                              message: "This hospital hasn't published any questionnaires yet.",
                            )
                          : ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              children: [
                                for (final q in items) ...[
                                  _option(q, isDark),
                                  const SizedBox(height: 8),
                                ],
                                const SizedBox(height: 8),
                                Text('Fill in by', style: QUi.text(13, FontWeight.w600, QUi.ink(isDark))),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final d in _dueChoices)
                                      ChoiceChip(
                                        label: Text(d == null ? 'No due date' : 'Within $d days'),
                                        selected: _dueInDays == d,
                                        onSelected: (_) => setState(() => _dueInDays = d),
                                        labelStyle: QUi.text(12.5, FontWeight.w600, _dueInDays == d ? Colors.white : QUi.body(isDark)),
                                        selectedColor: QUi.blue,
                                        backgroundColor: QUi.sunken(isDark),
                                        side: BorderSide(color: _dueInDays == d ? QUi.blue : QUi.line(isDark)),
                                        showCheckmark: false,
                                      ),
                                  ],
                                ),
                              ],
                            ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: chosen == null || _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: QUi.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  label: Text(
                    chosen == null ? 'Choose a questionnaire' : 'Send "${chosen.title}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QUi.text(15, FontWeight.w600, Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(SendableQuestionnaire q, bool isDark) {
    final active = q.id == _selected;
    final meta = [
      if (q.categoryName != null) q.categoryName!,
      '${q.questionCount} question${q.questionCount == 1 ? '' : 's'}',
      if (q.targetGender != 'All') '${q.targetGender} only',
    ].join(' · ');
    return Opacity(
      opacity: q.canSend ? 1 : 0.55,
      child: QCard(
        padding: const EdgeInsets.all(14),
        borderColor: active ? QUi.blue : null,
        onTap: q.canSend ? () => setState(() => _selected = q.id) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                active ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: active ? QUi.blue : QUi.muted(isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.title, style: QUi.text(14.5, FontWeight.w600, QUi.ink(isDark))),
                  const SizedBox(height: 2),
                  Text(meta, style: QUi.text(12, FontWeight.w400, QUi.muted(isDark))),
                  const SizedBox(height: 6),
                  Text(
                    _standing(q),
                    style: QUi.text(12, FontWeight.w500, q.pending ? const Color(0xFFB45309) : QUi.body(isDark), height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
