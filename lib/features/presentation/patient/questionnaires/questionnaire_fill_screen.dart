import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/custom_dialogue/app_dialog.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/questionnaires/questionnaire_remote_data_source.dart';
import '../../../data/models/questionnaires/questionnaire_models.dart';
import 'questionnaire_ui.dart';

/// Fills in one questionnaire. Pops with true once the answers are sent.
class QuestionnaireFillScreen extends StatefulWidget {
  final int questionnaireId;
  final String title;
  final QuestionnaireRemoteDataSource? dataSource;

  /// For tests: skip loading and show this form.
  final QuestionnaireForm? initialForm;

  const QuestionnaireFillScreen({super.key, required this.questionnaireId, required this.title, this.dataSource, this.initialForm});

  @override
  State<QuestionnaireFillScreen> createState() => _QuestionnaireFillScreenState();
}

class _QuestionnaireFillScreenState extends State<QuestionnaireFillScreen> {
  late final QuestionnaireRemoteDataSource _source = widget.dataSource ?? QuestionnaireRemoteDataSource();
  QuestionnaireForm? _form;
  String? _loadError;
  bool _sending = false;
  bool _showErrors = false;
  final QuestionnaireAnswers _answers = {};
  final Map<int, TextEditingController> _text = {};
  final Map<int, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialForm != null) {
      _setForm(widget.initialForm!);
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setForm(QuestionnaireForm form) {
    _form = form;
    for (final q in form.questions) {
      _keys[q.id] = GlobalKey();
      if (const {QuestionType.shortText, QuestionType.longText, QuestionType.number}.contains(q.typeCode)) {
        _text[q.id] = TextEditingController()..addListener(() => setState(() => _answers[q.id] = _text[q.id]!.text));
      }
    }
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final form = await _source.form(widget.questionnaireId);
      if (!mounted) return;
      setState(() => _setForm(form));
    } catch (e) {
      if (mounted) setState(() => _loadError = questionnaireErrorMessage(e, "Couldn't open this questionnaire."));
    }
  }

  bool get _dirty => _answers.values.any(isAnswered);

  int get _requiredCount => _form?.questions.where((q) => q.isRequired).length ?? 0;
  int get _requiredDone => _form?.questions.where((q) => q.isRequired && isAnswered(_answers[q.id])).length ?? 0;
  int get _answeredCount => _form?.questions.where((q) => isAnswered(_answers[q.id])).length ?? 0;

  Future<void> _submit() async {
    final form = _form;
    if (form == null || _sending) return;
    FocusScope.of(context).unfocus();
    final firstProblem = form.questions.where((q) => answerProblem(q, _answers[q.id]) != null).firstOrNull;
    if (firstProblem != null) {
      setState(() => _showErrors = true);
      final ctx = _keys[firstProblem.id]?.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
      return;
    }
    if (_answeredCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer at least one question.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final ok = await AppDialog.confirm(
      context,
      title: 'Send your answers?',
      message: "You can't change them after sending. Your hospital and doctors can see them.",
      confirmLabel: 'Send',
      icon: PhosphorIconsBold.fileText,
      accentColor: QUi.blue,
    );
    if (!ok || !mounted) return;
    setState(() => _sending = true);
    try {
      await _source.submit(widget.questionnaireId, answersPayload(form.questions, _answers));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      await AppDialog.alert(
        context,
        title: "Couldn't send",
        message: questionnaireErrorMessage(e, 'Please check your connection and try again.'),
        tone: AppDialogTone.warning,
      );
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty || _sending) return true;
    return AppDialog.confirm(
      context,
      title: 'Discard your answers?',
      message: "You haven't sent them yet.",
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      tone: AppDialogTone.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final form = _form;
    final total = form?.questions.length ?? 0;
    final progress = total == 0 ? 0.0 : _answeredCount / total;

    return PopScope(
      canPop: !_dirty || _sending,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: QUi.background(isDark),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: QUi.ink(isDark)),
          title: Text(form?.info.title ?? widget.title,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: QUi.text(17, FontWeight.w700, QUi.ink(isDark))),
          bottom: form == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: QUi.line(isDark),
                    valueColor: const AlwaysStoppedAnimation(QUi.blue),
                  ),
                ),
        ),
        body: _loadError != null
            ? Center(child: QMessage(icon: PhosphorIconsBold.warningCircle, title: "Couldn't open", message: _loadError, actionLabel: 'Try again', onAction: _load))
            : form == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _intro(form, isDark),
                      const SizedBox(height: 16),
                      for (final (i, q) in form.questions.indexed) ...[
                        _QuestionCard(
                          key: _keys[q.id],
                          number: i + 1,
                          question: q,
                          value: _answers[q.id],
                          error: _showErrors ? answerProblem(q, _answers[q.id]) : null,
                          controller: _text[q.id],
                          onChanged: (v) => setState(() => _answers[q.id] = v),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
        bottomNavigationBar: form == null
            ? null
            : SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: QUi.card(isDark),
                    border: Border(top: BorderSide(color: QUi.line(isDark))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _requiredCount > 0 ? '$_requiredDone of $_requiredCount required answered' : '$_answeredCount of $total answered',
                          style: QUi.text(12.5, FontWeight.w500, QUi.muted(isDark)),
                        ),
                      ),
                      FilledButton(
                        onPressed: _sending ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: QUi.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _sending
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                            : Text('Send answers', style: QUi.text(14, FontWeight.w600, Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _intro(QuestionnaireForm form, bool isDark) {
    final info = form.info;
    final meta = [info.hospitalName, info.categoryName].whereType<String>().join('  ·  ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.isNotEmpty) Text(meta, style: QUi.text(12.5, FontWeight.w500, QUi.muted(isDark))),
        if ((info.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(info.description!, style: QUi.text(14, FontWeight.w400, QUi.body(isDark), height: 1.45)),
        ],
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          QChip('${form.questions.length} questions'),
          if (_requiredCount > 0) QChip('* $_requiredCount required'),
          if (info.attempts > 0) QChip('Attempt ${info.attempts + 1}', accent: true),
        ]),
      ],
    );
  }
}

/// One question with the right input for its type.
class _QuestionCard extends StatelessWidget {
  final int number;
  final QuestionnaireQuestion question;
  final Object? value;
  final String? error;
  final TextEditingController? controller;
  final ValueChanged<Object?> onChanged;

  const _QuestionCard({
    super.key,
    required this.number,
    required this.question,
    required this.value,
    required this.error,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = question;
    return QCard(
      borderColor: error != null ? QUi.red.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '$number. ', style: QUi.text(14.5, FontWeight.w600, QUi.muted(isDark))),
              TextSpan(text: q.text, style: QUi.text(14.5, FontWeight.w600, QUi.ink(isDark), height: 1.4)),
              if (q.isRequired) TextSpan(text: ' *', style: QUi.text(14.5, FontWeight.w700, QUi.red)),
            ]),
          ),
          if ((q.helpText ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(q.helpText!, style: QUi.text(12.5, FontWeight.w400, QUi.muted(isDark), height: 1.4)),
          ],
          const SizedBox(height: 12),
          _input(context, isDark),
          if (error != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(PhosphorIconsBold.warningCircle, size: 14, color: QUi.red),
              const SizedBox(width: 6),
              Expanded(child: Text(error!, style: QUi.text(12, FontWeight.w500, QUi.red))),
            ]),
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration(bool isDark, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: QUi.text(13.5, FontWeight.w400, QUi.muted(isDark)),
        filled: true,
        fillColor: QUi.sunken(isDark),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: QUi.line(isDark))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: QUi.line(isDark))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: QUi.blue, width: 1.5)),
      );

  Widget _input(BuildContext context, bool isDark) {
    final q = question;
    final style = QUi.text(14, FontWeight.w500, QUi.ink(isDark));
    switch (q.typeCode) {
      case QuestionType.longText:
        return TextField(controller: controller, minLines: 3, maxLines: 6, maxLength: 5000, style: style,
            decoration: _decoration(isDark, 'Type your answer').copyWith(counterText: ''));
      case QuestionType.number:
        final range = [
          if (q.minValue != null) 'min ${_n(q.minValue!)}',
          if (q.maxValue != null) 'max ${_n(q.maxValue!)}',
        ].join(', ');
        return TextField(
          controller: controller,
          style: style,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
          decoration: _decoration(isDark, range.isEmpty ? 'Enter a number' : 'Enter a number ($range)'),
        );
      case QuestionType.rating:
        return Row(
          children: [
            for (var n = 1; n <= 5; n++) ...[
              Expanded(child: _pill(isDark, '$n', value == n, () => onChanged(value == n ? null : n), tall: true)),
              if (n < 5) const SizedBox(width: 8),
            ],
          ],
        );
      case QuestionType.yesNo:
        return Row(children: [
          Expanded(child: _pill(isDark, 'Yes', value == 'Yes', () => onChanged(value == 'Yes' ? null : 'Yes'))),
          const SizedBox(width: 10),
          Expanded(child: _pill(isDark, 'No', value == 'No', () => onChanged(value == 'No' ? null : 'No'))),
        ]);
      case QuestionType.singleChoice:
        return Column(children: [
          for (final o in q.options)
            _option(isDark, o.label, value == o.id, false, () => onChanged(value == o.id ? null : o.id)),
        ]);
      case QuestionType.multiChoice:
        final picked = (value is List ? value as List : const []).cast<int>();
        return Column(children: [
          for (final o in q.options)
            _option(isDark, o.label, picked.contains(o.id), true, () {
              final next = [...picked];
              next.contains(o.id) ? next.remove(o.id) : next.add(o.id);
              onChanged(next);
            }),
        ]);
      case QuestionType.dropdown:
        return DropdownButtonFormField<int>(
          initialValue: value is int ? value as int : null,
          isExpanded: true,
          style: style,
          dropdownColor: QUi.card(isDark),
          decoration: _decoration(isDark, 'Choose one'),
          items: [for (final o in q.options) DropdownMenuItem(value: o.id, child: Text(o.label, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => onChanged(v),
        );
      case QuestionType.date:
        final picked = value is String ? DateTime.tryParse(value as String) : null;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              initialDate: picked ?? now,
              firstDate: DateTime(1900),
              lastDate: DateTime(now.year + 10),
            );
            if (d != null) onChanged(DateFormat('yyyy-MM-dd').format(d));
          },
          child: InputDecorator(
            decoration: _decoration(isDark, 'Pick a date').copyWith(suffixIcon: Icon(PhosphorIconsBold.calendarBlank, size: 18, color: QUi.muted(isDark))),
            isEmpty: picked == null,
            child: picked == null ? null : Text(DateFormat('d MMM yyyy').format(picked), style: style),
          ),
        );
      default:
        return TextField(controller: controller, maxLength: 500, style: style,
            decoration: _decoration(isDark, 'Type your answer').copyWith(counterText: ''));
    }
  }

  static String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Widget _pill(bool isDark, String label, bool selected, VoidCallback onTap, {bool tall = false}) => Material(
        color: selected ? QUi.blue : QUi.sunken(isDark),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: tall ? 48 : 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? QUi.blue : QUi.line(isDark)),
            ),
            child: Text(label, style: QUi.text(14, FontWeight.w600, selected ? Colors.white : QUi.ink(isDark))),
          ),
        ),
      );

  Widget _option(bool isDark, String label, bool selected, bool multi, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected ? QUi.blueSoft(isDark) : QUi.sunken(isDark),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? QUi.blue : QUi.line(isDark)),
              ),
              child: Row(children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected ? QUi.blue : Colors.transparent,
                    shape: multi ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: multi ? BorderRadius.circular(5) : null,
                    border: Border.all(color: selected ? QUi.blue : QUi.muted(isDark), width: 1.6),
                  ),
                  child: selected ? const Icon(PhosphorIconsBold.check, size: 12, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: QUi.text(14, FontWeight.w500, QUi.ink(isDark), height: 1.3))),
              ]),
            ),
          ),
        ),
      );
}
