// Renders the patient prescriptions screen with sample data at phone sizes.
// Any layout overflow fails the test. Run with DIET_SHOTS=<dir> and
// --update-goldens to also save screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/services/medication_reminder_service.dart';
import 'package:yiraclinics/features/data/models/medication/medication_reminder_model.dart';
import 'package:yiraclinics/features/domain/entities/medication/medication_entity.dart';
import 'package:yiraclinics/features/domain/repositories/medication/medication_repository.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_screen.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_details_screen.dart';
import 'package:yiraclinics/features/presentation/medication_popup/medication_popup_overlay.dart';
import 'package:yiraclinics/core/services/medication_popup_service.dart';
import 'package:yiraclinics/features/use_cases/ge_prescription_use_case.dart';

class _NoRepo implements MedicationRepository {
  @override
  Future<MedicationEntity> getMedicationSummary() async =>
      MedicationEntity(totalPrescriptions: 0, activeMeds: 0, totalMedications: 0, needRefill: 0);
}

class _PresetBloc extends MedicationBloc {
  _PresetBloc(MedicationState preset) : super(getMedicationSummary: GetPrescriptionUseCase(_NoRepo())) {
    emit(preset);
  }
}

Map<String, dynamic> _prescription(String id, String doctor, String specialty, String date, String condition, List<String> meds) {
  return {
    'id': id,
    'title': 'Prescription for $condition',
    'condition': condition,
    'doctor': '$doctor - $specialty',
    'specialty': specialty,
    'doctorPhoto': '',
    'date': date,
    'status': 'Active',
    'pharmacy': 'Yira Clinx E-Pharmacy',
    'medications': [for (final m in meds) {'name': m, 'dosage': '1 tablet - Twice daily', 'duration': '5 Days'}],
    'pdfUrl': id == '1' ? '/v1/api/auth/prescriptions/1/pdf' : '',
  };
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

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

void main() {
  setUpAll(_loadFonts);

  final now = DateTime.now();
  String day(int offset) {
    final d = now.subtract(Duration(days: offset));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  final prescriptions = [
    _prescription('1', 'Dr. Teja Chennu', 'General Physician', day(1), 'Viral fever with body pain',
        ['Dolo 650', 'Cetirizine 10mg', 'Pantoprazole 40mg', 'ORS sachet', 'Vitamin C']),
    _prescription('2', 'Dr. Asha Rao', 'Endocrinologist', day(40), 'Type 2 Diabetes', ['Metformin 500mg']),
  ];

  final reminders = [
    MedicationReminder(
      id: 'r1',
      medicineName: 'Dolo 650',
      dosage: '1 tablet',
      durationDays: 5,
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 3)),
      times: const ['08:00 AM', '02:00 PM', '09:00 PM'],
      doctorName: 'Teja Chennu',
      takenDoses: {'${day(0)}_08:00 AM': true},
    ),
    MedicationReminder(
      id: 'r2',
      medicineName: 'Metformin 500mg',
      dosage: '1 tablet',
      durationDays: 0,
      isContinuous: true,
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 365)),
      times: const ['09:00 AM', '08:30 PM'],
      mealRelation: 'After Food',
      doctorName: 'Asha Rao',
    ),
  ];

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    final tag = size.width > 350 ? 'phone' : 'small';
    for (final tab in [0, 1]) {
      testWidgets('prescriptions screen tab $tab renders ($tag)', (tester) async {
        SharedPreferences.setMockInitialValues({});
        MedicationReminderService.instance.remindersNotifier.value = reminders;
        tester.view.physicalSize = Size(size.width * 3, size.height * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Poppins'),
          home: PrescriptionManagementScreen(
            initialTabIndex: tab,
            bloc: _PresetBloc(MedicationState(
              status: MedicationStatus.success,
              allPrescriptions: prescriptions,
              filteredPrescriptions: prescriptions,
            )),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Prescriptions'), findsWidgets);
        if (tab == 0) {
          expect(find.text('Dolo 650'), findsOneWidget);
          expect(find.text('+2 more'), findsOneWidget);
        } else {
          expect(find.text("Today's schedule"), findsOneWidget);
        }
        if (_shotsDir != null) {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/rx_tab${tab}_$tag.png')));
        }
      });
    }
  }

  Future<void> sized(WidgetTester tester, Size size) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    final tag = size.width > 350 ? 'phone' : 'small';

    testWidgets('prescription details renders ($tag)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      MedicationReminderService.instance.remindersNotifier.value = [
        MedicationReminder(
          id: 'r9',
          prescriptionId: '1',
          medicineName: 'Dolo 650',
          durationDays: 5,
          startDate: now,
          endDate: now.add(const Duration(days: 4)),
          times: const ['08:00 AM', '02:00 PM', '09:00 PM'],
        ),
      ];
      await sized(tester, size);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Poppins'),
        home: PrescriptionDetailScreen(
          prescriptionId: '1',
          initialData: {
            ...prescriptions.first,
            'notes': 'Drink plenty of fluids and rest. Come back if fever lasts more than 3 days.',
            'medications': [
              {'name': 'Dolo 650', 'dosage': '1 tablet - Thrice daily', 'frequency': 'Thrice daily', 'instructions': 'After food', 'duration': '5 Days'},
              {'name': 'Cetirizine 10mg', 'dosage': '1 tablet - Once at night', 'frequency': 'Once daily', 'instructions': 'Take at bedtime, may cause drowsiness', 'duration': '3 Days'},
            ],
          },
          bloc: _PresetBloc(const MedicationState(status: MedicationStatus.success)),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Daily reminder on'), findsOneWidget);
      expect(find.text('Set daily reminder'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/rx_details_$tag.png')));
      }
    });

    testWidgets('floating reminder popup renders ($tag)', (tester) async {
      await sized(tester, size);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Poppins'),
        home: Container(
          color: const Color(0xFF0B3B5C),
          child: MedicationPopupOverlay(
            initialData: const MedicationPopupData(
              reminderId: 'r1',
              medicineName: 'Metformin 500mg',
              dosage: '1 tablet',
              mealRelation: 'After Food',
              time: '08:30 PM',
            ),
            onClose: () async {},
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mark as Taken'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/popup_$tag.png')));
      }
    });
  }

}
