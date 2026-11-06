import 'package:flutter/material.dart';

import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/questionnaires/questionnaire_remote_data_source.dart';
import '../../../data/models/questionnaires/questionnaire_models.dart';
import 'questionnaire_ui.dart';

/// A patient's past answers to one questionnaire, one attempt at a time.
/// Answers that differ from the attempt before are marked.
class QuestionnaireHistoryScreen extends StatefulWidget {
  final PatientQuestionnaire questionnaire;
  final QuestionnaireRemoteDataSource? dataSource;

  const QuestionnaireHistoryScreen({super.key, required this.questionnaire, this.dataSource});

  @override
  State<QuestionnaireHistoryScreen> createState() => _QuestionnaireHistoryScreenState();
}

class _QuestionnaireHistoryScreenState extends State<QuestionnaireHistoryScreen> {
  late final QuestionnaireRemoteDataSource _source = widget.dataSource ?? QuestionnaireRemoteDataSource();
  List<QuestionnaireSubmission>? _attempts;
  String? _error;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      // Newest first, as the list sends them. There are only a few per patient.
      final attempts = await Future.wait(widget.questionnaire.history.map((a) => _source.submission(a.id)));
      if (mounted) setState(() => _attempts = attempts);
    } catch (e) {
      if (mounted) setState(() => _error = questionnaireErrorMessage(e, "Couldn't load your answers."));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attempts = _attempts;
    return Scaffold(
      backgroundColor: QUi.background(isDark),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: QUi.ink(isDark)),
        title: Text(widget.questionnaire.title,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: QUi.text(17, FontWeight.w700, QUi.ink(isDark))),
      ),
      body: _error != null
          ? Center(child: QMessage(icon: PhosphorIconsBold.warningCircle, title: "Couldn't load", message: _error, actionLabel: 'Try again', onAction: _load))
          : attempts == null
              ? const Center(child: CircularProgressIndicator())
              : attempts.isEmpty
                  ? const Center(child: QMessage(icon: PhosphorIconsBold.fileText, title: 'No answers yet'))
                  : AttemptAnswers(attempts: attempts, index: _index, onSelect: (i) => setState(() => _index = i)),
    );
  }
}

/// Attempt chips (newest first) over the chosen attempt's answers. Shared with the doctor's tab.
class AttemptAnswers extends StatelessWidget {
  final List<QuestionnaireSubmission> attempts;
  final int index;
  final ValueChanged<int> onSelect;
  final bool shrinkWrap;

  const AttemptAnswers({super.key, required this.attempts, required this.index, required this.onSelect, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = attempts[index.clamp(0, attempts.length - 1)];
    final changed = changedSincePrevious(attempts, index);
    final children = <Widget>[
      if (attempts.length > 1) ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final (i, a) in attempts.indexed) ...[
              ChoiceChip(
                label: Text('Attempt ${a.attemptNo}  ·  ${QUi.day(a.submittedAt)}'),
                selected: i == index,
                onSelected: (_) => onSelect(i),
                showCheckmark: false,
                selectedColor: QUi.blue,
                backgroundColor: QUi.card(isDark),
                side: BorderSide(color: i == index ? QUi.blue : QUi.line(isDark)),
                labelStyle: QUi.text(12, FontWeight.w600, i == index ? Colors.white : QUi.ink(isDark)),
              ),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: 12),
      ],
      Row(children: [
        Icon(PhosphorIconsBold.checkCircle, size: 16, color: QUi.muted(isDark)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Sent ${QUi.dayTime(current.submittedAt)}${current.hospitalName == null ? '' : '  ·  ${current.hospitalName}'}',
            style: QUi.text(12.5, FontWeight.w500, QUi.muted(isDark)),
          ),
        ),
      ]),
      if (changed.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text('${changed.length} answer${changed.length == 1 ? '' : 's'} changed since attempt ${attempts[index + 1].attemptNo}',
            style: QUi.text(12.5, FontWeight.w600, QUi.blue)),
      ],
      const SizedBox(height: 12),
      for (final (i, a) in current.answers.indexed) ...[
        QAnswerTile(number: i + 1, answer: a, changed: changed.contains(a.questionId)),
        const SizedBox(height: 8),
      ],
    ];
    if (shrinkWrap) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: children);
  }
}
