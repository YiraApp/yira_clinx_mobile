// Renders the doctor's past-records section in each state. Any layout
// overflow fails the test. Run with DIET_SHOTS=<dir> and --update-goldens to
// also save screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/data_sources/patient_history/past_records_remote_data_source.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_past_records_section.dart';

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();
  for (final style in ['Bold', 'Fill', 'Duotone']) {
    await (FontLoader('Phosphor$style')..addFont(rootBundle.load('assets/fonts/phosphor/Phosphor-$style.ttf'))).load();
  }
}

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

class _Fake implements PastRecordsRemoteDataSource {
  _Fake(this.result);
  final PastRecordsResult result;
  @override
  Future<PastRecordsResult> fetch({required String patientId, String? appointmentId, String? hospitalId}) async => result;
}

PastRecords _sample({bool all = true}) => PastRecords.fromJson({
      'scope': all ? 'all' : 'hospital',
      'appointments': [
        {'date': '2026-09-12', 'reason': 'Follow-up for blood pressure', 'doctor': 'Dr. Asha Rao', 'hospital': 'City Care'},
        {'date': '2026-07-02', 'type': 'Consultation', 'doctor': 'Dr. Vikram Shah', 'hospital': 'Sunrise Clinic'},
      ],
      'medicalRecords': [
        {'date': '2026-09-12', 'diagnosis': 'Essential hypertension', 'doctor': 'Dr. Asha Rao', 'hospital': 'City Care'},
      ],
      'prescriptions': [
        {
          'date': '2026-09-12',
          'doctor': 'Dr. Asha Rao',
          'hospital': 'City Care',
          'diagnoses': ['Hypertension'],
          'medications': [
            {'name': 'Amlodipine 5mg'},
            {'name': 'Telmisartan 40mg'},
            {'name': 'Aspirin 75mg'},
            {'name': 'Atorvastatin 10mg'},
          ],
          'pdfUrl': 'https://example.com/rx.pdf',
        },
      ],
      'documents': [
        {'name': 'Lipid profile.pdf', 'category': 'Lab report', 'date': '2026-09-10', 'url': 'https://example.com/l.pdf', 'hospital': 'City Care'},
      ],
      'medicines': all
          ? [
              {'name': 'Amlodipine', 'dosage': '5mg', 'active': true},
              {'name': 'Paracetamol', 'active': false},
            ]
          : [],
      'vitals': {
        'bloodPressure': {'value': '138/88', 'unit': 'mmHg', 'date': '2026-09-12'},
        'heartRate': {'value': '78', 'unit': 'bpm', 'date': '2026-09-12'},
        'spo2': {'value': '98', 'unit': '%', 'date': '2026-09-12'},
      },
      'fitness': all
          ? [
              {'steps': 6400, 'sleepMinutes': 410, 'restingHeartRate': 64},
              {'steps': 8200, 'sleepMinutes': 450, 'restingHeartRate': 62},
            ]
          : [],
    });

void main() {
  setUpAll(_loadFonts);

  Future<List<String>> pump(WidgetTester tester, PastRecordsResult result, {double width = 390}) async {
    tester.view.physicalSize = Size(width * 3, 1500 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final opened = <String>[];
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PatientPastRecordsSection(
            patientId: 'p',
            appointmentId: '9',
            dataSource: _Fake(result),
            onOpenTab: opened.add,
            onRequestAccess: () => opened.add('request'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return opened;
  }

  for (final width in [390.0, 320.0]) {
    testWidgets('shows past records with access (${width.round()})', (tester) async {
      final opened = await pump(tester, PastRecordsResult.records(_sample()), width: width);
      expect(find.text('All hospitals'), findsOneWidget);
      expect(find.text('Follow-up for blood pressure'), findsOneWidget);
      expect(find.text('Essential hypertension'), findsOneWidget);
      expect(find.text('Amlodipine 5mg, Telmisartan 40mg, Aspirin 75mg +1'), findsOneWidget);
      expect(find.text('Amlodipine 5mg'), findsOneWidget); // active medicine pill
      expect(find.text('Paracetamol'), findsNothing);
      expect(find.text('7,300 steps/day'), findsOneWidget);
      await tester.tap(find.text('View all').first);
      expect(opened, ['Appointments']);
      await tester.pumpAndSettle();
      if (_shotsDir != null) {
        await expectLater(find.byType(PatientPastRecordsSection),
            matchesGoldenFile(Uri.file('$_shotsDir/past_records_${width.round()}.png')));
      }
    });
  }

  testWidgets('hospital-only access offers to ask for the rest', (tester) async {
    final opened = await pump(tester, PastRecordsResult.records(_sample(all: false)));
    expect(find.text('This hospital'), findsOneWidget);
    await tester.tap(find.text('Ask the patient to see records from other hospitals'));
    expect(opened, ['request']);
    await tester.pumpAndSettle();
    if (_shotsDir != null) {
      await expectLater(find.byType(PatientPastRecordsSection), matchesGoldenFile(Uri.file('$_shotsDir/past_records_hospital.png')));
    }
  });

  testWidgets('no access shows a locked card with a request button', (tester) async {
    final opened = await pump(tester, const PastRecordsResult.locked('NO_REQUEST'));
    expect(find.text('Locked'), findsOneWidget);
    await tester.tap(find.text('Ask for access'));
    expect(opened, ['request']);
    await tester.pumpAndSettle();
    if (_shotsDir != null) {
      await expectLater(find.byType(PatientPastRecordsSection), matchesGoldenFile(Uri.file('$_shotsDir/past_records_locked.png')));
    }
  });

  testWidgets('a pending request says so and hides the button', (tester) async {
    await pump(tester, const PastRecordsResult.locked('PENDING'));
    expect(find.textContaining('asked for access'), findsOneWidget);
    expect(find.text('Ask for access'), findsNothing);
  });

  testWidgets('no history yet', (tester) async {
    await pump(tester, PastRecordsResult.records(PastRecords.fromJson({'scope': 'hospital'})));
    expect(find.text('No earlier visits or records yet.'), findsOneWidget);
  });
}
