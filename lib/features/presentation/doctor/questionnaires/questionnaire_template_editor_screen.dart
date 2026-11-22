import 'dart:convert';

import 'package:yiraclinics/core/widgets/fit_text.dart';
import 'package:yiraclinics/core/widgets/ios_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/custom_dialogue/app_dialog.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/questionnaires/questionnaire_remote_data_source.dart';
import '../../../data/models/questionnaires/questionnaire_models.dart';
import '../../patient/questionnaires/questionnaire_ui.dart';

/// Makes or edits one of the doctor's own questionnaires: a name, a note for
/// the patient, the questions, and whether it can be filled in more than once.
/// It's saved ready to send. Pops with the saved questionnaire's id, or null.
class QuestionnaireTemplateEditorScreen extends StatefulWidget {
  final String hospitalId;

  /// Leave out to make a new one.
  final int? templateId;
  final QuestionnaireRemoteDataSource? dataSource;

  /// For tests: skip loading and edit this one.
  final QuestionnaireTemplateDetail? initialTemplate;

  const QuestionnaireTemplateEditorScreen({
    super.key,
    required this.hospitalId,
    this.templateId,
    this.dataSource,
    this.initialTemplate,
  });

  static Future<int?> open(BuildContext context, {required String hospitalId, int? templateId, QuestionnaireRemoteDataSource? dataSource}) {
    return Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => QuestionnaireTemplateEditorScreen(hospitalId: hospitalId, templateId: templateId, dataSource: dataSource),
      ),
    );
  }

  @override
  State<QuestionnaireTemplateEditorScreen> createState() => _QuestionnaireTemplateEditorScreenState();
}

/// One question while it's being edited.
class _EditQuestion {
  _EditQuestion(TemplateQuestionDraft q, this._onChange)
      : text = TextEditingController(text: q.text),
        help = TextEditingController(text: q.helpText),
        min = TextEditingController(text: q.minValue),
        max = TextEditingController(text: q.maxValue),
        typeCode = templateQuestionTypes.contains(q.typeCode) ? q.typeCode : QuestionType.shortText,
        isRequired = q.isRequired {
    for (final c in [text, help, min, max]) {
      c.addListener(_onChange);
    }
    for (final o in q.options) {
      addOption(o);
    }
    _fillOptions();
  }

  final VoidCallback _onChange;
  final GlobalKey key = GlobalKey();
  final TextEditingController text;
  final TextEditingController help;
  final TextEditingController min;
  final TextEditingController max;
  final List<TextEditingController> options = [];
  String typeCode;
  bool isRequired;

  void addOption([String value = '']) => options.add(TextEditingController(text: value)..addListener(_onChange));

  /// A choice question starts with two empty options.
  void _fillOptions() {
    if (!needsOptions(typeCode)) return;
    while (options.length < 2) {
      addOption();
    }
  }

  void setType(String code) {
    typeCode = code;
    _fillOptions();
  }

  TemplateQuestionDraft get draft => TemplateQuestionDraft(
        text: text.text,
        typeCode: typeCode,
        helpText: help.text,
        isRequired: isRequired,
        options: [for (final o in options) o.text],
        minValue: min.text,
        maxValue: max.text,
      );

  List<Object> get fingerprint => [text.text, typeCode, help.text, isRequired, min.text, max.text, for (final o in options) o.text];

  void dispose() {
    for (final c in [text, help, min, max, ...options]) {
      c.dispose();
    }
  }
}

/// A controller still attached to a field is disposed after the field is gone.
void _disposeLater(void Function() dispose) => WidgetsBinding.instance.addPostFrameCallback((_) => dispose());

class _QuestionnaireTemplateEditorScreenState extends State<QuestionnaireTemplateEditorScreen> {
  late final QuestionnaireRemoteDataSource _source = widget.dataSource ?? QuestionnaireRemoteDataSource();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _detailsKey = GlobalKey();
  final List<_EditQuestion> _questions = [];
  bool _allowMultiple = true;
  bool _locked = false;
  bool _ready = false;
  String? _loadError;
  bool _saving = false;
  bool _showErrors = false;
  String _saved = '';

  bool get _isNew => widget.templateId == null;

  @override
  void initState() {
    super.initState();
    _title.addListener(_changed);
    _description.addListener(_changed);
    if (widget.initialTemplate != null) {
      _fill(widget.initialTemplate!);
    } else if (_isNew) {
      _fill(const QuestionnaireTemplateDetail(id: 0, title: '', questions: [TemplateQuestionDraft(text: '')]));
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _fill(QuestionnaireTemplateDetail t) {
    _title.text = t.title;
    _description.text = t.description ?? '';
    _allowMultiple = t.allowMultiple;
    _locked = t.questionsLocked;
    for (final q in _questions) {
      q.dispose();
    }
    _questions
      ..clear()
      ..addAll(t.questions.map((q) => _EditQuestion(q, _changed)));
    if (_questions.isEmpty && !_locked) _questions.add(_EditQuestion(const TemplateQuestionDraft(text: ''), _changed));
    _ready = true;
    _saved = _fingerprint();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final t = await _source.getTemplate(widget.templateId!, hospitalId: widget.hospitalId);
      if (!mounted) return;
      setState(() => _fill(t));
    } catch (e) {
      if (mounted) setState(() => _loadError = questionnaireErrorMessage(e, "Couldn't open this questionnaire."));
    }
  }

  String _fingerprint() => jsonEncode([_title.text, _description.text, _allowMultiple, for (final q in _questions) q.fingerprint]);

  bool get _dirty => _ready && _fingerprint() != _saved;

  TemplateProblem? _problem() {
    if (_locked) return _title.text.trim().isEmpty ? const TemplateProblem('Give the questionnaire a name.') : null;
    return templateProblem(_title.text, [for (final q in _questions) q.draft]);
  }

  void _addQuestion() {
    setState(() => _questions.add(_EditQuestion(const TemplateQuestionDraft(text: ''), _changed)));
    final added = _questions.last.key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = added.currentContext;
      if (ctx != null && ctx.mounted) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.2);
    });
  }

  void _removeQuestion(_EditQuestion q) {
    setState(() => _questions.remove(q));
    _disposeLater(q.dispose);
  }

  void _move(int index, int by) {
    setState(() {
      final q = _questions.removeAt(index);
      _questions.insert(index + by, q);
    });
  }

  void _removeOption(_EditQuestion q, TextEditingController option) {
    setState(() => q.options.remove(option));
    _disposeLater(option.dispose);
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final problem = _problem();
    if (problem != null) {
      setState(() => _showErrors = true);
      final at = problem.question;
      final ctx = at == null || at >= _questions.length ? _detailsKey.currentContext : _questions[at].key.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
      return;
    }
    setState(() => _saving = true);
    final draft = QuestionnaireTemplateDraft(
      title: _title.text,
      description: _description.text,
      allowMultiple: _allowMultiple,
      questions: _locked ? null : [for (final q in _questions) q.draft],
    );
    try {
      final saved = _isNew
          ? await _source.createTemplate(draft, hospitalId: widget.hospitalId)
          : await _source.updateTemplate(widget.templateId!, draft, hospitalId: widget.hospitalId);
      if (mounted) Navigator.of(context).pop(saved.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await AppDialog.alert(
        context,
        title: "Couldn't save",
        message: questionnaireErrorMessage(e, "Couldn't save the questionnaire. Please try again."),
        tone: AppDialogTone.warning,
      );
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty || _saving) return true;
    return AppDialog.confirm(
      context,
      title: 'Discard your changes?',
      message: "You haven't saved this questionnaire yet.",
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      tone: AppDialogTone.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final problem = _showErrors && _ready ? _problem() : null;

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: QUi.background(isDark),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: QUi.ink(isDark)),
          title: FitText(_isNew ? 'New questionnaire' : 'Edit questionnaire', style: QUi.text(17, FontWeight.w700, QUi.ink(isDark)), maxLines: 1),
        ),
        body: _loadError != null
            ? Center(
                child: QMessage(icon: PhosphorIconsBold.warningCircle, title: "Couldn't open", message: _loadError, actionLabel: 'Try again', onAction: _load),
              )
            : !_ready
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Saved to your questionnaires, so you can send it to any of your patients. Only you see it in your list.',
                          style: QUi.text(13, FontWeight.w400, QUi.muted(isDark), height: 1.45),
                        ),
                        const SizedBox(height: 14),
                        _details(isDark, problem),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('QUESTIONS', style: QUi.text(11.5, FontWeight.w700, QUi.muted(isDark)).copyWith(letterSpacing: 0.6)),
                              ),
                              if (!_locked)
                                Text('${_questions.length} of ${TemplateLimits.questions}', style: QUi.text(12, FontWeight.w500, QUi.muted(isDark))),
                            ],
                          ),
                        ),
                        if (_locked) ...[_lockedNote(isDark), const SizedBox(height: 12)],
                        for (final (i, q) in _questions.indexed) ...[
                          _locked ? _readOnlyQuestion(i, q, isDark) : _questionCard(i, q, isDark, problem?.question == i),
                          const SizedBox(height: 12),
                        ],
                        if (!_locked && _questions.length < TemplateLimits.questions)
                          OutlinedButton.icon(
                            onPressed: _addQuestion,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: QUi.blue,
                              side: BorderSide(color: QUi.blue.withValues(alpha: 0.45)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(PhosphorIconsBold.plus, size: 18),
                            label: Text('Add question', style: QUi.text(14, FontWeight.w600, QUi.blue)),
                          ),
                      ],
                    ),
                  ),
        bottomNavigationBar: !_ready || _loadError != null ? null : _saveBar(isDark, problem),
      ),
    );
  }

  Widget _saveBar(bool isDark, TemplateProblem? problem) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: QUi.card(isDark),
          border: Border(top: BorderSide(color: QUi.line(isDark))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (problem != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 1), child: Icon(PhosphorIconsBold.warningCircle, size: 16, color: QUi.red)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(problem.message, style: QUi.text(12.5, FontWeight.w500, QUi.red, height: 1.35))),
                ],
              ),
              const SizedBox(height: 10),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: QUi.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : Text(_isNew ? 'Save questionnaire' : 'Save', style: QUi.text(15, FontWeight.w600, Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(bool isDark, TemplateProblem? problem) {
    final titleMissing = problem != null && problem.question == null && _title.text.trim().isEmpty;
    return QCard(
      key: _detailsKey,
      borderColor: titleMissing ? QUi.red.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Name', isDark, required: true),
          TextField(
            controller: _title,
            maxLength: TemplateLimits.title,
            maxLines: null,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            style: _fieldStyle(isDark),
            decoration: _decoration(isDark, 'e.g. Knee pain follow-up'),
          ),
          const SizedBox(height: 14),
          _label('Note for the patient', isDark),
          TextField(
            controller: _description,
            maxLength: TemplateLimits.description,
            minLines: 2,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: _fieldStyle(isDark),
            decoration: _decoration(isDark, "Optional: what it's for"),
          ),
          const SizedBox(height: 8),
          _switchRow(
            'Patient can fill it in more than once',
            _allowMultiple,
            (v) => setState(() => _allowMultiple = v),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _lockedNote(bool isDark) {
    const amber = Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(IosIcons.lock_outline_rounded, size: 16, color: isDark ? const Color(0xFFFBBF24) : amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Patients have answered this questionnaire, so its questions can't change. You can still rename it. To ask different questions, make a new one.",
              style: QUi.text(12.5, FontWeight.w500, isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(int i, _EditQuestion q, bool isDark, bool hasProblem) {
    final last = _questions.length - 1;
    return QCard(
      key: q.key,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 14),
      borderColor: hasProblem ? QUi.red.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Question ${i + 1}', style: QUi.text(13, FontWeight.w700, QUi.muted(isDark)))),
              _iconButton(IosIcons.keyboard_arrow_up_rounded, 'Move up', i == 0 ? null : () => _move(i, -1), isDark),
              _iconButton(IosIcons.keyboard_arrow_down_rounded, 'Move down', i == last ? null : () => _move(i, 1), isDark),
              _iconButton(PhosphorIconsBold.trash, 'Remove question', _questions.length == 1 ? null : () => _removeQuestion(q), isDark),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: q.text,
                  maxLength: TemplateLimits.question,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  style: _fieldStyle(isDark),
                  decoration: _decoration(isDark, 'Type the question'),
                ),
                const SizedBox(height: 10),
                _label('Answer type', isDark),
                DropdownButtonFormField<String>(
                  initialValue: q.typeCode,
                  isExpanded: true,
                  // Labels wrap instead of being cut.
                  itemHeight: null,
                  style: _fieldStyle(isDark),
                  dropdownColor: QUi.card(isDark),
                  borderRadius: BorderRadius.circular(12),
                  decoration: _decoration(isDark, 'Choose one'),
                  items: [
                    for (final code in templateQuestionTypes) DropdownMenuItem(value: code, child: Text(questionTypeLabel(code))),
                  ],
                  onChanged: (code) {
                    if (code != null) setState(() => q.setType(code));
                  },
                ),
                const SizedBox(height: 6),
                _switchRow('Required', q.isRequired, (v) => setState(() => q.isRequired = v), isDark),
                const SizedBox(height: 4),
                TextField(
                  controller: q.help,
                  maxLength: TemplateLimits.helpText,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  style: _fieldStyle(isDark),
                  decoration: _decoration(isDark, 'Optional hint for the patient'),
                ),
                if (needsOptions(q.typeCode)) ...[
                  const SizedBox(height: 12),
                  _label('Options', isDark),
                  for (final (k, option) in q.options.indexed)
                    Padding(
                      key: ObjectKey(option),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: option,
                              maxLength: TemplateLimits.option,
                              maxLines: null,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.sentences,
                              style: _fieldStyle(isDark),
                              decoration: _decoration(isDark, 'Option ${k + 1}'),
                            ),
                          ),
                          if (q.options.length > 2) _iconButton(IosIcons.close_rounded, 'Remove option ${k + 1}', () => _removeOption(q, option), isDark),
                        ],
                      ),
                    ),
                  if (q.options.length < TemplateLimits.options)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => q.addOption()),
                        style: TextButton.styleFrom(foregroundColor: QUi.blue, padding: const EdgeInsets.symmetric(horizontal: 8)),
                        icon: const Icon(PhosphorIconsBold.plus, size: 16),
                        label: Text('Add option', style: QUi.text(13, FontWeight.w600, QUi.blue)),
                      ),
                    ),
                ],
                if (q.typeCode == QuestionType.number) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _numberField('Lowest allowed', q.min, isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _numberField('Highest allowed', q.max, isDark)),
                    ],
                  ),
                ],
                if (q.typeCode == QuestionType.rating) ...[
                  const SizedBox(height: 10),
                  Text('The patient picks a number from 1 to 5.', style: QUi.text(12, FontWeight.w400, QUi.muted(isDark), height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A question patients have already answered: shown, not editable.
  Widget _readOnlyQuestion(int i, _EditQuestion q, bool isDark) {
    final d = q.draft;
    final options = needsOptions(d.typeCode) ? d.cleanOptions : const <String>[];
    final range = d.typeCode == QuestionType.number
        ? [
            if (d.minValue.trim().isNotEmpty) 'from ${d.minValue.trim()}',
            if (d.maxValue.trim().isNotEmpty) 'up to ${d.maxValue.trim()}',
          ].join(' ')
        : '';
    return QCard(
      key: q.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '${i + 1}. ', style: QUi.text(14, FontWeight.w600, QUi.muted(isDark))),
              TextSpan(text: d.text, style: QUi.text(14, FontWeight.w600, QUi.ink(isDark), height: 1.4)),
              if (d.isRequired) TextSpan(text: ' *', style: QUi.text(14, FontWeight.w700, QUi.red)),
            ]),
          ),
          if (d.helpText.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(d.helpText.trim(), style: QUi.text(12.5, FontWeight.w400, QUi.muted(isDark), height: 1.4)),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            QChip(questionTypeLabel(d.typeCode)),
            if (d.isRequired) const QChip('Required'),
            if (range.isNotEmpty) QChip('Allowed $range'),
          ]),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final o in options)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: QUi.text(13, FontWeight.w500, QUi.muted(isDark), height: 1.4)),
                    Expanded(child: Text(o, style: QUi.text(13, FontWeight.w500, QUi.body(isDark), height: 1.4))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller, bool isDark) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(label, isDark),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
            style: _fieldStyle(isDark),
            decoration: _decoration(isDark, 'Any'),
          ),
        ],
      );

  Widget _label(String text, bool isDark, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: text, style: QUi.text(13, FontWeight.w600, QUi.ink(isDark))),
            if (required) TextSpan(text: ' *', style: QUi.text(13, FontWeight.w700, QUi.red)),
          ]),
        ),
      );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged, bool isDark) => Row(
        children: [
          Expanded(child: Text(label, style: QUi.text(13.5, FontWeight.w500, QUi.body(isDark), height: 1.35))),
          const SizedBox(width: 8),
          Switch.adaptive(value: value, activeTrackColor: QUi.blue, activeThumbColor: Colors.white, onChanged: onChanged),
        ],
      );

  Widget _iconButton(IconData icon, String tooltip, VoidCallback? onPressed, bool isDark) => IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        iconSize: 20,
        color: QUi.body(isDark),
        disabledColor: QUi.line(isDark),
        icon: Icon(icon),
      );

  TextStyle _fieldStyle(bool isDark) => QUi.text(14, FontWeight.w500, QUi.ink(isDark));

  InputDecoration _decoration(bool isDark, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: QUi.text(13.5, FontWeight.w400, QUi.muted(isDark)),
        counterText: '',
        filled: true,
        fillColor: QUi.sunken(isDark),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: QUi.line(isDark))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: QUi.line(isDark))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: QUi.blue, width: 1.5)),
      );
}
