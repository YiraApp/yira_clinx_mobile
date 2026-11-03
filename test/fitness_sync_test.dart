import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:yiraclinics/core/services/fitness/fitness_service.dart';
import 'package:yiraclinics/features/data/models/fitness/patient_fitness_model.dart';

DateTime t(int day, int hour, [int minute = 0]) => DateTime(2026, 10, day, hour, minute);

void main() {
  group('sleep by wake date', () {
    test('a night across midnight counts on the morning you woke up', () {
      final r = FitnessService.sleepByWakeDate([
        (t(10, 23), t(11, 7), HealthDataType.SLEEP_ASLEEP),
      ]);
      expect(r.keys, ['2026-10-11']);
      expect(r['2026-10-11']!['asleep'], 480);
    });

    test('the same night from a phone and a watch is not added twice', () {
      final r = FitnessService.sleepByWakeDate([
        (t(10, 23), t(11, 7), HealthDataType.SLEEP_ASLEEP),
        (t(10, 23, 30), t(11, 6, 30), HealthDataType.SLEEP_LIGHT),
      ]);
      final m = r['2026-10-11']!;
      expect(m['asleep']! + m['light']!, 480);
      expect(m['light'], 420);
    });

    test('a deeper stage wins where stages overlap', () {
      final r = FitnessService.sleepByWakeDate([
        (t(11, 0), t(11, 2), HealthDataType.SLEEP_LIGHT),
        (t(11, 1), t(11, 2), HealthDataType.SLEEP_DEEP),
      ]);
      expect(r['2026-10-11']!['deep'], 60);
      expect(r['2026-10-11']!['light'], 60);
    });

    test('a session only counts when no stage covers the night', () {
      final withStages = FitnessService.sleepByWakeDate([
        (t(10, 22), t(11, 7), HealthDataType.SLEEP_SESSION),
        (t(10, 23), t(11, 6), HealthDataType.SLEEP_LIGHT),
      ]);
      expect(withStages['2026-10-11']!['light'], 420);
      expect(withStages['2026-10-11']!['asleep'], 0);

      final bare = FitnessService.sleepByWakeDate([
        (t(10, 23), t(11, 6), HealthDataType.SLEEP_SESSION),
      ]);
      expect(bare['2026-10-11']!['asleep'], 420);
    });

    test('awake time inside the night is kept apart from sleep', () {
      final r = FitnessService.sleepByWakeDate([
        (t(10, 23), t(11, 3), HealthDataType.SLEEP_LIGHT),
        (t(11, 3), t(11, 3, 30), HealthDataType.SLEEP_AWAKE),
        (t(11, 3, 30), t(11, 7), HealthDataType.SLEEP_REM),
      ]);
      final m = r['2026-10-11']!;
      expect(m['light'], 240);
      expect(m['rem'], 210);
      expect(m['awake'], 30);
    });

    test('two nights stay on their own days', () {
      final r = FitnessService.sleepByWakeDate([
        (t(10, 23), t(11, 6), HealthDataType.SLEEP_ASLEEP),
        (t(11, 23), t(12, 7), HealthDataType.SLEEP_ASLEEP),
      ]);
      expect(r['2026-10-11']!['asleep'], 420);
      expect(r['2026-10-12']!['asleep'], 480);
    });
  });

  group('payload', () {
    test('missing readings are sent as null, never as zero or estimates', () {
      final day = FitnessDay(DateTime(2026, 10, 11))..steps = 5400;
      final p = day.toPayload();
      expect(p['date'], '2026-10-11');
      expect(p['steps'], 5400);
      expect(p['calories'], isNull);
      expect(p['distanceMeters'], isNull);
      expect(p['sleepMinutes'], isNull);
      expect(p['restingHeartRate'], isNull);
      expect(day.hasAnyReading, isTrue);
      expect(FitnessDay(DateTime(2026, 10, 12)).hasAnyReading, isFalse);
    });

    test('active energy is preferred over the total burn', () {
      final day = FitnessDay(DateTime(2026, 10, 11))
        ..totalCalories = 1900
        ..activeCalories = 320.44;
      expect(day.toPayload()['calories'], 320.4);
      day.activeCalories = null;
      expect(day.toPayload()['calories'], 1900.0);
    });
  });

  group('model', () {
    test('zeros and nulls from the server read as no reading', () {
      final p = ChartFitnessPoint.fromJson({'date': '2026-10-11', 'steps': 0, 'sleepMinutes': null, 'weightKg': 71.2});
      expect(p.steps, isNull);
      expect(p.sleepMinutes, isNull);
      expect(p.weightKg, 71.2);
    });

    test('summary reads latest readings and previous-period averages', () {
      final s = PatientFitnessSummaryResponse.fromJson({
        'patientId': 'x',
        'period': 'week',
        'today': null,
        'latest': {'weightKg': 70.5, 'weightDate': '2026-10-09', 'bloodOxygen': 97},
        'lastSyncedAt': '2026-10-11T08:00:00.000Z',
        'analytics': {
          'steps': {'average': 7000},
          'previous': {'stepsAverage': 6000},
          'daysWithData': 5,
        },
        'chartPoints': [
          {'date': '2026-10-10', 'steps': null},
          {'date': '2026-10-11', 'steps': 8000},
        ],
      });
      expect(s.today, isNull);
      expect(s.latestWeightKg, 70.5);
      expect(s.latestBloodOxygen, 97);
      expect(s.analytics!.previousStepsAverage, 6000);
      expect(s.analytics!.daysWithData, 5);
      expect(s.chartPoints.first.steps, isNull);
      expect(s.chartPoints.last.steps, 8000);
    });

    test('sleep formats as hours and minutes', () {
      expect(formatSleepMinutes(452), '7h 32m');
      expect(formatSleepMinutes(45), '45m');
      expect(formatSleepMinutes(null), '--');
    });
  });
}
