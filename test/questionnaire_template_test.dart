import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/data_sources/questionnaires/questionnaire_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/questionnaires/questionnaire_models.dart';
import 'package:yiraclinics/features/presentation/doctor/questionnaires/questionnaire_template_editor_screen.dart';
import 'package:yiraclinics/features/presentation/doctor/questionnaires/send_questionnaire_sheet.dart';

class _FakeTemplates extends QuestionnaireRemoteDataSource {
  _FakeTemplates({this.items = const [], this.template});

  List<SendableQuestionnaire> items;
  QuestionnaireTemplateDetail? template;
  Map<String, dynamic>? created;
  Map<String, dynamic>? updated;
  int? removed;

  @override
  Future<List<SendableQuestionnaire>> sendable(String patientId, {required String hospitalId}) async => items;

  @override
  Future<QuestionnaireTemplateDetail> getTemplate(int id, {required String hospitalId}) async => template!;

  @override
  Future<QuestionnaireTemplateDetail> createTemplate(QuestionnaireTemplateDraft draft, {required String hospitalId}) async {
    created = draft.toJson();
    return QuestionnaireTemplateDetail(id: 42, title: draft.title);
  }

  @override
  Future<QuestionnaireTemplateDetail> updateTemplate(int id, QuestionnaireTemplateDraft draft, {required String hospitalId}) async {
    updated = draft.toJson();
    return QuestionnaireTemplateDetail(id: id, title: draft.title);
  }

  @override
  Future<bool> removeTemplate(int id, {required String hospitalId}) async {
    removed = id;
    items = items.where((q) => q.id != id).toList();
    return false;
  }
}

/// A 360 x 800 phone.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('template checks', () {
    const choice = TemplateQuestionDraft(text: 'Pain?', typeCode: QuestionType.singleChoice, options: ['Mild', ' ']);

    test('the same messages as the web', () {
      expect(templateProblem(' ', const [TemplateQuestionDraft(text: 'Q')])?.message, 'Give the questionnaire a name.');
      expect(templateProblem('Knee', const [])?.message, 'Add at least one question.');
      expect(templateProblem('Knee', const [TemplateQuestionDraft(text: 'Q'), TemplateQuestionDraft(text: ' ')])?.message, 'Question 2 has no text.');
      final one = templateProblem('Knee', const [choice]);
      expect(one?.message, 'Question 1 needs at least two options.');
      expect(one?.question, 0);
      expect(
        templateProblem('Knee', const [TemplateQuestionDraft(text: 'Q', typeCode: QuestionType.dropdown, options: ['Yes', 'yes '])])?.message,
        'Question 1 has the same option twice.',
      );
      expect(
        templateProblem('Knee', const [TemplateQuestionDraft(text: 'Q', typeCode: QuestionType.number, minValue: '-')])?.message,
        'Question 1: the lowest and highest allowed values must be numbers.',
      );
      expect(
        templateProblem('Knee', const [TemplateQuestionDraft(text: 'Q', typeCode: QuestionType.number, minValue: '10', maxValue: '5')])?.message,
        "Question 1: the lowest value can't be more than the highest.",
      );
      expect(templateProblem('Knee', const [TemplateQuestionDraft(text: 'Q', typeCode: QuestionType.rating)]), isNull);
    });

    test('payload is trimmed, with options only for choices and a range only for numbers', () {
      const draft = QuestionnaireTemplateDraft(
        title: ' Knee follow-up ',
        description: '  ',
        allowMultiple: false,
        questions: [
          TemplateQuestionDraft(text: ' Pain? ', typeCode: QuestionType.multiChoice, options: [' Mild ', '', 'Severe'], helpText: ' '),
          TemplateQuestionDraft(text: 'Weight', typeCode: QuestionType.number, minValue: '20', maxValue: '72.5', options: ['x']),
          TemplateQuestionDraft(text: 'Notes', isRequired: false, minValue: '3'),
        ],
      );
      expect(draft.toJson(), {
        'title': 'Knee follow-up',
        'description': null,
        'allowMultiple': false,
        'questions': [
          {'text': 'Pain?', 'typeCode': 'MULTI_CHOICE', 'helpText': null, 'isRequired': true, 'options': ['Mild', 'Severe'], 'minValue': null, 'maxValue': null},
          {'text': 'Weight', 'typeCode': 'NUMBER', 'helpText': null, 'isRequired': true, 'options': <String>[], 'minValue': 20, 'maxValue': 72.5},
          {'text': 'Notes', 'typeCode': 'SHORT_TEXT', 'helpText': null, 'isRequired': false, 'options': <String>[], 'minValue': null, 'maxValue': null},
        ],
      });
      expect(const QuestionnaireTemplateDraft(title: 'A').toJson().containsKey('questions'), isFalse);
    });

    test('reads the saved template and the "mine" mark', () {
      final t = QuestionnaireTemplateDetail.fromJson({
        'id': 7,
        'title': 'Knee',
        'description': null,
        'allowMultiple': true,
        'submissionCount': 2,
        'questionsLocked': true,
        'questions': [
          {'text': 'Weight', 'typeCode': 'NUMBER', 'helpText': null, 'isRequired': true, 'options': [], 'minValue': 20, 'maxValue': 250.5},
        ],
      });
      expect(t.questionsLocked, isTrue);
      expect(t.questions.single.minValue, '20');
      expect(t.questions.single.maxValue, '250.5');
      final q = SendableQuestionnaire.fromJson({'id': 7, 'title': 'Knee', 'description': 'After surgery', 'mine': true, 'canSend': true});
      expect(q.mine, isTrue);
      expect(q.description, 'After surgery');
      expect(SendableQuestionnaire.fromJson({'id': 8, 'title': 'Intake'}).mine, isFalse);
    });
  });

  testWidgets('editor blocks a choice question with one option, then saves', (tester) async {
    _phone(tester);
    final source = _FakeTemplates();
    int? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await QuestionnaireTemplateEditorScreen.open(context, hospitalId: '5', dataSource: source),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('New questionnaire'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'e.g. Knee pain follow-up'), 'Knee follow-up');
    await tester.enterText(find.widgetWithText(TextField, 'Type the question'), 'How bad is the pain?');
    await tester.ensureVisible(find.text('Short answer'));
    await tester.tap(find.text('Short answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Single choice').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Option 1'), 'Mild');

    await tester.tap(find.text('Save questionnaire'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 needs at least two options.'), findsOneWidget);
    expect(source.created, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Option 2'), 'Severe');
    await tester.pumpAndSettle();
    expect(find.text('Question 1 needs at least two options.'), findsNothing);
    await tester.tap(find.text('Save questionnaire'));
    await tester.pumpAndSettle();

    expect(source.created, {
      'title': 'Knee follow-up',
      'description': null,
      'allowMultiple': true,
      'questions': [
        {'text': 'How bad is the pain?', 'typeCode': 'SINGLE_CHOICE', 'helpText': null, 'isRequired': true, 'options': ['Mild', 'Severe'], 'minValue': null, 'maxValue': null},
      ],
    });
    expect(result, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a questionnaire patients answered keeps its questions and saves the name only', (tester) async {
    _phone(tester);
    final source = _FakeTemplates(
      template: const QuestionnaireTemplateDetail(
        id: 7,
        title: 'Knee follow-up',
        questionsLocked: true,
        submissionCount: 3,
        questions: [TemplateQuestionDraft(text: 'How bad is the pain?', typeCode: QuestionType.rating)],
      ),
    );
    await tester.pumpWidget(MaterialApp(home: QuestionnaireTemplateEditorScreen(hospitalId: '5', templateId: 7, dataSource: source)));
    await tester.pumpAndSettle();

    expect(find.textContaining("its questions can't change"), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Type the question'), findsNothing);
    expect(find.text('Rating 1–5'), findsOneWidget);
    expect(find.text('Add question'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Knee follow-up'), 'Knee check');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(source.updated, {'title': 'Knee check', 'description': null, 'allowMultiple': true});
  });

  testWidgets('send sheet groups the doctor\'s own questionnaires and removes one after asking', (tester) async {
    _phone(tester);
    final source = _FakeTemplates(items: const [
      SendableQuestionnaire(id: 7, title: 'Knee follow-up', mine: true, questionCount: 3, canSend: true),
      SendableQuestionnaire(id: 2, title: 'Intake', questionCount: 6, canSend: true),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SendQuestionnaireSheet(patientId: 'p1', hospitalId: '5', dataSource: source),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Create questionnaire'), findsOneWidget);
    expect(find.text('YOUR QUESTIONNAIRES  ·  1'), findsOneWidget);
    expect(find.text('HOSPITAL QUESTIONNAIRES  ·  1'), findsOneWidget);
    expect(find.text('Yours'), findsOneWidget);
    expect(find.text('Send "Knee follow-up"'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this questionnaire?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(source.removed, 7);
    expect(find.text('YOUR QUESTIONNAIRES  ·  1'), findsNothing);
    expect(find.text('Send "Intake"'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor renders every kind of question (dark, phone)', (tester) async {
    _phone(tester);
    final source = _FakeTemplates(
      template: QuestionnaireTemplateDetail(
        id: 7,
        title: 'A long questionnaire name that has to wrap onto a second line on a small phone',
        description: 'After knee surgery',
        questions: [
          for (final code in templateQuestionTypes)
            TemplateQuestionDraft(text: 'A question of type $code that is long enough to wrap', typeCode: code, options: const ['Mild', 'Severe'], minValue: '1', maxValue: '10'),
        ],
      ),
    );
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: QuestionnaireTemplateEditorScreen(hospitalId: '5', templateId: 7, dataSource: source),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Edit questionnaire'), findsOneWidget);
    expect(find.text('9 of 100'), findsOneWidget);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Add question'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('send sheet with nothing to send offers to create one', (tester) async {
    _phone(tester);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SendQuestionnaireSheet(patientId: 'p1', hospitalId: '5', dataSource: _FakeTemplates()),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No questionnaires yet'), findsOneWidget);
    expect(find.text('Create questionnaire'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
