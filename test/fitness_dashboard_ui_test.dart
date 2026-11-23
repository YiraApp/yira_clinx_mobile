// Renders the fitness dashboard with sample data at phone sizes. Any layout
// overflow fails the test. Run with DIET_SHOTS=<dir> and --update-goldens to
// also save screenshots.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/services/fitness/fitness_service.dart';
import 'package:yiraclinics/features/data/models/fitness/patient_fitness_model.dart';
import 'package:yiraclinics/features/presentation/patient/fitness/patient_fitness_dashboard_screen.dart';

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

String _day(int back) => FitnessService.dateKey(DateTime.now().subtract(Duration(days: back)));

PatientFitnessSummaryResponse _summary({bool empty = false}) {
  final steps = [6200, null, 9100, 7400, 11250, 5300, 4870];
  final sleep = [412, 455, null, 390, 468, 501, 437];
  final resting = [64, 63, null, 65, 62, 61, 62];
  return PatientFitnessSummaryResponse.fromJson({
    'patientId': 'p',
    'period': 'week',
    'latest': {'weightKg': 71.4, 'weightDate': _day(3), 'bloodOxygen': 97, 'bloodOxygenDate': _day(1)},
    'lastSyncedAt': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(),
    'analytics': {
      'steps': {'average': 7353},
      'sleep': {'averageMinutes': 444},
      'heartRate': {'restingAverage': 63},
      'previous': {'stepsAverage': 6400, 'sleepAverageMinutes': 420, 'restingHeartRateAverage': 64},
    },
    'chartPoints': [
      for (var i = 0; i < 7; i++)
        empty
            ? {'date': _day(6 - i)}
            : {
                'date': _day(6 - i),
                'steps': steps[i],
                'calories': steps[i] == null ? null : steps[i]! * 0.045,
                'distanceMeters': steps[i] == null ? null : steps[i]! * 0.74,
                'sleepMinutes': sleep[i],
                'restingHeartRate': resting[i],
                'heartRateAvg': resting[i] == null ? null : resting[i]! + 14,
                'weightKg': i == 3 ? 71.4 : null,
              },
    ],
  });
}

/// 30 days, every one with steps, so it's easy to tell apart from the 7-day summary.
PatientFitnessSummaryResponse _monthSummary() => PatientFitnessSummaryResponse.fromJson({
      'patientId': 'p',
      'period': 'month',
      'analytics': {'steps': {'average': 9000}},
      'chartPoints': [
        for (var i = 0; i < 30; i++) {'date': _day(29 - i), 'steps': 9000},
      ],
    });

TodayFitnessData _today() => TodayFitnessData.fromJson({
      'date': _day(0),
      'steps': 4870,
      'calories': 219.4,
      'distanceMeters': 3604,
      'heartRateAvg': 76,
      'heartRateMin': 58,
      'heartRateMax': 128,
      'restingHeartRate': 62,
      'sleepMinutes': 437,
      'sleepDeepMinutes': 82,
      'sleepRemMinutes': 96,
      'sleepLightMinutes': 259,
      'sleepAwakeMinutes': 18,
      'hourly': [
        for (var h = 0; h < 15; h++) {'hour': h, 'steps': h < 7 ? 0 : [320, 910, 410, 260, 180, 650, 1120, 540][h - 7], 'heartRate': 70},
      ],
    });

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(
    WidgetTester tester,
    Size size, {
    bool dark = false,
    bool empty = false,
    double textScale = 1,
    Future<PatientFitnessSummaryResponse?> Function(String period)? loader,
  }) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins', brightness: dark ? Brightness.dark : Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: PatientFitnessDashboardScreen(
        previewSummary: loader == null ? _summary(empty: empty) : null,
        previewToday: empty ? TodayFitnessData(date: _day(0)) : _today(),
        summaryLoader: loader,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  for (final size in [const Size(390, 1900), const Size(320, 1900)]) {
    final tag = size.width > 350 ? 'phone' : 'small';
    testWidgets('dashboard renders with data ($tag)', (tester) async {
      await pump(tester, size);
      expect(find.text('4,870'), findsOneWidget);
      expect(find.text('Last night'), findsOneWidget);
      expect(find.text('7h 17m'), findsOneWidget);
      expect(find.text('Steps by hour'), findsOneWidget);
      expect(find.text('6 of 7 days have a reading · dashed line is your goal'), findsOneWidget);
      expect(find.textContaining('+15% vs previous 7 days'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/fitness_$tag.png')));
      }
    });
  }

  testWidgets('switching to a line metric shows gaps, not zeros', (tester) async {
    await pump(tester, const Size(390, 1900));
    await tester.tap(find.text('Resting HR'));
    await tester.pumpAndSettle();
    final chip = tester.getRect(find.text('Resting heart rate'));
    expect(chip.left >= 0 && chip.right <= 390, isTrue, reason: 'selected chip scrolls into view');
    expect(find.text('Daily average'), findsOneWidget);
    expect(find.text('6 of 7 days have a reading'), findsOneWidget);
    if (_shotsDir != null) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/fitness_resting.png')));
    }
  });

  testWidgets('no readings shows dashes and empty states', (tester) async {
    await pump(tester, const Size(390, 1900), empty: true);
    expect(find.text('No sleep recorded'), findsOneWidget);
    expect(find.textContaining('No steps recorded yet today'), findsOneWidget);
    expect(find.text('No steps readings in the last 7 days'), findsOneWidget);
    expect(find.textContaining('vs previous'), findsNothing);
    if (_shotsDir != null) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/fitness_empty.png')));
    }
  });

  testWidgets('a small phone with large text does not overflow', (tester) async {
    await pump(tester, const Size(320, 2400), textScale: 1.3);
    expect(find.text('4,870'), findsOneWidget);
    await tester.tap(find.text('Resting HR'));
    await tester.pumpAndSettle();
    expect(find.text('6 of 7 days have a reading'), findsOneWidget);
  });

  testWidgets('history that fails to load offers a retry, not "no readings"', (tester) async {
    var fail = true;
    await pump(tester, const Size(390, 1900), loader: (_) async => fail ? null : _summary());
    expect(find.text('Couldn\'t load your fitness history'), findsOneWidget);
    expect(find.textContaining('No steps readings'), findsNothing);
    expect(find.textContaining('days have a reading'), findsNothing);
    // Today's numbers come from the phone and still show.
    expect(find.text('4,870'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Couldn\'t load your fitness history'), findsNothing);
    expect(find.text('6 of 7 days have a reading · dashed line is your goal'), findsOneWidget);
  });

  testWidgets('a slow 30-day reply never replaces the 7-day view picked after it', (tester) async {
    final pending = <String, Completer<PatientFitnessSummaryResponse?>>{};
    var calls = 0;
    Future<PatientFitnessSummaryResponse?> loader(String period) {
      calls++;
      if (calls == 1) return Future.value(_summary());
      return (pending[period] = Completer<PatientFitnessSummaryResponse?>()).future;
    }

    await pump(tester, const Size(390, 1900), loader: loader);
    expect(find.text('6 of 7 days have a reading · dashed line is your goal'), findsOneWidget);

    await tester.tap(find.text('30 days'));
    await tester.pump();
    await tester.tap(find.text('7 days'));
    await tester.pump();

    pending['week']!.complete(_summary());
    await tester.pump();
    pending['month']!.complete(_monthSummary());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('6 of 7 days have a reading · dashed line is your goal'), findsOneWidget);
    expect(find.textContaining('of 30 days'), findsNothing);
  });

  testWidgets('dark mode uses the app\'s charcoal cards', (tester) async {
    await pump(tester, const Size(390, 1900), dark: true);
    expect(find.text('Trends'), findsOneWidget);
    final fills = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration is BoxDecoration ? (c.decoration as BoxDecoration).color : null)
        .whereType<Color>()
        .toSet();
    expect(fills, contains(const Color(0xFF232323)));
    expect(fills, isNot(contains(const Color(0xFF161616))));
    if (_shotsDir != null) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/fitness_dark.png')));
    }
  });
}
