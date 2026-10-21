// Renders the diet screens with sample data at phone sizes. Any layout
// overflow fails the test. Run with DIET_SHOTS=<dir> and --update-goldens to
// also save screenshots for a visual check.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/data_sources/diet/doctor_diet_remote_data_source.dart';
import 'package:yiraclinics/features/data/data_sources/diet/patient_diet_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/diet/patient_diet_plan_model.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/doctor_patient_diet_tab.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/doctor_prescribe_diet_sheet.dart';
import 'package:yiraclinics/features/presentation/patient/diet/patient_diet_edit_screen.dart';
import 'package:yiraclinics/features/presentation/patient/diet/patient_diet_plan_screen.dart';
import 'package:yiraclinics/features/presentation/patient/diet/patient_diet_plans_screen.dart';

String _date(DateTime d) => dietDateKey(d);

final DateTime _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

Map<String, dynamic> _meal(int id, int day, String slot, String time, String name, double qty, String unit, num kcal,
    {num? p, num? c, num? f, String? category}) {
  return {
    'Id': id,
    'PlanId': 7,
    'DayNumber': day,
    'MealSlot': slot,
    'MealTime': time,
    'FoodName': name,
    'Quantity': qty,
    'Unit': unit,
    'Calories': kcal,
    'ProteinG': p,
    'CarbsG': c,
    'FatG': f,
    if (category != null) 'FoodItem': {'Category': category, 'FoodType': 'Veg'},
  };
}

Map<String, dynamic> _planDetails() {
  final meals = <Map<String, dynamic>>[];
  var id = 1;
  for (var day = 1; day <= 3; day++) {
    meals.addAll([
      _meal(id++, day, 'Early Morning', '06:30 AM', 'Warm Lemon Water (No Sugar)', 1, 'glass', 6, category: 'Beverage'),
      _meal(id++, day, 'Breakfast', '08:30 AM', 'Idli (2 pieces)', 1, '2 pieces (80g)', 104, p: 4, c: 22, f: 0.4, category: 'Breakfast'),
      _meal(id++, day, 'Breakfast', '08:30 AM', 'Coconut Chutney', 2, 'tbsp', 0, p: 1, c: 2, f: 6, category: 'Other'),
      _meal(id++, day, 'Lunch', '01:30 PM', 'Brown Rice with Toor Dal and Mixed Vegetable Curry', 1, 'plate', 420, p: 14, c: 68, f: 9, category: 'Grain'),
      _meal(id++, day, 'Lunch', '01:30 PM', 'Homemade pickle', 1, 'tsp', 0),
      _meal(id++, day, 'Dinner', '08:00 PM', 'Chapati / Phulka (Whole Wheat)', 2, 'roti', 168, p: 6, c: 35, f: 1, category: 'Grain'),
    ]);
  }
  return {
    'Id': 7,
    'PlanName': 'Diabetes Friendly Vegetarian Plan',
    'Status': 'active',
    'TotalDays': 3,
    'StartDate': _date(_today.subtract(const Duration(days: 3))),
    'EndDate': _date(_today.add(const Duration(days: 26))),
    'TargetCalories': 1600,
    'DietType': 'Veg',
    'Condition': 'Type 2 Diabetes',
    'DoctorNotes': 'Walk 30 minutes after dinner. Drink 2.5 litres of water a day.',
    'FoodsToAvoid': '["Refined sugar","Maida","Fried snacks"]',
    'FoodsToPrefer': '["Millets","Sprouts","Green leafy vegetables"]',
    'AssignedByDoctor': {'FirstName': 'Asha', 'LastName': 'Rao'},
    'Hospital': {'Name': 'Yira Multispeciality Hospital, Banjara Hills'},
    'Organization': {'Name': 'Yira Clinics'},
    'Meals': meals,
  };
}

class _FakePatientDiet extends PatientDietRemoteDataSource {
  @override
  Future<List<PatientDietPlanSummary>> getMyPlans() async => [
        PatientDietPlanSummary.fromJson({
          'id': 7,
          'planName': 'Diabetes Friendly Vegetarian Plan',
          'status': 'active',
          'startDate': _date(_today.subtract(const Duration(days: 3))),
          'endDate': _date(_today.add(const Duration(days: 26))),
          'totalDays': 3,
          'targetCalories': 1600,
          'doctorName': 'Asha Rao',
          'hospitalName': 'Yira Multispeciality Hospital, Banjara Hills',
          'mealCount': 18,
          'canDeactivate': true,
        }),
        PatientDietPlanSummary.fromJson({
          'id': 5,
          'planName': 'High Protein Weight Loss Plan with a Very Long Name for Testing',
          'status': 'paused',
          'startDate': _date(_today.subtract(const Duration(days: 40))),
          'endDate': _date(_today.add(const Duration(days: 20))),
          'totalDays': 7,
          'targetCalories': 1400,
          'doctorName': 'Ravi Kumar',
          'organizationName': 'Apollo',
          'mealCount': 42,
          'canActivate': true,
        }),
        PatientDietPlanSummary.fromJson({
          'id': 9,
          'planName': 'My summer plan',
          'status': 'paused',
          'startDate': _date(_today.subtract(const Duration(days: 2))),
          'totalDays': 1,
          'targetCalories': 1800,
          'doctorName': 'You',
          'mealCount': 6,
          'canActivate': true,
          'createdByPatient': true,
        }),
        PatientDietPlanSummary.fromJson({
          'id': 3,
          'planName': 'Post-surgery soft diet',
          'status': 'completed',
          'startDate': '2026-01-01',
          'endDate': '2026-01-31',
          'totalDays': 1,
          'doctorName': 'Asha Rao',
          'hospitalName': 'Yira Hospital',
          'mealCount': 8,
          'isExpired': true,
        }),
      ];

  @override
  Future<Map<String, dynamic>?> getPlanDetails(int planId) async => _planDetails();

  @override
  Future<List<DietMealLog>> getMealLogs(int planId, DateTime from, DateTime to) async => [
        DietMealLog(planMealId: 2, logDate: _date(_today), isEaten: true),
        DietMealLog(planMealId: 3, logDate: _date(_today), isEaten: true),
      ];
}

class _FakeDoctorDiet extends DoctorDietRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> getPatientPlans(String patientId, {String? orgId, bool fullHistory = false}) async => [
        _planDetails(),
        {..._planDetails(), 'Id': 5, 'PlanName': 'Weight Loss Plan', 'Status': 'cancelled', 'Condition': null},
      ];
}

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final iconFile = flutterRoot == null
      ? null
      : File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (iconFile != null && iconFile.existsSync()) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(iconFile.readAsBytesSync().buffer)));
    await icons.load();
  }
}

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

Future<void> _render(WidgetTester tester, Widget screen, Size size, String shot, {bool dark = false}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light, fontFamily: 'Poppins'),
    home: screen,
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));

  if (_shotsDir != null) {
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/$shot.png')));
  }
}

void main() {
  setUpAll(_loadFonts);

  const phone = Size(390, 844);
  const small = Size(320, 640);

  for (final size in [phone, small]) {
    final tag = size == phone ? 'phone' : 'small';

    testWidgets('plans list renders ($tag)', (tester) async {
      await _render(tester, PatientDietPlansScreen(dataSource: _FakePatientDiet()), size, 'plans_$tag');
      expect(find.text('My Diet Plans'), findsOneWidget);
      // With plans listed, a new plan is started from the floating button.
      expect(find.text('New Plan'), findsOneWidget);
    });

    testWidgets('food dashboard renders ($tag)', (tester) async {
      await _render(tester, PatientDietPlanScreen(planId: 7, dataSource: _FakePatientDiet()), size, 'dashboard_$tag');
      expect(find.text('Diabetes Friendly Vegetarian Plan'), findsWidgets);
      expect(find.text('Upload'), findsNothing);
      expect(find.textContaining('no calorie info'), findsOneWidget);
      final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
      await tester.scrollUntilVisible(find.text("Do's & Don'ts"), 200, scrollable: page);
      await tester.scrollUntilVisible(find.text('Refined sugar'), 200, scrollable: page);
      expect(find.text('Refined sugar'), findsOneWidget);
      // Open Lunch, which has a food saved without calories.
      await tester.scrollUntilVisible(find.text('Lunch'), 300, scrollable: page);
      await tester.ensureVisible(find.text('Lunch'));
      await tester.pump(const Duration(milliseconds: 300));
      if (find.text('Calories not added').evaluate().isEmpty) {
        await tester.tap(find.text('Lunch'));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.scrollUntilVisible(find.text('Calories not added'), 200, scrollable: page);
      expect(find.text('Calories not added'), findsOneWidget);
    });

    testWidgets('create my plan renders ($tag)', (tester) async {
      await _render(
        tester,
        PatientDietEditScreen(
          createMode: true,
          meals: const [],
          plan: TodayDietPlanInfo(id: 0, planName: '', doctorName: 'You', organizationName: '', totalDays: 1, createdByPatient: true),
        ),
        size,
        'create_$tag',
      );
      expect(find.text('Create My Plan'), findsOneWidget);
    });

    testWidgets('doctor diet tab renders ($tag)', (tester) async {
      await _render(
        tester,
        Scaffold(body: SafeArea(child: DoctorPatientDietTab(patientId: 'p1', patientName: 'Ravi', dataSource: _FakeDoctorDiet()))),
        size,
        'doctor_tab_$tag',
      );
      expect(find.text('Prescribe'), findsOneWidget);
    });
  }

  for (final size in [phone, small]) {
    testWidgets('doctor templates tab renders (${size == phone ? 'phone' : 'small'})', (tester) async {
      await _render(
        tester,
        DoctorPrescribeDietSheet(
          patientId: 'p1',
          patientName: 'teja chennu',
          debugTemplates: [
            {
              'Id': 3,
              'Name': 'Fever recovery diet with a fairly long name',
              'Condition': 'fever',
              'DietType': 'Veg',
              'TotalDays': 1,
              'TargetCalories': 472,
              'TargetProteinG': 22.5,
              'TargetCarbsG': 67.5,
              'TargetFatG': 11,
              'MealCount': 3,
              'Description': 'Light, easily digested meals while recovering.',
              'IsMine': true,
            },
          ],
        ),
        size,
        'templates_${size == phone ? 'phone' : 'small'}',
      );
      expect(find.text('Use for patient'), findsOneWidget);
    });
  }

  testWidgets('food dashboard renders in dark mode', (tester) async {
    await _render(tester, PatientDietPlanScreen(planId: 7, dataSource: _FakePatientDiet()), phone, 'dashboard_dark', dark: true);
  });
}
