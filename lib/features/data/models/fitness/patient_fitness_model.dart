// Fitness values are null when nothing was recorded, which is not the same as zero.

int? _int(dynamic v) {
  final n = v is num ? v : num.tryParse('${v ?? ''}');
  return n == null || n <= 0 ? null : n.round();
}

double? _double(dynamic v) {
  final n = v is num ? v : num.tryParse('${v ?? ''}');
  return n == null || n <= 0 ? null : n.toDouble();
}

String formatSleepMinutes(int? minutes) {
  if (minutes == null || minutes <= 0) return '--';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h == 0 ? '${m}m' : '${h}h ${m.toString().padLeft(2, '0')}m';
}

class TodayFitnessData {
  final String date;
  final int? steps;
  final double? calories;
  final double? distanceMeters;
  final double? heartRateAvg;
  final double? heartRateMin;
  final double? heartRateMax;
  final double? restingHeartRate;
  final double? bloodOxygen;
  final int? sleepMinutes;
  final int? sleepDeepMinutes;
  final int? sleepRemMinutes;
  final int? sleepLightMinutes;
  final int? sleepAwakeMinutes;
  final double? weightKg;
  final String source;
  final DateTime? lastSynced;
  final List<HourlyFitnessPoint> hourly;

  TodayFitnessData({
    required this.date,
    this.steps,
    this.calories,
    this.distanceMeters,
    this.heartRateAvg,
    this.heartRateMin,
    this.heartRateMax,
    this.restingHeartRate,
    this.bloodOxygen,
    this.sleepMinutes,
    this.sleepDeepMinutes,
    this.sleepRemMinutes,
    this.sleepLightMinutes,
    this.sleepAwakeMinutes,
    this.weightKg,
    this.source = '',
    this.lastSynced,
    this.hourly = const [],
  });

  String get sleepFormatted => formatSleepMinutes(sleepMinutes);

  factory TodayFitnessData.fromJson(Map<String, dynamic> json) {
    final rawHourly = json['hourly'] ?? json['rawHourlyJson'];
    return TodayFitnessData(
      date: json['date']?.toString() ?? '',
      steps: _int(json['steps']),
      calories: _double(json['calories']),
      distanceMeters: _double(json['distanceMeters']),
      heartRateAvg: _double(json['heartRateAvg']),
      heartRateMin: _double(json['heartRateMin']),
      heartRateMax: _double(json['heartRateMax']),
      restingHeartRate: _double(json['restingHeartRate']),
      bloodOxygen: _double(json['bloodOxygen']),
      sleepMinutes: _int(json['sleepMinutes']),
      sleepDeepMinutes: _int(json['sleepDeepMinutes']),
      sleepRemMinutes: _int(json['sleepRemMinutes']),
      sleepLightMinutes: _int(json['sleepLightMinutes']),
      sleepAwakeMinutes: _int(json['sleepAwakeMinutes']),
      weightKg: _double(json['weightKg']),
      source: json['source']?.toString() ?? '',
      lastSynced: json['lastSynced'] != null ? DateTime.tryParse(json['lastSynced'].toString()) : null,
      hourly: rawHourly is List
          ? rawHourly.whereType<Map>().map((e) => HourlyFitnessPoint.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
    );
  }
}

class HourlyFitnessPoint {
  final int hour;
  final int steps;
  final double heartRate;

  HourlyFitnessPoint({
    required this.hour,
    required this.steps,
    required this.heartRate,
  });

  factory HourlyFitnessPoint.fromJson(Map<String, dynamic> json) {
    return HourlyFitnessPoint(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      heartRate: (json['heartRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChartFitnessPoint {
  final String date;
  final int? steps;
  final double? calories;
  final double? distanceMeters;
  final double? heartRateAvg;
  final double? heartRateMin;
  final double? heartRateMax;
  final double? restingHeartRate;
  final double? bloodOxygen;
  final int? sleepMinutes;
  final int? sleepDeepMinutes;
  final int? sleepRemMinutes;
  final int? sleepLightMinutes;
  final int? sleepAwakeMinutes;
  final double? weightKg;
  final List<HourlyFitnessPoint> hourly;

  ChartFitnessPoint({
    required this.date,
    this.steps,
    this.calories,
    this.distanceMeters,
    this.heartRateAvg,
    this.heartRateMin,
    this.heartRateMax,
    this.restingHeartRate,
    this.bloodOxygen,
    this.sleepMinutes,
    this.sleepDeepMinutes,
    this.sleepRemMinutes,
    this.sleepLightMinutes,
    this.sleepAwakeMinutes,
    this.weightKg,
    this.hourly = const [],
  });

  DateTime? get day => DateTime.tryParse(date);

  factory ChartFitnessPoint.fromJson(Map<String, dynamic> json) {
    final rawHourly = json['hourly'] as List<dynamic>? ?? [];
    return ChartFitnessPoint(
      date: json['date']?.toString() ?? '',
      steps: _int(json['steps']),
      calories: _double(json['calories']),
      distanceMeters: _double(json['distanceMeters']),
      heartRateAvg: _double(json['heartRateAvg']),
      heartRateMin: _double(json['heartRateMin']),
      heartRateMax: _double(json['heartRateMax']),
      restingHeartRate: _double(json['restingHeartRate']),
      bloodOxygen: _double(json['bloodOxygen']),
      sleepMinutes: _int(json['sleepMinutes']),
      sleepDeepMinutes: _int(json['sleepDeepMinutes']),
      sleepRemMinutes: _int(json['sleepRemMinutes']),
      sleepLightMinutes: _int(json['sleepLightMinutes']),
      sleepAwakeMinutes: _int(json['sleepAwakeMinutes']),
      weightKg: _double(json['weightKg']),
      hourly: rawHourly.whereType<Map>().map((e) => HourlyFitnessPoint.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class FitnessAnalytics {
  final int stepsAverage;
  final int stepsPeak;
  final int stepsTotal;
  final double caloriesAverage;
  final double caloriesTotal;
  final double distanceTotal;
  final double heartRateAverage;
  final double heartRatePeak;
  final double heartRateMin;
  final double restingHeartRateAverage;
  final int sleepAverageMinutes;
  final int sleepNights;
  final int daysWithData;
  final int previousStepsAverage;
  final int previousSleepAverageMinutes;
  final double previousRestingHeartRateAverage;

  FitnessAnalytics({
    this.stepsAverage = 0,
    this.stepsPeak = 0,
    this.stepsTotal = 0,
    this.caloriesAverage = 0,
    this.caloriesTotal = 0,
    this.distanceTotal = 0,
    this.heartRateAverage = 0,
    this.heartRatePeak = 0,
    this.heartRateMin = 0,
    this.restingHeartRateAverage = 0,
    this.sleepAverageMinutes = 0,
    this.sleepNights = 0,
    this.daysWithData = 0,
    this.previousStepsAverage = 0,
    this.previousSleepAverageMinutes = 0,
    this.previousRestingHeartRateAverage = 0,
  });

  factory FitnessAnalytics.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> part(String key) =>
        json[key] is Map ? Map<String, dynamic>.from(json[key]) : <String, dynamic>{};
    final steps = part('steps');
    final cals = part('calories');
    final distance = part('distance');
    final hr = part('heartRate');
    final sleep = part('sleep');
    final previous = part('previous');
    num n(Map<String, dynamic> m, String k) => (m[k] is num) ? m[k] as num : 0;

    return FitnessAnalytics(
      stepsAverage: n(steps, 'average').toInt(),
      stepsPeak: n(steps, 'peak').toInt(),
      stepsTotal: n(steps, 'total').toInt(),
      caloriesAverage: n(cals, 'average').toDouble(),
      caloriesTotal: n(cals, 'total').toDouble(),
      distanceTotal: n(distance, 'total').toDouble(),
      heartRateAverage: n(hr, 'average').toDouble(),
      heartRatePeak: n(hr, 'peak').toDouble(),
      heartRateMin: n(hr, 'lowest').toDouble(),
      restingHeartRateAverage: n(hr, 'restingAverage').toDouble(),
      sleepAverageMinutes: n(sleep, 'averageMinutes').toInt(),
      sleepNights: n(sleep, 'nights').toInt(),
      daysWithData: (json['daysWithData'] as num?)?.toInt() ?? 0,
      previousStepsAverage: n(previous, 'stepsAverage').toInt(),
      previousSleepAverageMinutes: n(previous, 'sleepAverageMinutes').toInt(),
      previousRestingHeartRateAverage: n(previous, 'restingHeartRateAverage').toDouble(),
    );
  }
}

class PatientFitnessSummaryResponse {
  final String patientId;
  final String period;
  final TodayFitnessData? today;
  final FitnessAnalytics? analytics;
  final List<ChartFitnessPoint> chartPoints;
  final double? latestWeightKg;
  final String? latestWeightDate;
  final double? latestBloodOxygen;
  final String? latestBloodOxygenDate;
  final DateTime? lastSyncedAt;

  PatientFitnessSummaryResponse({
    required this.patientId,
    required this.period,
    this.today,
    this.analytics,
    this.chartPoints = const [],
    this.latestWeightKg,
    this.latestWeightDate,
    this.latestBloodOxygen,
    this.latestBloodOxygenDate,
    this.lastSyncedAt,
  });

  factory PatientFitnessSummaryResponse.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['chartPoints'] as List<dynamic>? ?? [];
    final latest = json['latest'] is Map ? Map<String, dynamic>.from(json['latest']) : <String, dynamic>{};
    return PatientFitnessSummaryResponse(
      patientId: json['patientId']?.toString() ?? '',
      period: json['period']?.toString() ?? 'week',
      today: json['today'] is Map ? TodayFitnessData.fromJson(Map<String, dynamic>.from(json['today'])) : null,
      analytics: json['analytics'] is Map ? FitnessAnalytics.fromJson(Map<String, dynamic>.from(json['analytics'])) : null,
      chartPoints: rawPoints.whereType<Map>().map((e) => ChartFitnessPoint.fromJson(Map<String, dynamic>.from(e))).toList(),
      latestWeightKg: _double(latest['weightKg']),
      latestWeightDate: latest['weightDate']?.toString(),
      latestBloodOxygen: _double(latest['bloodOxygen']),
      latestBloodOxygenDate: latest['bloodOxygenDate']?.toString(),
      lastSyncedAt: json['lastSyncedAt'] != null ? DateTime.tryParse(json['lastSyncedAt'].toString()) : null,
    );
  }
}
