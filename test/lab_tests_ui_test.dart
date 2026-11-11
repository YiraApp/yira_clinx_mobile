// Renders the lab test picker, the prescribing form's lab section, and every
// place a prescription shows its tests, in light and dark at phone sizes. Any
// layout overflow fails the test. Run with DIET_SHOTS=<dir> and --update-goldens
// to also save screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/services/medication_reminder_service.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/data/data_sources/patient_history/past_records_remote_data_source.dart';
import 'package:yiraclinics/features/domain/entities/medication/medication_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/lab_test_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_item.dart';
import 'package:yiraclinics/features/domain/repositories/medication/medication_repository.dart';
import 'package:yiraclinics/features/domain/repositories/prescritpions/prescriptions_repo.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/prescription_history_tab.dart';
import 'package:yiraclinics/features/presentation/prescriptions/add_prescription_screen.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_view_details_screen.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/lab_test_picker_sheet.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/lab_tests_section.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/single_prescription_card.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart' as patient;
import 'package:yiraclinics/features/presentation/user_prescription/prescription_details_screen.dart';
import 'package:yiraclinics/features/presentation/user_prescription/widgets/prescription_card.dart';
import 'package:yiraclinics/features/use_cases/ge_prescription_use_case.dart';
import 'package:yiraclinics/features/use_cases/get_hospital_lab_tests_use_case.dart';
import 'package:yiraclinics/features/use_cases/save_prescription_use_case.dart';

const _catalog = [
  HospitalLabTest(id: 1, testName: 'Complete Blood Count (CBC)', testCode: 'CBC', category: 'Haematology', sampleType: 'Blood'),
  HospitalLabTest(id: 2, testName: 'Fasting Blood Sugar', testCode: 'FBS', category: 'Biochemistry', sampleType: 'Blood', preparation: 'Fast for 8 to 10 hours before the sample. Water is allowed.'),
  HospitalLabTest(id: 3, testName: 'Lipid Profile', testCode: 'LIPID', category: 'Biochemistry', sampleType: 'Blood', preparation: 'Fast for 12 hours.'),
  HospitalLabTest(id: 4, testName: 'Urine Routine and Microscopy', testCode: 'URM', category: 'Clinical Pathology', sampleType: 'Urine', preparation: 'Mid-stream morning sample.'),
  HospitalLabTest(id: 5, testName: 'Thyroid Stimulating Hormone with a very long descriptive name for wrapping at small widths', testCode: 'TSH', category: 'Immunology and Endocrinology', sampleType: 'Serum'),
  HospitalLabTest(id: 6, testName: 'X-Ray Chest PA View', testCode: 'CXR', category: 'Radiology'),
];

const _ordered = [
  PrescribedLabTest(hospitalLabTestId: 1, testName: 'Complete Blood Count (CBC)', category: 'Haematology'),
  PrescribedLabTest(hospitalLabTestId: 2, testName: 'Fasting Blood Sugar', category: 'Biochemistry', priority: PrescribedLabTest.urgent, instructions: 'Collect before the first dose tomorrow morning'),
  PrescribedLabTest(testName: 'Serum Vitamin D, a test the doctor typed with a rather long name', priority: PrescribedLabTest.urgent),
  PrescribedLabTest(hospitalLabTestId: 3, testName: 'Lipid Profile', category: 'Biochemistry'),
];

class _Repo implements PrescriptionRepository {
  PrescriptionEntity existing = const PrescriptionEntity(patientId: '', diagnoses: [], medications: [], additionalNotes: '');
  PrescriptionEntity? saved;

  @override
  Future<PrescriptionEntity> getPrescriptionByPatientId(String patientId, {String? appointmentId, String? hospitalId, String? orgId}) async => existing;

  @override
  Future<PrescriptionEntity> savePrescription(PrescriptionEntity prescription) async {
    saved = prescription;
    return prescription.copyWith(pdfUrl: 'https://example.com/rx.pdf');
  }

  @override
  Future<List<HospitalLabTest>> getHospitalLabTests(String hospitalId) async => _catalog;
}

class _NoMedRepo implements MedicationRepository {
  @override
  Future<MedicationEntity> getMedicationSummary() async =>
      MedicationEntity(totalPrescriptions: 0, activeMeds: 0, totalMedications: 0, needRefill: 0);
}

class _PresetBloc extends patient.MedicationBloc {
  _PresetBloc() : super(getMedicationSummary: GetPrescriptionUseCase(_NoMedRepo())) {
    emit(const patient.MedicationState(status: patient.MedicationStatus.success));
  }
}

class _History extends PastRecordsRemoteDataSource {
  @override
  Future<PastRecordsResult> fetch({required String patientId, String? appointmentId, String? hospitalId}) async {
    return PastRecordsResult.records(PastRecords.fromJson({
      'prescriptions': [
        {
          'date': '2026-09-12',
          'doctor': 'Dr. Asha Rao',
          'hospital': 'City Care',
          'diagnoses': ['Hypertension'],
          'medications': [
            {'name': 'Amlodipine 5mg', 'dosage': '1 tablet', 'frequency': 'Once daily'},
          ],
          'labTests': [
            {'testName': 'Lipid Profile', 'category': 'Biochemistry', 'priority': 'Routine'},
            {'testName': 'Fasting Blood Sugar', 'category': 'Biochemistry', 'priority': 'Urgent', 'instructions': 'Before breakfast'},
          ],
        },
      ],
    }));
  }
}

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();
  for (final style in ['Bold', 'Fill', 'Duotone']) {
    await (FontLoader('Phosphor$style')..addFont(rootBundle.load('assets/fonts/phosphor/Phosphor-$style.ttf'))).load();
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = root == null ? null : File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)))).load();
  }
}

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

Future<void> _shot(WidgetTester tester, String name) async {
  if (_shotsDir == null) return;
  await expectLater(find.byType(MaterialApp).first, matchesGoldenFile(Uri.file('$_shotsDir/$name.png')));
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

MaterialApp _app(bool dark, Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins', brightness: dark ? Brightness.dark : Brightness.light),
      home: home,
    );

Widget _picker(
  void Function(List<PrescribedLabTest>?) onResult, {
  LabCatalogStatus status = LabCatalogStatus.success,
  List<HospitalLabTest> tests = _catalog,
  List<PrescribedLabTest> selected = const [],
  VoidCallback? onRetry,
}) {
  return Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () async {
            final result = await showModalBottomSheet<List<PrescribedLabTest>>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => LabTestPickerSheet(status: status, tests: tests, selected: selected, onRetry: onRetry),
            );
            onResult(result);
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  final sizes = {'393x852': const Size(393, 852), '320x640': const Size(320, 640)};

  for (final entry in sizes.entries) {
    for (final dark in [false, true]) {
      final tag = '${entry.key}_${dark ? 'dark' : 'light'}';

      testWidgets('picker renders the hospital\'s tests ($tag)', (tester) async {
        _size(tester, entry.value);
        await tester.pumpWidget(_app(dark, _picker((_) {}, selected: _ordered.take(1).toList())));
        await _open(tester);
        expect(find.text('Haematology · Blood'), findsOneWidget);
        expect(find.text('Fast for 12 hours.'), findsOneWidget);
        expect(find.text('1 selected'), findsOneWidget);
        await _shot(tester, 'picker_$tag');
      });

      testWidgets('prescribing form lab section renders ($tag)', (tester) async {
        _size(tester, entry.value);
        await tester.pumpWidget(_app(
          dark,
          Scaffold(
            backgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: LabTestsSection(
                  tests: _ordered,
                  onAdd: () {},
                  onRemove: (_) {},
                  onPriorityChanged: (_, _) {},
                  onInstructionsChanged: (_, _) {},
                ),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(find.text('4 Tests'), findsOneWidget);
        await _shot(tester, 'section_$tag');
      });

      testWidgets('doctor list card shows tests ($tag)', (tester) async {
        _size(tester, entry.value);
        await tester.pumpWidget(_app(
          dark,
          Scaffold(
            body: ListView(
              children: [
                SinglePrescriptionCard(
                  isTab: false,
                  date: 'Today • Clinical Consultation',
                  medications: const [MedicationItem(id: '1', name: 'Dolo 650', dosage: '1 tablet', frequency: 'Twice daily')],
                  labTests: _ordered,
                  onView: () {},
                  onEdit: () {},
                  onDelete: () {},
                ),
                SinglePrescriptionCard(isTab: false, date: 'Lab tests only', medications: const [], labTests: _ordered.take(1).toList(), onView: () {}),
              ],
            ),
          ),
        ));
        await tester.pump();
        expect(find.text('4 Lab Tests'), findsOneWidget);
        expect(find.text('+ 1 more test'), findsOneWidget);
        expect(find.text('0 Medicines'), findsNothing);
        await _shot(tester, 'doctor_card_$tag');
      });

      testWidgets('doctor details screen shows tests, lab tests only ($tag)', (tester) async {
        _size(tester, entry.value);
        final repo = _Repo()
          ..existing = const PrescriptionEntity(id: 'rx', patientId: 'p1', diagnoses: [], medications: [], additionalNotes: 'Review with reports.', labTests: _ordered);
        await sl.reset();
        sl.registerFactory<PrescriptionBloc>(() => PrescriptionBloc(savePrescriptionUseCase: SavePrescriptionUseCase(repo)));
        await tester.pumpWidget(_app(dark, const PrescriptionViewDetailsScreen(patientId: 'p1')));
        await tester.pump();
        await tester.pump();
        expect(find.text('Lab Tests'), findsOneWidget);
        expect(find.text('No medications mapped.'), findsNothing);
        expect(find.text('Prescribed Medications'), findsNothing);
        await _shot(tester, 'doctor_details_$tag');
      });

      testWidgets('history tab shows tests ($tag)', (tester) async {
        _size(tester, entry.value);
        await tester.pumpWidget(_app(dark, Scaffold(body: PrescriptionHistoryTab(patientId: 'p1', dataSource: _History()))));
        await tester.pump();
        await tester.pump();
        expect(find.text('Lab Tests'), findsOneWidget);
        expect(find.text('Urgent'), findsOneWidget);
        await _shot(tester, 'history_$tag');
      });

      testWidgets('patient card shows tests ($tag)', (tester) async {
        _size(tester, entry.value);
        await tester.pumpWidget(_app(
          dark,
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PrescriptionCard(
                  id: '1',
                  title: 'Prescription',
                  condition: 'Viral fever',
                  doctor: 'Dr. Teja Chennu - General Physician',
                  specialty: 'General Physician',
                  date: '2026-10-30',
                  status: 'Active',
                  pharmacy: 'Yira',
                  medications: const [
                    {'name': 'Dolo 650', 'dosage': '1 tablet - Twice daily', 'frequency': 'Twice daily', 'duration': '5 Days'},
                  ],
                  labTests: _ordered,
                ),
                PrescriptionCard(
                  id: '2',
                  title: 'Prescription',
                  condition: 'Annual check-up',
                  doctor: 'Dr. Asha Rao',
                  specialty: 'Endocrinologist',
                  date: '2026-10-12',
                  status: 'Active',
                  pharmacy: 'Yira',
                  medications: const [],
                  labTests: _ordered.take(2).toList(),
                ),
              ],
            ),
          ),
        ));
        await tester.pump();
        expect(find.text('LAB TESTS · 4'), findsOneWidget);
        expect(find.text('+ 1 more test'), findsOneWidget);
        expect(find.text('No medicines listed'), findsNothing);
        await _shot(tester, 'patient_card_$tag');
      });

      for (final labOnly in [false, true]) {
        testWidgets('patient details screen shows tests (${labOnly ? 'lab only' : 'with medicines'}, $tag)', (tester) async {
          SharedPreferences.setMockInitialValues({});
          MedicationReminderService.instance.remindersNotifier.value = const [];
          _size(tester, entry.value);
          await tester.pumpWidget(_app(
            dark,
            PrescriptionDetailScreen(
              prescriptionId: '1',
              initialData: {
                'id': '1',
                'condition': 'Viral fever',
                'doctor': 'Dr. Teja Chennu - General Physician',
                'specialty': 'General Physician',
                'date': '2026-10-30',
                'notes': 'Review with reports.',
                'pdfUrl': '',
                'medications': labOnly
                    ? const <Map<String, dynamic>>[]
                    : const [
                        {'name': 'Dolo 650', 'dosage': '1 tablet - Twice daily', 'frequency': 'Twice daily', 'instructions': 'After food', 'duration': '5 Days'},
                      ],
                'labTests': _ordered,
              },
              bloc: _PresetBloc(),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('LAB TESTS · 4'), findsOneWidget);
          expect(find.textContaining('MEDICINES'), labOnly ? findsNothing : findsOneWidget);
          expect(find.text('No medicines are listed on this prescription.'), findsNothing);
          await _shot(tester, 'patient_details_${labOnly ? 'labonly_' : ''}$tag');
        });
      }
    }

    testWidgets('picker fits with the keyboard open (${entry.key})', (tester) async {
      _size(tester, entry.value);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280 * 3);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(_app(false, _picker((_) {})));
      await _open(tester);
      await tester.enterText(find.byType(TextField), 'blood');
      await tester.pumpAndSettle();
      expect(find.text('Complete Blood Count (CBC)'), findsOneWidget);
      await _shot(tester, 'picker_keyboard_${entry.key}');
    });

    testWidgets('picker failure state renders (${entry.key})', (tester) async {
      _size(tester, entry.value);
      var retried = 0;
      await tester.pumpWidget(_app(false, _picker((_) {}, status: LabCatalogStatus.failure, tests: const [], onRetry: () => retried++)));
      await _open(tester);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
      await _shot(tester, 'picker_failure_${entry.key}');
    });

    testWidgets('picker empty state renders (${entry.key})', (tester) async {
      _size(tester, entry.value);
      await tester.pumpWidget(_app(true, _picker((_) {}, tests: const [])));
      await _open(tester);
      expect(find.text('No tests listed yet.'), findsOneWidget);
    });
  }

  testWidgets('picker filters by search and category and returns several tests', (tester) async {
    _size(tester, sizes['393x852']!);
    List<PrescribedLabTest>? result;
    await tester.pumpWidget(_app(false, _picker((r) => result = r)));
    await _open(tester);

    await tester.tap(find.text('Biochemistry').first);
    await tester.pumpAndSettle();
    expect(find.text('Complete Blood Count (CBC)'), findsNothing);
    await tester.tap(find.text('Lipid Profile'));
    await tester.pump();

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'cbc');
    await tester.pump();
    expect(find.text('Lipid Profile'), findsNothing);
    await tester.tap(find.text('Complete Blood Count (CBC)'));
    await tester.pump();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result!.map((t) => t.hospitalLabTestId), [3, 1]);
    expect(result!.first.category, 'Biochemistry');
  });

  testWidgets('a typed test has no list id, and a listed name is not typed twice', (tester) async {
    _size(tester, sizes['393x852']!);
    List<PrescribedLabTest>? result;
    await tester.pumpWidget(_app(false, _picker((r) => result = r)));
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'lipid profile');
    await tester.pump();
    expect(find.textContaining('as a typed test'), findsNothing);

    await tester.enterText(find.byType(TextField), '  Serum Ferritin ');
    await tester.pump();
    await tester.tap(find.text('Add "Serum Ferritin" as a typed test'));
    await tester.pump();
    expect(find.text('Serum Ferritin'), findsOneWidget);
    expect(find.text('Typed test'), findsOneWidget);
    await _shot(tester, 'picker_typed_393x852');

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result!.single.testName, 'Serum Ferritin');
    expect(result!.single.hospitalLabTestId, isNull);
  });

  testWidgets('unticking keeps other tests\' priority, and closing changes nothing', (tester) async {
    _size(tester, sizes['393x852']!);
    List<PrescribedLabTest>? result = const [];
    await tester.pumpWidget(_app(false, _picker((r) => result = r, selected: _ordered)));
    await _open(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(result, isNull);

    await _open(tester);
    await tester.tap(find.text('Complete Blood Count (CBC)'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result!.map((t) => t.testName), isNot(contains('Complete Blood Count (CBC)')));
    expect(result!.firstWhere((t) => t.hospitalLabTestId == 2).isUrgent, isTrue);
    expect(result!.firstWhere((t) => t.hospitalLabTestId == 2).instructions, isNotEmpty);
    expect(result!.any((t) => t.hospitalLabTestId == null), isTrue);
  });

  testWidgets('section reports removal, priority and instructions', (tester) async {
    _size(tester, sizes['393x852']!);
    PrescribedLabTest? removed;
    String? priority;
    String? instructions;
    await tester.pumpWidget(_app(
      false,
      Scaffold(
        body: SingleChildScrollView(
          child: LabTestsSection(
            tests: _ordered.take(1).toList(),
            onAdd: () {},
            onRemove: (t) => removed = t,
            onPriorityChanged: (_, p) => priority = p,
            onInstructionsChanged: (_, text) => instructions = text,
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Urgent'));
    await tester.enterText(find.byType(TextField), 'Morning sample');
    await tester.tap(find.byTooltip('Remove Complete Blood Count (CBC)'));
    expect(priority, PrescribedLabTest.urgent);
    expect(instructions, 'Morning sample');
    expect(removed, _ordered.first);
  });

  Future<_Repo> openForm(WidgetTester tester, Size size, {bool dark = false, PrescriptionEntity? existing}) async {
    _size(tester, size);
    final repo = _Repo();
    if (existing != null) repo.existing = existing;
    await sl.reset();
    sl.registerFactory<PrescriptionBloc>(() => PrescriptionBloc(
          savePrescriptionUseCase: SavePrescriptionUseCase(repo),
          getHospitalLabTestsUseCase: GetHospitalLabTestsUseCase(repo),
        ));
    await tester.pumpWidget(_app(dark, const AddPrescriptionRecordScreen(patientId: 'p1', hospitalId: '19')));
    await tester.pump();
    await tester.pump();
    return repo;
  }

  Future<void> scrollToLabs(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Add Lab Test'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump();
  }

  testWidgets('a prescription of only lab tests can be issued from the form', (tester) async {
    final repo = await openForm(tester, sizes['393x852']!);
    await scrollToLabs(tester);
    await tester.tap(find.text('Add Lab Test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lipid Profile'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Urgent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urgent'));
    await tester.pump();

    await tester.tap(find.text('Issue Prescription'));
    await tester.pump();
    await tester.pump();

    expect(repo.saved, isNotNull);
    expect(repo.saved!.medications, isEmpty);
    final test = repo.saved!.labTests!.single;
    expect(test.hospitalLabTestId, 3);
    expect(test.isUrgent, isTrue);
  });

  testWidgets('the form refuses to issue nothing', (tester) async {
    final repo = await openForm(tester, sizes['393x852']!);
    await tester.tap(find.text('Issue Prescription'));
    await tester.pump();
    expect(find.text('Please add at least one medication or lab test.'), findsOneWidget);
    expect(repo.saved, isNull);
  });

  for (final entry in sizes.entries) {
    for (final dark in [false, true]) {
      testWidgets('editing loads existing tests, and removing them all saves an empty list (${entry.key}, dark $dark)', (tester) async {
        final repo = await openForm(
          tester,
          entry.value,
          dark: dark,
          existing: const PrescriptionEntity(
            id: 'rx1',
            patientId: 'p1',
            diagnoses: [],
            medications: [MedicationItem(id: 'm1', name: 'Dolo 650', dosage: '650mg', frequency: 'Twice daily', duration: '5 Days', route: 'Oral')],
            additionalNotes: '',
            labTests: [PrescribedLabTest(hospitalLabTestId: 3, testName: 'Lipid Profile', category: 'Biochemistry', priority: PrescribedLabTest.urgent, instructions: 'Fasting')],
          ),
        );
        await scrollToLabs(tester);
        expect(find.text('Lipid Profile'), findsOneWidget);
        expect(find.text('Fasting'), findsOneWidget);
        await _shot(tester, 'form_${entry.key}_${dark ? 'dark' : 'light'}');

        final remove = find.byTooltip('Remove Lipid Profile');
        await tester.ensureVisible(remove);
        await tester.pumpAndSettle();
        await tester.tap(remove);
        await tester.pump();
        await tester.tap(find.text('Issue Prescription'));
        await tester.pump();
        await tester.pump();
        expect(repo.saved!.id, 'rx1');
        expect(repo.saved!.labTests, isEmpty);
        expect(repo.saved!.medications.single.name, 'Dolo 650');
      });
    }
  }
}
