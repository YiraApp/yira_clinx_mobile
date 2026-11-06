import 'package:flutter/material.dart';

import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/questionnaires/questionnaire_remote_data_source.dart';
import '../../../data/models/questionnaires/questionnaire_models.dart';
import 'questionnaire_fill_screen.dart';
import 'questionnaire_history_screen.dart';
import 'questionnaire_ui.dart';

/// Questionnaires from the patient's hospitals: ones to fill in first, then
/// ones they can fill in again any time, then ones they've done.
class PatientQuestionnairesScreen extends StatefulWidget {
  final QuestionnaireRemoteDataSource? dataSource;

  const PatientQuestionnairesScreen({super.key, this.dataSource});

  @override
  State<PatientQuestionnairesScreen> createState() => _PatientQuestionnairesScreenState();
}

class _PatientQuestionnairesScreenState extends State<PatientQuestionnairesScreen> {
  late final QuestionnaireRemoteDataSource _source = widget.dataSource ?? QuestionnaireRemoteDataSource();
  List<PatientQuestionnaire>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items == null;
      _error = null;
    });
    try {
      final result = await _source.list();
      if (mounted) setState(() => _items = result.items);
    } catch (e) {
      if (mounted) setState(() => _error = questionnaireErrorMessage(e, "Couldn't load your questionnaires. Pull down to try again."));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(PatientQuestionnaire q) async {
    if (q.canSubmit) {
      final sent = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => QuestionnaireFillScreen(questionnaireId: q.id, title: q.title, dataSource: _source)),
      );
      if (sent == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you. Your answers were sent.'), behavior: SnackBarBehavior.floating),
        );
        _load();
      }
    } else if (q.history.isNotEmpty) {
      _history(q);
    }
  }

  void _history(PatientQuestionnaire q) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuestionnaireHistoryScreen(questionnaire: q, dataSource: _source)),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _items ?? const <PatientQuestionnaire>[];
    final due = items.where((q) => q.state == QuestionnaireState.due).toList();
    final available = items.where((q) => q.state == QuestionnaireState.available).toList();
    final done = items.where((q) => q.state == QuestionnaireState.completed).toList();

    return Scaffold(
      backgroundColor: QUi.background(isDark),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: QUi.background(isDark),
        iconTheme: IconThemeData(color: QUi.ink(isDark)),
        title: Text('Questionnaires', style: QUi.text(18, FontWeight.w700, QUi.ink(isDark))),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  if (_error != null)
                    QMessage(
                      icon: PhosphorIconsBold.warningCircle,
                      title: "Couldn't load",
                      message: _error,
                      actionLabel: 'Try again',
                      onAction: _load,
                    )
                  else if (items.isEmpty)
                    const QMessage(
                      icon: PhosphorIconsBold.fileText,
                      title: 'No questionnaires yet',
                      message: 'When your hospital or doctor asks you to fill in a questionnaire, it shows up here.',
                    )
                  else ...[
                    _Summary(dueCount: due.length, isDark: isDark),
                    if (due.isNotEmpty) ..._section('To fill in', due),
                    if (available.isNotEmpty) ..._section('Fill in again any time', available),
                    if (done.isNotEmpty) ..._section('Done', done),
                  ],
                ],
              ),
      ),
    );
  }

  List<Widget> _section(String title, List<PatientQuestionnaire> list) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(
          '${title.toUpperCase()}  ·  ${list.length}',
          style: QUi.text(11.5, FontWeight.w700, QUi.muted(isDark)).copyWith(letterSpacing: 0.6),
        ),
      ),
      for (final q in list) ...[
        QuestionnaireCardTile(questionnaire: q, onOpen: () => _open(q), onHistory: q.history.isEmpty ? null : () => _history(q)),
        const SizedBox(height: 10),
      ],
    ];
  }
}

/// One line at the top: how many are waiting, or that there's nothing to do.
class _Summary extends StatelessWidget {
  final int dueCount;
  final bool isDark;

  const _Summary({required this.dueCount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final waiting = dueCount > 0;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: waiting ? QUi.blueSoft(isDark) : QUi.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: waiting ? QUi.blue.withValues(alpha: 0.25) : QUi.line(isDark)),
      ),
      child: Row(
        children: [
          Icon(waiting ? Icons.assignment_outlined : Icons.check_circle_outline_rounded, color: waiting ? QUi.blue : QUi.ink(isDark), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waiting ? '$dueCount questionnaire${dueCount == 1 ? '' : 's'} to fill in' : "You're all caught up",
                  style: QUi.text(14.5, FontWeight.w700, QUi.ink(isDark)),
                ),
                const SizedBox(height: 2),
                Text(
                  waiting ? 'Your answers go straight to your doctor.' : "We'll let you know when there's a new one.",
                  style: QUi.text(12.5, FontWeight.w400, QUi.body(isDark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One questionnaire in the list: a full card with a Fill in button when it
/// needs answering, a compact row that opens the answers when it's done.
class QuestionnaireCardTile extends StatelessWidget {
  final PatientQuestionnaire questionnaire;
  final VoidCallback onOpen;
  final VoidCallback? onHistory;

  const QuestionnaireCardTile({super.key, required this.questionnaire, required this.onOpen, this.onHistory});

  static String _minutes(int questions) {
    final m = (questions * 15 / 60).ceil();
    return 'about ${m < 1 ? 1 : m} min';
  }

  /// "Due today", "Due in 8 days", "Overdue by 2 days".
  static ({String text, bool late})? _dueText(DateTime? dueAt) {
    if (dueAt == null) return null;
    final today = DateUtils.dateOnly(DateTime.now());
    final days = DateUtils.dateOnly(dueAt).difference(today).inDays;
    if (days < 0) return (text: 'Overdue by ${-days} day${days == -1 ? '' : 's'}', late: true);
    if (days == 0) return (text: 'Due today', late: true);
    if (days == 1) return (text: 'Due tomorrow', late: false);
    return (text: 'Due in $days days · ${QUi.day(dueAt)}', late: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = questionnaire;
    return q.canSubmit ? _toFill(isDark, q) : _done(isDark, q);
  }

  Widget _toFill(bool isDark, PatientQuestionnaire q) {
    final due = q.state == QuestionnaireState.due;
    final subtitle = [q.hospitalName, q.categoryName].whereType<String>().join('  ·  ');
    final dueText = _dueText(q.dueAt);
    final from = q.requestedBy != null
        ? 'Sent by ${q.requestedBy}'
        : q.requested
            ? 'Requested by your hospital'
            : (due && q.attempts > 0)
                ? 'Time to fill in again'
                : null;
    const amber = Color(0xFFB45309);

    return QCard(
      onTap: onOpen,
      borderColor: due ? QUi.blue.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: QUi.blueSoft(isDark), borderRadius: BorderRadius.circular(12)),
                child: const Icon(PhosphorIconsBold.fileText, size: 21, color: QUi.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.title, style: QUi.text(15.5, FontWeight.w700, QUi.ink(isDark), height: 1.3)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: QUi.text(12, FontWeight.w400, QUi.muted(isDark))),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if ((q.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(q.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: QUi.text(13, FontWeight.w400, QUi.body(isDark), height: 1.4)),
          ],
          const SizedBox(height: 12),
          if (from != null) _line(Icons.person_outline_rounded, from, QUi.body(isDark)),
          if (dueText != null) _line(Icons.schedule_rounded, dueText.text, dueText.late ? amber : QUi.blue, bold: true),
          _line(
            Icons.list_alt_rounded,
            '${q.questionCount} question${q.questionCount == 1 ? '' : 's'} · ${_minutes(q.questionCount)}'
            '${q.repeatAfterDays != null ? ' · every ${q.repeatAfterDays} days' : ''}',
            QUi.muted(isDark),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onHistory != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onHistory,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: QUi.ink(isDark),
                      side: BorderSide(color: QUi.line(isDark)),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Past answers', style: QUi.text(13.5, FontWeight.w600, QUi.ink(isDark))),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: onHistory != null ? 1 : 2,
                child: FilledButton(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: QUi.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(q.attempts > 0 ? 'Fill in again' : 'Fill in', style: QUi.text(14, FontWeight.w600, Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _done(bool isDark, PatientQuestionnaire q) {
    final filled = q.attempts == 0
        ? 'Not filled in'
        : 'Filled ${q.attempts == 1 ? 'once' : '${q.attempts} times'} · last on ${QUi.day(q.lastSubmittedAt)}';
    return QCard(
      onTap: onHistory ?? onOpen,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: QUi.sunken(isDark), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.task_alt_rounded, size: 21, color: QUi.ink(isDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.title, style: QUi.text(14.5, FontWeight.w700, QUi.ink(isDark), height: 1.3)),
                const SizedBox(height: 3),
                Text(filled, style: QUi.text(12, FontWeight.w400, QUi.muted(isDark))),
                if (q.nextDueAt != null) ...[
                  const SizedBox(height: 2),
                  Text('Next one opens ${QUi.day(q.nextDueAt)}', style: QUi.text(12, FontWeight.w600, QUi.blue)),
                ],
              ],
            ),
          ),
          if (onHistory != null) Icon(Icons.chevron_right_rounded, color: QUi.muted(isDark)),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, Color color, {bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: QUi.text(12.5, bold ? FontWeight.w600 : FontWeight.w500, color))),
          ],
        ),
      );
}
