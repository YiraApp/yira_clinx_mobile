import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/data_sources/questionnaires/questionnaire_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/questionnaires/questionnaire_models.dart';
import 'package:yiraclinics/features/presentation/patient/questionnaires/patient_questionnaires_screen.dart';
import 'package:yiraclinics/features/presentation/patient/questionnaires/questionnaire_fill_screen.dart';

const _pain = QuestionnaireQuestion(
  id: 1,
  text: 'How is your pain?',
  typeCode: QuestionType.singleChoice,
  isRequired: true,
  options: [QuestionOption(id: 10, label: 'None'), QuestionOption(id: 11, label: 'Severe')],
);
const _symptoms = QuestionnaireQuestion(
  id: 2,
  text: 'Symptoms',
  typeCode: QuestionType.multiChoice,
  options: [QuestionOption(id: 20, label: 'Fever'), QuestionOption(id: 21, label: 'Cough')],
);
const _weight = QuestionnaireQuestion(id: 3, text: 'Weight (kg)', typeCode: QuestionType.number, minValue: 20, maxValue: 250);
const _sleep = QuestionnaireQuestion(id: 4, text: 'Rate your sleep', typeCode: QuestionType.rating, isRequired: true);
const _smoke = QuestionnaireQuestion(id: 5, text: 'Do you smoke?', typeCode: QuestionType.yesNo);
const _notes = QuestionnaireQuestion(id: 6, text: 'Anything else?', typeCode: QuestionType.longText);

QuestionnaireSubmission _attempt(int no, Map<int, String> answers) => QuestionnaireSubmission(
      id: no,
      questionnaireId: 1,
      title: 'Intake',
      attemptNo: no,
      answers: [for (final e in answers.entries) SubmittedAnswer(questionId: e.key, questionText: 'Q${e.key}', typeCode: 'X', display: e.value)],
    );

class _FakeSource extends QuestionnaireRemoteDataSource {
  _FakeSource(this.items);
  final List<PatientQuestionnaire> items;
  List<Map<String, dynamic>>? sent;

  @override
  Future<({List<PatientQuestionnaire> items, int dueCount})> list() async =>
      (items: items, dueCount: items.where((q) => q.state == QuestionnaireState.due).length);

  @override
  Future<QuestionnaireSubmission> submit(int id, List<Map<String, dynamic>> answers) async {
    sent = answers;
    return _attempt(1, const {});
  }
}

void main() {
  group('answer checks', () {
    test('required questions need an answer, optional ones do not', () {
      expect(answerProblem(_pain, null), isNotNull);
      expect(answerProblem(_symptoms, null), isNull);
      expect(answerProblem(_symptoms, <int>[]), isNull);
      expect(answerProblem(_pain, 10), isNull);
    });

    test('numbers stay in range and ratings in 1-5', () {
      expect(answerProblem(_weight, 'abc'), 'Enter a number.');
      expect(answerProblem(_weight, '10'), 'Enter 20 or more.');
      expect(answerProblem(_weight, '300'), 'Enter 250 or less.');
      expect(answerProblem(_weight, '72.5'), isNull);
      expect(answerProblem(_sleep, 6), 'Enter 5 or less.');
      expect(answerProblem(_sleep, 3), isNull);
    });

    test('payload leaves out empty answers and sends numbers as numbers', () {
      final payload = answersPayload(
        [_pain, _symptoms, _weight, _sleep, _smoke, _notes],
        {1: 11, 2: <int>[], 3: ' 72.5 ', 4: 4, 5: 'No', 6: '  tight chest  '},
      );
      expect(payload, [
        {'questionId': 1, 'value': 11},
        {'questionId': 3, 'value': 72.5},
        {'questionId': 4, 'value': 4},
        {'questionId': 5, 'value': 'No'},
        {'questionId': 6, 'value': 'tight chest'},
      ]);
    });
  });

  test('answers that changed since the attempt before are found', () {
    final attempts = [
      _attempt(2, {1: 'Mild', 4: '4', 5: 'No'}),
      _attempt(1, {1: 'Severe', 4: '4', 6: 'tight chest'}),
    ];
    expect(changedSincePrevious(attempts, 0), {1, 5, 6});
    expect(changedSincePrevious(attempts, 1), isEmpty);
  });

  testWidgets('list puts questionnaires to fill in first, then done', (tester) async {
    final source = _FakeSource(const [
      PatientQuestionnaire(id: 1, title: 'Day 30 follow-up', state: QuestionnaireState.completed, attempts: 1, history: [QuestionnaireAttempt(id: 9, attemptNo: 1)]),
      PatientQuestionnaire(id: 2, title: 'Intake', state: QuestionnaireState.due, canSubmit: true, questionCount: 6, requested: true),
    ]);
    await tester.pumpWidget(MaterialApp(home: PatientQuestionnairesScreen(dataSource: source)));
    await tester.pumpAndSettle();

    expect(find.text('TO FILL IN  ·  1'), findsOneWidget);
    expect(find.text('DONE  ·  1'), findsOneWidget);
    expect(find.text('Requested by your hospital'), findsOneWidget);
    expect(find.text('Fill in'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Intake')).dy < tester.getTopLeft(find.text('Day 30 follow-up')).dy, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form blocks sending until required questions are answered', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final source = _FakeSource(const []);
    await tester.pumpWidget(MaterialApp(
      home: QuestionnaireFillScreen(
        questionnaireId: 1,
        title: 'Intake',
        dataSource: source,
        initialForm: const QuestionnaireForm(
          info: PatientQuestionnaire(id: 1, title: 'Intake', canSubmit: true, state: QuestionnaireState.due),
          questions: [_pain, _sleep, _smoke],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('0 of 2 required answered'), findsOneWidget);

    await tester.tap(find.text('Send answers'));
    await tester.pumpAndSettle();
    expect(find.text('This question needs an answer.'), findsNWidgets(2));
    expect(source.sent, isNull);

    await tester.tap(find.text('Severe'));
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2 required answered'), findsOneWidget);
    expect(find.text('This question needs an answer.'), findsNothing);

    await tester.tap(find.text('Send answers'));
    await tester.pumpAndSettle();
    expect(find.text('Send your answers?'), findsOneWidget);
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(source.sent, [
      {'questionId': 1, 'value': 11},
      {'questionId': 4, 'value': 4},
    ]);
  });
}
