// The doctor's medical record form in the app, laid out like the web: allergies first, then vitals
// and examination, then the clinical history; diagnosis and plan hidden; a preview before saving.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/domain/entities/medicine/medical_history_entity.dart';
import 'package:yiraclinics/features/domain/repositories/medicine/medical_history_repo.dart';
import 'package:yiraclinics/features/presentation/medicine/create_medicine_screen.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_bloc/medical_record_bloc.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/clinical_note_sections.dart';

class _FakeRecords implements MedicalHistoryRepository {
  final created = <Map<String, dynamic>>[];
  final updated = <String, Map<String, dynamic>>{};

  @override
  Future<void> createMedicalRecord(Map<String, dynamic> data) async => created.add(data);
  @override
  Future<void> updateMedicalRecord(String id, Map<String, dynamic> data) async => updated[id] = data;
  @override
  Future<void> deleteMedicalRecord(String id) async {}
  @override
  Future<List<MedicalRecordBriefEntity>> fetchMedicalRecords({String? patientId, String? appointmentId, String? hospitalId, String? orgId}) async => [];
}

final _saved = MedicalRecordBriefEntity(
  id: 'rec-1',
  title: 'Consultation', // a type the visit dropdown doesn't list
  recordDate: DateTime(2026, 11, 11),
  doctorName: 'Dr. Test',
  status: 'Completed',
  chiefComplaint: 'Fever',
  diagnosis: 'Viral fever',
  vitalsSummary: '',
  symptoms: 'Headache',
  physicalExamination: 'No pallor',
  treatmentPlan: 'Rest and fluids',
  bloodPressure: '120/80',
  heartRate: '82',
  temperature: '100.2',
  weight: '70',
  height: '172',
  spo2: '98',
  respiratoryRate: '18',
  allergies: 'Penicillin (rash, itching)',
  historyOfPresentIllness: 'Fever for 3 days',
  familyHistory: 'Diabetes',
  pastHistory: 'Hypertension (HTN)',
  currentMedications: 'Amlodipine 5 mg',
  cvsExamination: 'S1, S2 normal; no murmurs',
  respiratoryExamination: '',
  abdomenExamination: '',
  cnsExamination: '',
);

Future<_FakeRecords> _openForm(WidgetTester tester, {MedicalRecordBriefEntity? record}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repo = _FakeRecords();
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => MedicalRecordBloc(repository: repo),
                child: CreateMedicalRecordScreen(recordToEdit: record, patientId: 'patient-1', appointmentId: '370', hospitalId: '11', orgId: '9'),
              ),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = root == null ? null : File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

// Run with MR_SHOTS=<dir> and --update-goldens to also save screenshots.
final String? _shotsDir = Platform.environment['MR_SHOTS'];

Future<void> _shot(String name) async {
  if (_shotsDir == null) return;
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/$name.png')));
}

void main() {
  setUpAll(_loadFonts);

  test('lists split on commas outside brackets', () {
    expect(splitNoteList('Penicillin (rash, itching), Peanuts ,, Latex'), ['Penicillin (rash, itching)', 'Peanuts', 'Latex']);
    expect(appendNoteTerm('Diabetes', 'diabetes'), 'Diabetes');
    expect(appendNoteTerm('', 'Asthma'), 'Asthma');
  });

  testWidgets('sections come in the web order and diagnosis and plan are not on the form', (tester) async {
    await _openForm(tester, record: _saved);
    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    expect(top('Allergies'), lessThan(top('Clinical Examination')));
    expect(top('Clinical Examination'), lessThan(top('Clinical History & Presentation')));
    expect(find.text('Diagnosis'), findsNothing);
    expect(find.textContaining('Subjective'), findsNothing);
    expect(find.textContaining('Objective'), findsNothing);
    expect(find.text('Preview'), findsOneWidget);
    // The saved allergy shows as one chip, bracket and all; the saved visit type stays selectable.
    expect(find.text('Penicillin (rash, itching)'), findsOneWidget);
    expect(find.text('Consultation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the doctor types any allergy, and "No known allergies" replaces the list', (tester) async {
    await _openForm(tester);
    final input = find.widgetWithText(TextField, 'e.g. Ibuprofen - rash');
    await tester.enterText(input, 'Ibuprofen - swelling');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add'));
    await tester.pump();
    expect(find.text('Ibuprofen - swelling'), findsOneWidget);

    await tester.tap(find.text('+ Peanuts'));
    await tester.pump();
    expect(find.text('Peanuts'), findsOneWidget);

    await tester.tap(find.text('+ No known allergies (NKDA)'));
    await tester.pump();
    expect(find.text('No known allergies (NKDA)'), findsOneWidget);
    expect(find.text('Ibuprofen - swelling'), findsNothing);
    expect(find.text('Peanuts'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Remove No known allergies (NKDA)'));
    await tester.pump();
    expect(find.text('No allergies added yet.'), findsOneWidget);
  });

  testWidgets('a record without a chief complaint is not previewed', (tester) async {
    final repo = await _openForm(tester);
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.text('Chief Complaint is mandatory'), findsOneWidget);
    expect(find.text('Preview medical record'), findsNothing);
    expect(repo.created, isEmpty);
  });

  testWidgets('preview: Edit goes back without saving, Save sends every note field and keeps diagnosis and plan', (tester) async {
    final repo = await _openForm(tester, record: _saved);

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.text('Preview medical record'), findsOneWidget);
    final sheet = find.byType(DraggableScrollableSheet);
    expect(find.descendant(of: sheet, matching: find.text('Penicillin (rash, itching)')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('100.2 °F')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('120/80 mmHg')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('18 /min')), findsWidgets);
    expect(find.descendant(of: sheet, matching: find.text('Family History')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Viral fever')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.descendant(of: sheet, matching: find.text('Edit')));
    await tester.pumpAndSettle();
    expect(find.text('Preview medical record'), findsNothing);
    expect(repo.updated, isEmpty);

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final payload = repo.updated['rec-1']!;
    expect(payload['allergies'], 'Penicillin (rash, itching)');
    expect(payload['respiratoryRate'], '18');
    expect(payload['spo2'], '98');
    expect(payload['historyOfPresentIllness'], 'Fever for 3 days');
    expect(payload['familyHistory'], 'Diabetes');
    expect(payload['pastHistory'], 'Hypertension (HTN)');
    expect(payload['currentMedications'], 'Amlodipine 5 mg');
    expect(payload['physicalExamination'], 'No pallor');
    expect(payload['cvsExamination'], 'S1, S2 normal; no murmurs');
    // Cleared fields are sent empty so the server clears them too.
    expect(payload['respiratoryExamination'], '');
    // Hidden on the form, but an edited record keeps what it had.
    expect(payload['diagnosis'], 'Viral fever');
    expect(payload['treatmentPlan'], 'Rest and fluids');
    expect(payload['type'], 'Consultation');
  });

  testWidgets('"Normal" and "Fill empty as normal" fill the systemic examination', (tester) async {
    await _openForm(tester, record: _saved);
    await tester.ensureVisible(find.text('Fill empty as normal'));
    await tester.tap(find.text('Fill empty as normal'));
    await tester.pump();
    for (final normal in systemicNormal.values) {
      expect(find.widgetWithText(TextField, normal), findsOneWidget);
    }
  });

  testWidgets('screenshots of the form and the preview', (tester) async {
    if (_shotsDir == null) return;
    await _openForm(tester, record: _saved);
    tester.view.physicalSize = const Size(390 * 3, 2900 * 3);
    await tester.pumpAndSettle();
    await _shot('record_form_full');
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    await _shot('record_preview');
  });
}
