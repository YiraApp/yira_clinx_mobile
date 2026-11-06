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
        display: j['display']?.toString() ?? '',
      );
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
class SendableQuestionnaire {
  final int id;
  final String title;
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
