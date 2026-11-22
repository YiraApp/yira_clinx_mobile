import 'package:yiraclinics/core/widgets/ios_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/custom_dialogue/app_dialog.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/questionnaires/questionnaire_remote_data_source.dart';
import '../../../data/models/questionnaires/questionnaire_models.dart';
import '../../patient/questionnaires/questionnaire_ui.dart';
import 'questionnaire_template_editor_screen.dart';

/// Bottom sheet for a doctor (or other staff) to send a questionnaire to this
/// patient: one of their own (made, edited and removed here, as on the web) or
/// one the hospital published. Returns the title sent, or null.
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

  /// Loads the list; [prefer] selects that one (just saved) when it can be sent.
  Future<void> _load({int? prefer}) async {
    setState(() => _error = null);
    try {
      final items = await _source.sendable(widget.patientId, hospitalId: widget.hospitalId);
      if (!mounted) return;
      bool sendable(int? id) => id != null && items.any((q) => q.id == id && q.canSend);
      setState(() {
        _items = items;
        if (sendable(prefer)) {
          _selected = prefer;
        } else if (!sendable(_selected)) {
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

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  /// Opens the editor for a new questionnaire ([q] null) or one of the doctor's own.
  Future<void> _openEditor([SendableQuestionnaire? q]) async {
    final savedId = await QuestionnaireTemplateEditorScreen.open(
      context,
      hospitalId: widget.hospitalId,
      templateId: q?.id,
      dataSource: widget.dataSource,
    );
    if (!mounted || savedId == null) return;
    await _load(prefer: savedId);
    if (!mounted) return;
    final saved = _items?.where((i) => i.id == savedId).firstOrNull;
    _snack(saved == null ? 'Saved to your questionnaires.' : 'Saved "${saved.title}". It\'s ready to send.');
  }

  Future<void> _remove(SendableQuestionnaire q) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Remove this questionnaire?',
      message: "\"${q.title}\" comes off your list and patients who haven't answered it yet won't be asked any more. Answers already given still show.",
      confirmLabel: 'Remove',
      cancelLabel: 'Keep it',
      tone: AppDialogTone.danger,
      icon: PhosphorIconsBold.trash,
    );
    if (!ok || !mounted) return;
    try {
      final closed = await _source.removeTemplate(q.id, hospitalId: widget.hospitalId);
      if (!mounted) return;
      if (_selected == q.id) _selected = null;
      _snack(closed ? 'Removed "${q.title}". Answers already given still show.' : 'Deleted "${q.title}".');
    } catch (e) {
      if (!mounted) return;
      _snack(questionnaireErrorMessage(e, "Couldn't remove the questionnaire."));
    }
    if (mounted) await _load();
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
    final mine = items?.where((q) => q.mine).toList() ?? const <SendableQuestionnaire>[];
    final hospital = items?.where((q) => !q.mine).toList() ?? const <SendableQuestionnaire>[];

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
                    icon: Icon(IosIcons.close_rounded, color: QUi.muted(isDark)),
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
                          ? SingleChildScrollView(
                              child: QMessage(
                                icon: PhosphorIconsBold.fileText,
                                title: 'No questionnaires yet',
                                message: "There's nothing to send yet. Create your own: it's saved, so you can send it to other patients too.",
                                actionLabel: 'Create questionnaire',
                                onAction: () => _openEditor(),
                              ),
                            )
                          : ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              children: [
                                _createButton(isDark),
                                if (mine.isNotEmpty) ...[
                                  _groupLabel('Your questionnaires', mine.length, isDark),
                                  for (final q in mine) ...[
                                    _option(q, isDark),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                                if (hospital.isNotEmpty) ...[
                                  _groupLabel('Hospital questionnaires', hospital.length, isDark),
                                  for (final q in hospital) ...[
                                    _option(q, isDark),
                                    const SizedBox(height: 8),
                                  ],
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 50),
                child: FilledButton.icon(
                  onPressed: chosen == null || _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: QUi.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(IosIcons.send_rounded, size: 18, color: Colors.white),
                  label: Text(
                    chosen == null ? 'Choose a questionnaire' : 'Send "${chosen.title}"',
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

  Widget _createButton(bool isDark) => OutlinedButton.icon(
        onPressed: () => _openEditor(),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          foregroundColor: QUi.blue,
          side: BorderSide(color: QUi.blue.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(PhosphorIconsBold.plus, size: 18),
        label: Text('Create questionnaire', style: QUi.text(14, FontWeight.w600, QUi.blue)),
      );

  Widget _groupLabel(String title, int count, bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          '${title.toUpperCase()}  ·  $count',
          style: QUi.text(11.5, FontWeight.w700, QUi.muted(isDark)).copyWith(letterSpacing: 0.6),
        ),
      );

  Widget _option(SendableQuestionnaire q, bool isDark) {
    final active = q.id == _selected;
    final faded = q.canSend ? 1.0 : 0.55;
    final meta = [
      if (q.categoryName != null) q.categoryName!,
      '${q.questionCount} question${q.questionCount == 1 ? '' : 's'}',
      if (q.targetGender != 'All') '${q.targetGender} only',
    ].join(' · ');
    return Opacity(
      // The doctor's own stay editable when they can't be sent, so only their text fades.
      opacity: q.mine ? 1 : faded,
      child: QCard(
        padding: EdgeInsets.fromLTRB(14, 14, q.mine ? 2 : 14, 14),
        borderColor: active ? QUi.blue : null,
        onTap: q.canSend ? () => setState(() => _selected = q.id) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Opacity(
                opacity: q.mine ? faded : 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        active ? IosIcons.radio_button_checked_rounded : IosIcons.radio_button_unchecked_rounded,
                        size: 20,
                        color: active ? QUi.blue : QUi.muted(isDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(q.title, style: QUi.text(14.5, FontWeight.w600, QUi.ink(isDark))),
                              if (q.mine) const QChip('Yours', accent: true),
                            ],
                          ),
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
            ),
            if (q.mine)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _openEditor(q),
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                    iconSize: 19,
                    color: QUi.body(isDark),
                    icon: const Icon(PhosphorIconsBold.pencilSimple),
                  ),
                  IconButton(
                    onPressed: () => _remove(q),
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    iconSize: 19,
                    color: QUi.red,
                    icon: const Icon(PhosphorIconsBold.trash),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
