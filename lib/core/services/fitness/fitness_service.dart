import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// One calendar day of readings from Apple Health or Health Connect.
///
/// A null value means the phone has no reading for that day, which is
/// different from a reading of zero. Nothing here is estimated.
class FitnessDay {
  FitnessDay(this.date);

  final DateTime date;
  int? steps;
  double? activeCalories;
  double? totalCalories;
  double? distanceMeters;
  double? heartRateAvg;
  double? heartRateMin;
  double? heartRateMax;
  double? restingHeartRate;
  double? bloodOxygen;
  double? weightKg;
  int? sleepMinutes;
  int? sleepDeepMinutes;
  int? sleepRemMinutes;
  int? sleepLightMinutes;
  int? sleepAwakeMinutes;
  List<Map<String, dynamic>> hourly = const [];
  Set<String> sources = {};

  String get dateKey => FitnessService.dateKey(date);

  /// Active calories when the phone records them, else the total burn.
  double? get calories => activeCalories ?? totalCalories;

  bool get hasAnyReading => [
        steps,
        calories,
        distanceMeters,
        heartRateAvg,
        restingHeartRate,
        bloodOxygen,
        weightKg,
        sleepMinutes,
      ].any((v) => v != null && v > 0);

  static double? _round(double? v) => v == null ? null : double.parse(v.toStringAsFixed(1));

  Map<String, dynamic> toPayload() => {
        'date': dateKey,
        'steps': steps,
        'calories': _round(calories),
        'distanceMeters': _round(distanceMeters),
        'heartRateAvg': _round(heartRateAvg),
        'heartRateMin': _round(heartRateMin),
        'heartRateMax': _round(heartRateMax),
        'restingHeartRate': _round(restingHeartRate),
        'bloodOxygen': _round(bloodOxygen),
        'sleepMinutes': sleepMinutes,
        'sleepDeepMinutes': sleepDeepMinutes,
        'sleepRemMinutes': sleepRemMinutes,
        'sleepLightMinutes': sleepLightMinutes,
        'sleepAwakeMinutes': sleepAwakeMinutes,
        'weightKg': _round(weightKg),
        if (hourly.isNotEmpty) 'rawHourlyJson': hourly,
        if (sources.isNotEmpty) 'rawMetricsJson': {'sources': sources.toList()..sort()},
      };
}

class FitnessService {
  FitnessService._();
  static final FitnessService instance = FitnessService._();

  final Health _health = Health();
  bool _isConfigured = false;

  /// Ensure Health SDK is configured
  Future<void> configure() async {
    if (_isConfigured) return;
    try {
      await _health.configure();
      _isConfigured = true;
    } catch (e) {
      debugPrint('⚠️ [FitnessService] Error configuring health plugin: $e');
    }
  }

  /// Platform source name
  String get platformSourceName {
    if (Platform.isIOS) return 'AppleHealth';
    if (Platform.isAndroid) return 'GoogleHealthConnect';
    return 'Unknown';
  }

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  List<HealthDataType> get _sleepTypes => Platform.isIOS
      ? const [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_IN_BED,
        ]
      : const [
          HealthDataType.SLEEP_SESSION,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_AWAKE,
        ];

  HealthDataType get _distanceType =>
      Platform.isIOS ? HealthDataType.DISTANCE_WALKING_RUNNING : HealthDataType.DISTANCE_DELTA;

  /// Every type the app reads. All are read-only.
  List<HealthDataType> get supportedTypes => [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        if (Platform.isAndroid) HealthDataType.TOTAL_CALORIES_BURNED,
        _distanceType,
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
        ..._sleepTypes,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.WEIGHT,
      ];

  /// Check whether Health Connect is installed or needs update on Android
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }

  /// Prompt user to install Google Health Connect from Google Play Store if needed
  Future<void> promptInstallHealthConnect() async {
    if (Platform.isAndroid) {
      try {
        await _health.installHealthConnect();
      } catch (e) {
        debugPrint('⚠️ [FitnessService] Error launching Health Connect installer: $e');
      }
    }
  }

  /// Whether the phone has granted read access to at least one core type.
  ///
  /// HealthKit never says whether read access was granted, so on iOS this is
  /// always true and the caller relies on the user's own connect choice.
  Future<bool> hasOsPermission() async {
    await configure();
    if (Platform.isIOS) return true;
    if (!await isHealthConnectAvailable()) return false;
    for (final t in const [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_SESSION,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.WEIGHT,
    ]) {
      try {
        if (await _health.hasPermissions([t], permissions: [HealthDataAccess.READ]) == true) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Asks for read access to every supported type. Returns whether any access is usable.
  Future<bool> requestPermissions() async {
    await configure();
    final types = supportedTypes;
    try {
      final granted = await _health.requestAuthorization(
        types,
        permissions: List.filled(types.length, HealthDataAccess.READ),
      );
      if (granted) return true;
    } catch (e) {
      debugPrint('⚠️ [FitnessService] Error requesting health permissions: $e');
    }
    return Platform.isAndroid ? hasOsPermission() : false;
  }

  /// Reads one entry per calendar day from [from] (inclusive) to today.
  Future<List<FitnessDay>> readDays({required DateTime from}) async {
    await configure();
    final now = DateTime.now();
    final start = _midnight(from);
    final days = <String, FitnessDay>{};
    for (var d = start; !d.isAfter(now); d = DateTime(d.year, d.month, d.day + 1)) {
      days[dateKey(d)] = FitnessDay(d);
    }

    await _readSteps(days, start, now);
    await _readCumulative(days, HealthDataType.ACTIVE_ENERGY_BURNED, start, now,
        (day, v) => day.activeCalories = v);
    if (Platform.isAndroid) {
      await _readCumulative(days, HealthDataType.TOTAL_CALORIES_BURNED, start, now,
          (day, v) => day.totalCalories = v);
    }
    await _readCumulative(days, _distanceType, start, now, (day, v) => day.distanceMeters = v);
    await _readHeartRate(days, start, now);
    await _readLatestPerDay(days, HealthDataType.RESTING_HEART_RATE, start, now,
        (day, v) => day.restingHeartRate = v);
    await _readLatestPerDay(days, HealthDataType.BLOOD_OXYGEN, start, now,
        (day, v) => day.bloodOxygen = v <= 1.0 ? v * 100.0 : v);
    await _readLatestPerDay(days, HealthDataType.WEIGHT, start, now, (day, v) => day.weightKg = v);
    await _readSleep(days, start, now);

    final today = days[dateKey(now)];
    if (today != null) await _readTodayHourly(today, now);

    return days.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// The latest weight within [lookback], for the summary card on days with no weigh-in.
  Future<double?> readLatestWeight({Duration lookback = const Duration(days: 90)}) async {
    final now = DateTime.now();
    final points = await _points([HealthDataType.WEIGHT], now.subtract(lookback), now);
    if (points.isEmpty) return null;
    points.sort((a, b) => a.dateTo.compareTo(b.dateTo));
    final v = _numeric(points.last.value);
    return v > 0 ? v : null;
  }

  // Steps: the platform's own de-duplicated total, one query per day.
  Future<void> _readSteps(Map<String, FitnessDay> days, DateTime start, DateTime now) async {
    var gotAny = false;
    for (final day in days.values) {
      final end = day.dateKey == dateKey(now) ? now : DateTime(day.date.year, day.date.month, day.date.day + 1);
      try {
        final steps = await _health.getTotalStepsInInterval(day.date, end);
        if (steps != null && steps > 0) {
          day.steps = steps;
          gotAny = true;
        }
      } catch (e) {
        debugPrint('⚠️ [FitnessService] Step total failed for ${day.dateKey}: $e');
      }
    }
    if (gotAny) return;
    // Some phones answer the total query with nothing; fall back to the busiest source per day.
    await _readCumulative(days, HealthDataType.STEPS, start, now, (day, v) => day.steps = v.round());
  }

  /// A daily total for a cumulative type, taken from the platform's
  /// statistics where it supports them, else from the single source that
  /// recorded the most that day. Two apps logging the same walk are never added
  /// together.
  Future<void> _readCumulative(
    Map<String, FitnessDay> days,
    HealthDataType type,
    DateTime start,
    DateTime now,
    void Function(FitnessDay day, double value) assign,
  ) async {
    if (Platform.isIOS) {
      try {
        final stats = await _health.getHealthIntervalDataFromTypes(
          startDate: start,
          endDate: now,
          types: [type],
          interval: 86400,
        );
        var gotAny = false;
        for (final p in stats) {
          // Key by the middle of the bucket so a DST shift can't move it to the wrong day.
          final day = days[dateKey(p.dateFrom.add(const Duration(hours: 12)))];
          final v = _numeric(p.value);
          if (day != null && v > 0) {
            assign(day, v);
            gotAny = true;
          }
        }
        if (gotAny) return;
      } catch (e) {
        debugPrint('⚠️ [FitnessService] Statistics query failed for $type: $e');
      }
    }

    final points = await _points([type], start, now);
    final perDaySource = <String, Map<String, double>>{};
    for (final p in points) {
      final v = _numeric(p.value);
      if (v <= 0) continue;
      final key = dateKey(p.dateFrom);
      if (!days.containsKey(key)) continue;
      final bySource = perDaySource.putIfAbsent(key, () => {});
      bySource.update(_sourceKey(p), (s) => s + v, ifAbsent: () => v);
      days[key]!.sources.add(_sourceLabel(p));
    }
    perDaySource.forEach((key, bySource) {
      final best = bySource.values.fold<double>(0, math.max);
      if (best > 0) assign(days[key]!, best);
    });
  }

  Future<void> _readHeartRate(Map<String, FitnessDay> days, DateTime start, DateTime now) async {
    final points = await _points([HealthDataType.HEART_RATE], start, now);
    final byDay = <String, List<double>>{};
    for (final p in points) {
      final v = _numeric(p.value);
      if (v < 25 || v > 240) continue;
      final key = dateKey(p.dateFrom);
      if (!days.containsKey(key)) continue;
      byDay.putIfAbsent(key, () => []).add(v);
      days[key]!.sources.add(_sourceLabel(p));
    }
    byDay.forEach((key, values) {
      final day = days[key]!;
      day.heartRateAvg = values.reduce((a, b) => a + b) / values.length;
      day.heartRateMin = values.reduce(math.min);
      day.heartRateMax = values.reduce(math.max);
    });
  }

  /// The most recent reading of a spot measurement (SpO2, weight, resting HR) on each day.
  Future<void> _readLatestPerDay(
    Map<String, FitnessDay> days,
    HealthDataType type,
    DateTime start,
    DateTime now,
    void Function(FitnessDay day, double value) assign,
  ) async {
    final points = await _points([type], start, now);
    points.sort((a, b) => a.dateTo.compareTo(b.dateTo));
    for (final p in points) {
      final v = _numeric(p.value);
      final day = days[dateKey(p.dateFrom)];
      if (day == null || v <= 0) continue;
      assign(day, v);
    }
  }

  /// Sleep per night, credited to the day the person woke up (as Fitbit,
  /// Garmin and Google Fit do). Overlapping records from different apps are
  /// merged rather than added, and each minute counts once, under its deepest
  /// recorded stage.
  Future<void> _readSleep(Map<String, FitnessDay> days, DateTime start, DateTime now) async {
    // Start the evening before so the first morning's night is complete.
    final points = await _points(_sleepTypes, start.subtract(const Duration(hours: 12)), now);
    if (points.isEmpty) return;

    final segments = <_Segment>[
      for (final p in points)
        if (p.dateTo.isAfter(p.dateFrom)) _Segment(p.dateFrom, p.dateTo, _stageOf(p.type)),
    ];
    if (segments.isEmpty) return;

    final minutes = _sweepStages(segments);
    for (final entry in minutes.entries) {
      final day = days[entry.key];
      if (day == null) continue;
      final m = entry.value;
      final asleep = m[_SleepStage.deep]! + m[_SleepStage.rem]! + m[_SleepStage.light]! + m[_SleepStage.asleep]!;
      // m[_SleepStage.inBed] is what's left of a session no stage covers, and doesn't count as sleep.
      if (asleep <= 0) continue;
      day.sleepMinutes = asleep;
      day.sleepDeepMinutes = m[_SleepStage.deep]! > 0 ? m[_SleepStage.deep] : null;
      day.sleepRemMinutes = m[_SleepStage.rem]! > 0 ? m[_SleepStage.rem] : null;
      day.sleepLightMinutes = m[_SleepStage.light]! > 0 ? m[_SleepStage.light] : null;
      day.sleepAwakeMinutes = m[_SleepStage.awake]! > 0 ? m[_SleepStage.awake] : null;
    }
  }

  /// Splits the timeline at every boundary, keeps the highest-priority stage
  /// for each piece, and credits each block of sleep to its wake-up date.
  static Map<String, Map<_SleepStage, int>> _sweepStages(List<_Segment> segments) {
    final bounds = <DateTime>{};
    for (final s in segments) {
      bounds
        ..add(s.from)
        ..add(s.to);
    }
    final sorted = bounds.toList()..sort();
    final pieces = <_Segment>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      _SleepStage? best;
      for (final s in segments) {
        if (!s.from.isAfter(a) && !s.to.isBefore(b)) {
          if (best == null || s.stage.index > best.index) best = s.stage;
        }
      }
      if (best != null) pieces.add(_Segment(a, b, best));
    }

    // Pieces less than 90 minutes apart belong to the same night.
    final result = <String, Map<_SleepStage, int>>{};
    var block = <_Segment>[];
    void flush() {
      if (block.isEmpty) return;
      final key = dateKey(block.last.to);
      final totals = result.putIfAbsent(key, () => {for (final s in _SleepStage.values) s: 0});
      // A night with no stage data at all (a bare session) counts as asleep throughout.
      final hasStages = block.any((p) => p.stage != _SleepStage.inBed);
      for (final p in block) {
        final stage = (!hasStages && p.stage == _SleepStage.inBed) ? _SleepStage.asleep : p.stage;
        totals[stage] = totals[stage]! + p.to.difference(p.from).inSeconds;
      }
      block = [];
    }

    for (final p in pieces) {
      if (block.isNotEmpty && p.from.difference(block.last.to) > const Duration(minutes: 90)) flush();
      block.add(p);
    }
    flush();
    return result.map((k, v) => MapEntry(k, v.map((s, secs) => MapEntry(s, (secs / 60).round()))));
  }

  /// Sleep minutes per wake-up date for raw (from, to, type) records. Exposed for tests.
  @visibleForTesting
  static Map<String, Map<String, int>> sleepByWakeDate(List<(DateTime, DateTime, HealthDataType)> records) {
    final segments = [for (final r in records) _Segment(r.$1, r.$2, _stageOf(r.$3))];
    return _sweepStages(segments).map((k, v) => MapEntry(k, v.map((s, m) => MapEntry(s.name, m))));
  }

  static _SleepStage _stageOf(HealthDataType type) {
    switch (type) {
      case HealthDataType.SLEEP_DEEP:
        return _SleepStage.deep;
      case HealthDataType.SLEEP_REM:
        return _SleepStage.rem;
      case HealthDataType.SLEEP_LIGHT:
        return _SleepStage.light;
      case HealthDataType.SLEEP_ASLEEP:
        return _SleepStage.asleep;
      case HealthDataType.SLEEP_AWAKE:
        return _SleepStage.awake;
      default:
        return _SleepStage.inBed; // SLEEP_SESSION / SLEEP_IN_BED
    }
  }

  /// Steps and heart rate by hour for today's chart. Hourly steps are scaled
  /// so they add up to the day's de-duplicated total.
  Future<void> _readTodayHourly(FitnessDay today, DateTime now) async {
    final start = _midnight(now);
    final stepPoints = await _points([HealthDataType.STEPS], start, now);
    final hrPoints = await _points([HealthDataType.HEART_RATE], start, now);
    if (stepPoints.isEmpty && hrPoints.isEmpty) return;

    final perSource = <String, List<double>>{};
    for (final p in stepPoints) {
      final hours = perSource.putIfAbsent(_sourceKey(p), () => List.filled(24, 0));
      hours[p.dateFrom.hour] += _numeric(p.value);
    }
    final stepsByHour = List<double>.filled(24, 0);
    if (perSource.isNotEmpty) {
      final best = perSource.values.reduce(
          (a, b) => a.fold<double>(0, (s, v) => s + v) >= b.fold<double>(0, (s, v) => s + v) ? a : b);
      final rawTotal = best.fold<double>(0, (s, v) => s + v);
      final scale = (today.steps != null && rawTotal > 0) ? today.steps! / rawTotal : 1.0;
      for (var h = 0; h < 24; h++) {
        stepsByHour[h] = best[h] * scale;
      }
    }
    final hrByHour = <int, List<double>>{};
    for (final p in hrPoints) {
      final v = _numeric(p.value);
      if (v >= 25 && v <= 240) hrByHour.putIfAbsent(p.dateFrom.hour, () => []).add(v);
    }

    today.hourly = [
      for (var h = 0; h <= now.hour; h++)
        {
          'hour': h,
          'steps': stepsByHour[h].round(),
          'heartRate': hrByHour[h] == null
              ? 0
              : double.parse((hrByHour[h]!.reduce((a, b) => a + b) / hrByHour[h]!.length).toStringAsFixed(1)),
          'calories': 0,
        },
    ];
  }

  /// Reads raw points, one type at a time so a type the user didn't grant
  /// doesn't stop the others.
  Future<List<HealthDataPoint>> _points(List<HealthDataType> types, DateTime start, DateTime end) async {
    final all = <HealthDataPoint>[];
    for (final type in types) {
      try {
        all.addAll(await _health.getHealthDataFromTypes(startTime: start, endTime: end, types: [type]));
      } catch (e) {
        debugPrint('⚠️ [FitnessService] Skipping $type: $e');
      }
    }
    return _health.removeDuplicates(all);
  }

  static double _numeric(HealthValue value) {
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    return 0.0;
  }

  static String _sourceKey(HealthDataPoint p) =>
      p.sourceId.isNotEmpty ? p.sourceId : (p.sourceName.isNotEmpty ? p.sourceName : 'unknown');

  static const Map<String, String> _knownSources = {
    'com.sec.android.app.shealth': 'Samsung Health',
    'com.google.android.apps.fitness': 'Google Fit',
    'com.fitbit.fitbitmobile': 'Fitbit',
    'com.garmin.android.apps.connectmobile': 'Garmin Connect',
    'com.mi.health': 'Mi Fitness',
    'com.xiaomi.wearable': 'Mi Fitness',
    'com.huawei.health': 'Huawei Health',
    'com.noisefit': 'NoiseFit',
    'com.oneplus.health.international': 'OHealth',
    'com.heytap.health.international': 'OHealth',
    'com.ouraring.oura': 'Oura',
    'com.whoop.android': 'WHOOP',
    'com.strava': 'Strava',
    'com.google.android.apps.healthdata': 'Health Connect',
    'android': 'This phone',
  };

  /// A readable name for the app or device a reading came from.
  static String sourceLabel(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return 'Unknown';
    return _knownSources[key] ?? raw.trim();
  }

  static String _sourceLabel(HealthDataPoint p) => sourceLabel(p.sourceName.isNotEmpty ? p.sourceName : p.sourceId);
}

// Ordered by priority: a minute recorded as both light and deep counts as deep,
// and a session only fills the gaps no stage covers.
enum _SleepStage { inBed, awake, asleep, light, rem, deep }

class _Segment {
  _Segment(this.from, this.to, this.stage);
  final DateTime from;
  final DateTime to;
  final _SleepStage stage;
}
