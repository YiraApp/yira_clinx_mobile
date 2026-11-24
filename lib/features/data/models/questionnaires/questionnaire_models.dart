/// Questionnaires a hospital asks its patients to fill in, and the answers.
library;

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
int _int(dynamic v, [int fallback = 0]) => v is int ? v : int.tryParse('${v ?? ''}') ?? (v is num ? v.toInt() : fallback);
double? _double(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
String? _str(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

List<Map<String, dynamic>> _maps(dynamic v) =>
    (v is List ? v : const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

/// Where a questionnaire stands for the patient.
enum QuestionnaireState { due, available, completed }

QuestionnaireState _state(dynamic v) => switch (v?.toString()) {
      'due' => QuestionnaireState.due,
      'available' => QuestionnaireState.available,
      _ => QuestionnaireState.completed,
    };

/// The input kinds the server knows. Anything else is shown as text.
abstract final class QuestionType {
  static const shortText = 'SHORT_TEXT';
  static const longText = 'LONG_TEXT';
  static const number = 'NUMBER';
  static const singleChoice = 'SINGLE_CHOICE';
  static const multiChoice = 'MULTI_CHOICE';
  static const dropdown = 'DROPDOWN';
  static const yesNo = 'YES_NO';
  static const date = 'DATE';
  static const rating = 'RATING';
}

class QuestionnaireAttempt {
  final int id;
  final int attemptNo;
  final DateTime? submittedAt;

  const QuestionnaireAttempt({required this.id, required this.attemptNo, this.submittedAt});

  factory QuestionnaireAttempt.fromJson(Map<String, dynamic> j) =>
      QuestionnaireAttempt(id: _int(j['id']), attemptNo: _int(j['attemptNo'], 1), submittedAt: _date(j['submittedAt']));
}

class PatientQuestionnaire {
  final int id;
  final String title;
  final String? description;
  final String? categoryName;
  final String? hospitalName;
  final int questionCount;
  final bool allowMultiple;
  final int? repeatAfterDays;
  final int attempts;
  final DateTime? lastSubmittedAt;
  final int? lastSubmissionId;
  final bool requested;
  final DateTime? dueAt;
  /// When the open request was sent, and who sent it when a member of staff sent it to this patient alone.
  final DateTime? requestedAt;
  final String? requestedBy;
  final bool canSubmit;
  final DateTime? nextDueAt;
  final QuestionnaireState state;
  final List<QuestionnaireAttempt> history;

  const PatientQuestionnaire({
    required this.id,
    required this.title,
    this.description,
    this.categoryName,
    this.hospitalName,
    this.questionCount = 0,
    this.allowMultiple = true,
    this.repeatAfterDays,
    this.attempts = 0,
    this.lastSubmittedAt,
    this.lastSubmissionId,
    this.requested = false,
    this.dueAt,
    this.requestedAt,
    this.requestedBy,
    this.canSubmit = false,
    this.nextDueAt,
    this.state = QuestionnaireState.completed,
    this.history = const [],
  });

  factory PatientQuestionnaire.fromJson(Map<String, dynamic> j) => PatientQuestionnaire(
        id: _int(j['id']),
        title: _str(j['title']) ?? 'Questionnaire',
        description: _str(j['description']),
        categoryName: _str(j['categoryName']),
        hospitalName: _str(j['hospitalName']),
        questionCount: _int(j['questionCount']),
        allowMultiple: j['allowMultiple'] != false,
        repeatAfterDays: j['repeatAfterDays'] == null ? null : _int(j['repeatAfterDays']),
        attempts: _int(j['attempts']),
        lastSubmittedAt: _date(j['lastSubmittedAt']),
        lastSubmissionId: j['lastSubmissionId'] == null ? null : _int(j['lastSubmissionId']),
        requested: j['requested'] == true,
        dueAt: _date(j['dueAt']),
        requestedAt: _date(j['requestedAt']),
        requestedBy: _str(j['requestedBy']),
        canSubmit: j['canSubmit'] == true,
        nextDueAt: _date(j['nextDueAt']),
        state: _state(j['state']),
        history: _maps(j['history']).map(QuestionnaireAttempt.fromJson).toList(),
      );
}

class QuestionOption {
  final int id;
  final String label;

  const QuestionOption({required this.id, required this.label});

  factory QuestionOption.fromJson(Map<String, dynamic> j) => QuestionOption(id: _int(j['id']), label: _str(j['label']) ?? '');
}

class QuestionnaireQuestion {
  final int id;
  final String text;
  final String? helpText;
  final String typeCode;
  final bool isRequired;
  final double? minValue;
  final double? maxValue;
  final List<QuestionOption> options;

  const QuestionnaireQuestion({
    required this.id,
    required this.text,
    required this.typeCode,
    this.helpText,
    this.isRequired = false,
    this.minValue,
    this.maxValue,
    this.options = const [],
  });

  factory QuestionnaireQuestion.fromJson(Map<String, dynamic> j) => QuestionnaireQuestion(
        id: _int(j['id']),
        text: _str(j['text']) ?? '',
        helpText: _str(j['helpText']),
        typeCode: _str(j['typeCode']) ?? QuestionType.shortText,
        isRequired: j['isRequired'] == true,
        minValue: _double(j['minValue']),
        maxValue: _double(j['maxValue']),
        options: _maps(j['options']).map(QuestionOption.fromJson).toList(),
      );
}

class QuestionnaireForm {
  final PatientQuestionnaire info;
  final List<QuestionnaireQuestion> questions;

  const QuestionnaireForm({required this.info, required this.questions});

  factory QuestionnaireForm.fromJson(Map<String, dynamic> j) => QuestionnaireForm(
        info: PatientQuestionnaire.fromJson(j),
        questions: _maps(j['questions']).map(QuestionnaireQuestion.fromJson).toList(),
      );
}

class SubmittedAnswer {
  final int questionId;
  final String questionText;
  final String typeCode;
  final String display;

  const SubmittedAnswer({required this.questionId, required this.questionText, required this.typeCode, required this.display});

  factory SubmittedAnswer.fromJson(Map<String, dynamic> j) => SubmittedAnswer(
        questionId: _int(j['questionId']),
        questionText: _str(j['questionText']) ?? '',
        typeCode: _str(j['typeCode']) ?? QuestionType.shortText,
        display: _answerDisplay(_str(j['typeCode']), j['display']?.toString() ?? ''),
      );
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// A date answer reads like the other dates in the app ("1 Oct 2026"), not as stored ("2026-10-01").
String _answerDisplay(String? typeCode, String display) {
  if (typeCode != QuestionType.date) return display;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(display);
  if (m == null) return display;
  final month = int.parse(m.group(2)!);
  if (month < 1 || month > 12) return display;
  return '${int.parse(m.group(3)!)} ${_months[month - 1]} ${m.group(1)}';
}

class QuestionnaireSubmission {
  final int id;
  final int questionnaireId;
  final String title;
  final String? hospitalName;
  final int attemptNo;
  final DateTime? submittedAt;
  final List<SubmittedAnswer> answers;

  const QuestionnaireSubmission({
    required this.id,
    required this.questionnaireId,
    required this.title,
    required this.attemptNo,
    this.hospitalName,
    this.submittedAt,
    this.answers = const [],
  });

  factory QuestionnaireSubmission.fromJson(Map<String, dynamic> j) => QuestionnaireSubmission(
        id: _int(j['id']),
        questionnaireId: _int(j['questionnaireId']),
        title: _str(j['questionnaireTitle']) ?? _str(j['title']) ?? 'Questionnaire',
        hospitalName: _str(j['hospitalName']),
        attemptNo: _int(j['attemptNo'], 1),
        submittedAt: _date(j['submittedAt']),
        answers: _maps(j['answers']).map(SubmittedAnswer.fromJson).toList(),
      );
}

/// One questionnaire a patient answered, with every attempt, for their doctor.
class DoctorQuestionnaireGroup {
  final int questionnaireId;
  final String title;
  final String? categoryName;
  final String? hospitalName;
  final int? repeatAfterDays;
  final List<QuestionnaireSubmission> attempts;

  const DoctorQuestionnaireGroup({
    required this.questionnaireId,
    required this.title,
    this.categoryName,
    this.hospitalName,
    this.repeatAfterDays,
    this.attempts = const [],
  });

  factory DoctorQuestionnaireGroup.fromJson(Map<String, dynamic> j) {
    final title = _str(j['title']) ?? 'Questionnaire';
    final id = _int(j['questionnaireId']);
    return DoctorQuestionnaireGroup(
      questionnaireId: id,
      title: title,
      categoryName: _str(j['categoryName']),
      hospitalName: _str(j['hospitalName']),
      repeatAfterDays: j['repeatAfterDays'] == null ? null : _int(j['repeatAfterDays']),
      attempts: _maps(j['attempts'])
          .map((a) => QuestionnaireSubmission.fromJson({...a, 'questionnaireId': id, 'title': title}))
          .toList(),
    );
  }
}

/// The question ids whose answer differs from the attempt before [index] in
/// [attempts] (newest first). Empty for the first attempt.
Set<int> changedSincePrevious(List<QuestionnaireSubmission> attempts, int index) {
  if (index < 0 || index + 1 >= attempts.length) return const {};
  final now = {for (final a in attempts[index].answers) a.questionId: a.display};
  final before = {for (final a in attempts[index + 1].answers) a.questionId: a.display};
  return {
    for (final id in {...now.keys, ...before.keys})
      if ((now[id] ?? '') != (before[id] ?? '')) id,
  };
}

/// What the patient has entered so far, keyed by question id. Values follow the
/// server's shapes: text, number, option id, option id list, "Yes"/"No", "YYYY-MM-DD".
typedef QuestionnaireAnswers = Map<int, Object?>;

bool isAnswered(Object? value) => switch (value) {
      null => false,
      String s => s.trim().isNotEmpty,
      List l => l.isNotEmpty,
      _ => true,
    };

/// The first problem with [value] for [q], or null when it's fine. Mirrors the server's checks.
String? answerProblem(QuestionnaireQuestion q, Object? value) {
  if (!isAnswered(value)) return q.isRequired ? 'This question needs an answer.' : null;
  switch (q.typeCode) {
    case QuestionType.shortText:
      return value.toString().trim().length > 500 ? 'Keep it under 500 characters.' : null;
    case QuestionType.longText:
      return value.toString().trim().length > 5000 ? 'Keep it under 5000 characters.' : null;
    case QuestionType.number:
    case QuestionType.rating:
      final n = value is num ? value.toDouble() : double.tryParse(value.toString().trim());
      if (n == null) return 'Enter a number.';
      final min = q.typeCode == QuestionType.rating ? 1.0 : q.minValue;
      final max = q.typeCode == QuestionType.rating ? 5.0 : q.maxValue;
      if (min != null && n < min) return 'Enter ${_fmt(min)} or more.';
      if (max != null && n > max) return 'Enter ${_fmt(max)} or less.';
      return null;
    default:
      return null;
  }
}

String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Answers in the shape the submit endpoint takes, leaving out empty ones.
List<Map<String, dynamic>> answersPayload(List<QuestionnaireQuestion> questions, QuestionnaireAnswers answers) => [
      for (final q in questions)
        if (isAnswered(answers[q.id]))
          {
            'questionId': q.id,
            'value': switch (q.typeCode) {
              QuestionType.number || QuestionType.rating => answers[q.id] is num
                  ? answers[q.id]
                  : double.tryParse(answers[q.id].toString().trim()),
              QuestionType.shortText || QuestionType.longText => answers[q.id].toString().trim(),
              _ => answers[q.id],
            },
          },
    ];


/// One of the hospital's published questionnaires as seen for a patient, when a doctor picks one to send.
/// [mine] marks one of the doctor's own questionnaires; the server lists those first.
class SendableQuestionnaire {
  final int id;
  final String title;
  final String? description;
  final bool mine;
  final String? categoryName;
  final int questionCount;
  final String targetGender;
  final bool allowMultiple;
  final int attempts;
  final DateTime? lastSubmittedAt;
  final DateTime? pendingSentAt;
  final DateTime? pendingDueAt;
  final String? pendingSentBy;
  final bool canSend;
  final String? reason;

  const SendableQuestionnaire({
    required this.id,
    required this.title,
    this.description,
    this.mine = false,
    this.categoryName,
    this.questionCount = 0,
    this.targetGender = 'All',
    this.allowMultiple = true,
    this.attempts = 0,
    this.lastSubmittedAt,
    this.pendingSentAt,
    this.pendingDueAt,
    this.pendingSentBy,
    this.canSend = false,
    this.reason,
  });

  bool get pending => pendingSentAt != null;

  factory SendableQuestionnaire.fromJson(Map<String, dynamic> j) {
    final pending = j['pending'] is Map ? Map<String, dynamic>.from(j['pending'] as Map) : const <String, dynamic>{};
    return SendableQuestionnaire(
      id: _int(j['id']),
      title: _str(j['title']) ?? 'Questionnaire',
      description: _str(j['description']),
      mine: j['mine'] == true,
      categoryName: _str(j['categoryName']),
      questionCount: _int(j['questionCount']),
      targetGender: _str(j['targetGender']) ?? 'All',
      allowMultiple: j['allowMultiple'] != false,
      attempts: _int(j['attempts']),
      lastSubmittedAt: _date(j['lastSubmittedAt']),
      pendingSentAt: _date(pending['sentAt']),
      pendingDueAt: _date(pending['dueAt']),
      pendingSentBy: _str(pending['sentBy']),
      canSend: j['canSend'] == true,
      reason: _str(j['reason']),
    );
  }
}

// ── A doctor's own questionnaires ("templates") ─────────────────────────────

/// The answer kinds a doctor can pick for a question, in the editor's order.
const templateQuestionTypes = [
  QuestionType.shortText,
  QuestionType.longText,
  QuestionType.number,
  QuestionType.singleChoice,
  QuestionType.multiChoice,
  QuestionType.dropdown,
  QuestionType.yesNo,
  QuestionType.date,
  QuestionType.rating,
];

/// What the editor calls each answer kind.
String questionTypeLabel(String typeCode) => switch (typeCode) {
      QuestionType.shortText => 'Short answer',
      QuestionType.longText => 'Long answer',
      QuestionType.number => 'Number',
      QuestionType.singleChoice => 'Single choice',
      QuestionType.multiChoice => 'Multiple choice',
      QuestionType.dropdown => 'Dropdown',
      QuestionType.yesNo => 'Yes / No',
      QuestionType.date => 'Date',
      QuestionType.rating => 'Rating 1–5',
      _ => typeCode,
    };

/// True for the answer kinds that need a list of options.
bool needsOptions(String typeCode) =>
    typeCode == QuestionType.singleChoice || typeCode == QuestionType.multiChoice || typeCode == QuestionType.dropdown;

/// The limits the server holds a doctor's questionnaire to.
abstract final class TemplateLimits {
  static const title = 200;
  static const description = 2000;
  static const question = 1000;
  static const helpText = 1000;
  static const option = 500;
  static const options = 50;
  static const questions = 100;
}

/// A whole number goes out as 5, not 5.0.
num _jsonNum(double v) => v == v.roundToDouble() ? v.toInt() : v;

/// A number as typed, or null when empty. NaN when it isn't a number.
double? _typedNumber(String s) {
  final t = s.trim();
  if (t.isEmpty) return null;
  final n = double.tryParse(t);
  return n == null || !n.isFinite ? double.nan : n;
}

/// One question of a doctor's own questionnaire, as written in the editor.
/// [minValue] and [maxValue] are kept as typed (empty for any) and only matter for numbers.
class TemplateQuestionDraft {
  final String text;
  final String typeCode;
  final String helpText;
  final bool isRequired;
  final List<String> options;
  final String minValue;
  final String maxValue;

  const TemplateQuestionDraft({
    required this.text,
    this.typeCode = QuestionType.shortText,
    this.helpText = '',
    this.isRequired = true,
    this.options = const [],
    this.minValue = '',
    this.maxValue = '',
  });

  factory TemplateQuestionDraft.fromJson(Map<String, dynamic> j) {
    final min = _double(j['minValue']);
    final max = _double(j['maxValue']);
    return TemplateQuestionDraft(
      text: j['text']?.toString() ?? '',
      typeCode: _str(j['typeCode'])?.toUpperCase() ?? QuestionType.shortText,
      helpText: j['helpText']?.toString() ?? '',
      isRequired: j['isRequired'] == true || j['isRequired'] == 1,
      options: (j['options'] is List ? j['options'] as List : const [])
          .map((o) => (o is Map ? o['label'] : o)?.toString() ?? '')
          .toList(),
      minValue: min == null ? '' : _fmt(min),
      maxValue: max == null ? '' : _fmt(max),
    );
  }

  /// The options with blanks left out.
  List<String> get cleanOptions => options.map((o) => o.trim()).where((o) => o.isNotEmpty).toList();

  /// The shape the server takes: trimmed, options only for choices, a range only for numbers.
  Map<String, dynamic> toJson() {
    final number = typeCode == QuestionType.number;
    final min = number ? _typedNumber(minValue) : null;
    final max = number ? _typedNumber(maxValue) : null;
    return {
      'text': text.trim(),
      'typeCode': typeCode,
      'helpText': helpText.trim().isEmpty ? null : helpText.trim(),
      'isRequired': isRequired,
      'options': needsOptions(typeCode) ? cleanOptions : <String>[],
      'minValue': min == null || min.isNaN ? null : _jsonNum(min),
      'maxValue': max == null || max.isNaN ? null : _jsonNum(max),
    };
  }
}

/// What the editor saves. [questions] null sends the name and note only, for a
/// questionnaire patients have already answered.
class QuestionnaireTemplateDraft {
  final String title;
  final String description;
  final bool allowMultiple;
  final List<TemplateQuestionDraft>? questions;

  const QuestionnaireTemplateDraft({required this.title, this.description = '', this.allowMultiple = true, this.questions});

  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        'description': description.trim().isEmpty ? null : description.trim(),
        'allowMultiple': allowMultiple,
        if (questions != null) 'questions': [for (final q in questions!) q.toJson()],
      };
}

/// A doctor's own questionnaire as saved. Once a patient has answered it,
/// [questionsLocked] is true and only its name and note can change.
class QuestionnaireTemplateDetail {
  final int id;
  final String title;
  final String? description;
  final bool allowMultiple;
  final int submissionCount;
  final bool questionsLocked;
  final List<TemplateQuestionDraft> questions;

  const QuestionnaireTemplateDetail({
    required this.id,
    required this.title,
    this.description,
    this.allowMultiple = true,
    this.submissionCount = 0,
    this.questionsLocked = false,
    this.questions = const [],
  });

  factory QuestionnaireTemplateDetail.fromJson(Map<String, dynamic> j) => QuestionnaireTemplateDetail(
        id: _int(j['id']),
        title: _str(j['title']) ?? '',
        description: _str(j['description']),
        allowMultiple: j['allowMultiple'] != false,
        submissionCount: _int(j['submissionCount']),
        questionsLocked: j['questionsLocked'] == true,
        questions: _maps(j['questions']).map(TemplateQuestionDraft.fromJson).toList(),
      );
}

/// One of the doctor's own questionnaires in their list.
class QuestionnaireTemplateSummary {
  final int id;
  final String title;
  final String? description;
  final bool allowMultiple;
  final int questionCount;
  final int sentCount;
  final int submissionCount;

  const QuestionnaireTemplateSummary({
    required this.id,
    required this.title,
    this.description,
    this.allowMultiple = true,
    this.questionCount = 0,
    this.sentCount = 0,
    this.submissionCount = 0,
  });

  factory QuestionnaireTemplateSummary.fromJson(Map<String, dynamic> j) => QuestionnaireTemplateSummary(
        id: _int(j['id']),
        title: _str(j['title']) ?? 'Questionnaire',
        description: _str(j['description']),
        allowMultiple: j['allowMultiple'] != false,
        questionCount: _int(j['questionCount']),
        sentCount: _int(j['sentCount']),
        submissionCount: _int(j['submissionCount']),
      );
}

/// The first thing to fix before saving, and the question it's in (from 0), if any.
class TemplateProblem {
  final String message;
  final int? question;

  const TemplateProblem(this.message, {this.question});
}

/// The first thing to fix in a doctor's questionnaire before saving, in the
/// same words as the web, or null when it's ready. The server checks the same.
TemplateProblem? templateProblem(String title, List<TemplateQuestionDraft> questions) {
  if (title.trim().isEmpty) return const TemplateProblem('Give the questionnaire a name.');
  if (questions.isEmpty) return const TemplateProblem('Add at least one question.');
  for (final (i, q) in questions.indexed) {
    final where = 'Question ${i + 1}';
    TemplateProblem at(String message) => TemplateProblem(message, question: i);
    if (q.text.trim().isEmpty) return at('$where has no text.');
    if (needsOptions(q.typeCode)) {
      final options = q.cleanOptions;
      if (options.length < 2) return at('$where needs at least two options.');
      if (options.map((o) => o.toLowerCase()).toSet().length != options.length) return at('$where has the same option twice.');
    }
    if (q.typeCode == QuestionType.number) {
      final min = _typedNumber(q.minValue);
      final max = _typedNumber(q.maxValue);
      if ((min?.isNaN ?? false) || (max?.isNaN ?? false)) {
        return at('$where: the lowest and highest allowed values must be numbers.');
      }
      if (min != null && max != null && min > max) return at("$where: the lowest value can't be more than the highest.");
    }
  }
  return null;
}
