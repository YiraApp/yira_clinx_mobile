class TodayFitnessData {
  final String date;
  final int steps;
  final double calories;
  final double distanceMeters;
  final double heartRateAvg;
  final double heartRateMin;
  final double heartRateMax;
  final double restingHeartRate;
  final double bloodOxygen;
  final int sleepMinutes;
  final String sleepFormatted;
  final double weightKg;
  final String source;
  final DateTime? lastSynced;

  TodayFitnessData({
    required this.date,
    required this.steps,
    required this.calories,
    required this.distanceMeters,
    required this.heartRateAvg,
    required this.heartRateMin,
    required this.heartRateMax,
    required this.restingHeartRate,
    required this.bloodOxygen,
    required this.sleepMinutes,
    required this.sleepFormatted,
    required this.weightKg,
    required this.source,
    this.lastSynced,
  });

  factory TodayFitnessData.fromJson(Map<String, dynamic> json) {
    return TodayFitnessData(
      date: json['date']?.toString() ?? '',
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      heartRateAvg: (json['heartRateAvg'] as num?)?.toDouble() ?? 0.0,
      heartRateMin: (json['heartRateMin'] as num?)?.toDouble() ?? 0.0,
      heartRateMax: (json['heartRateMax'] as num?)?.toDouble() ?? 0.0,
      restingHeartRate: (json['restingHeartRate'] as num?)?.toDouble() ?? 0.0,
      bloodOxygen: (json['bloodOxygen'] as num?)?.toDouble() ?? 0.0,
      sleepMinutes: (json['sleepMinutes'] as num?)?.toInt() ?? 0,
      sleepFormatted: json['sleepFormatted']?.toString() ?? '0h 0m',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      source: json['source']?.toString() ?? 'AppleHealth',
      lastSynced: json['lastSynced'] != null ? DateTime.tryParse(json['lastSynced'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'steps': steps,
      'calories': calories,
      'distanceMeters': distanceMeters,
      'heartRateAvg': heartRateAvg,
      'heartRateMin': heartRateMin,
      'heartRateMax': heartRateMax,
      'restingHeartRate': restingHeartRate,
      'bloodOxygen': bloodOxygen,
      'sleepMinutes': sleepMinutes,
      'sleepFormatted': sleepFormatted,
      'weightKg': weightKg,
      'source': source,
      'lastSynced': lastSynced?.toIso8601String(),
    };
  }
}

class HourlyFitnessPoint {
  final int hour;
  final int steps;
  final double heartRate;
  final double calories;

  HourlyFitnessPoint({
    required this.hour,
    required this.steps,
    required this.heartRate,
    required this.calories,
  });

  factory HourlyFitnessPoint.fromJson(Map<String, dynamic> json) {
    return HourlyFitnessPoint(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      heartRate: (json['heartRate'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'steps': steps,
    'heartRate': heartRate,
    'calories': calories,
  };
}

class ChartFitnessPoint {
  final String date;
  final int steps;
  final double calories;
  final double distanceMeters;
  final double heartRateAvg;
  final double heartRateMin;
  final double heartRateMax;
  final double bloodOxygen;
  final int sleepMinutes;
  final double weightKg;
  final List<HourlyFitnessPoint> hourly;

  ChartFitnessPoint({
    required this.date,
    required this.steps,
    required this.calories,
    required this.distanceMeters,
    required this.heartRateAvg,
    required this.heartRateMin,
    required this.heartRateMax,
    required this.bloodOxygen,
    required this.sleepMinutes,
    required this.weightKg,
    this.hourly = const [],
  });

  factory ChartFitnessPoint.fromJson(Map<String, dynamic> json) {
    final rawHourly = json['hourly'] as List<dynamic>? ?? [];
    return ChartFitnessPoint(
      date: json['date']?.toString() ?? '',
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      heartRateAvg: (json['heartRateAvg'] as num?)?.toDouble() ?? 0.0,
      heartRateMin: (json['heartRateMin'] as num?)?.toDouble() ?? 0.0,
      heartRateMax: (json['heartRateMax'] as num?)?.toDouble() ?? 0.0,
      bloodOxygen: (json['bloodOxygen'] as num?)?.toDouble() ?? 0.0,
      sleepMinutes: (json['sleepMinutes'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      hourly: rawHourly.map((e) => HourlyFitnessPoint.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'steps': steps,
    'calories': calories,
    'distanceMeters': distanceMeters,
    'heartRateAvg': heartRateAvg,
    'heartRateMin': heartRateMin,
    'heartRateMax': heartRateMax,
    'bloodOxygen': bloodOxygen,
    'sleepMinutes': sleepMinutes,
    'weightKg': weightKg,
    'hourly': hourly.map((e) => e.toJson()).toList(),
  };
}

class FitnessAnalytics {
  final int stepsAverage;
  final int stepsPeak;
  final int stepsTotal;

  final double caloriesAverage;
  final double caloriesPeak;
  final double caloriesTotal;

  final double heartRateAverage;
  final double heartRatePeak;
  final double heartRateMin;

  final int sleepAverageMinutes;
  final int sleepTotalMinutes;
  final String sleepAverageFormatted;

  FitnessAnalytics({
    required this.stepsAverage,
    required this.stepsPeak,
    required this.stepsTotal,
    required this.caloriesAverage,
    required this.caloriesPeak,
    required this.caloriesTotal,
    required this.heartRateAverage,
    required this.heartRatePeak,
    required this.heartRateMin,
    required this.sleepAverageMinutes,
    required this.sleepTotalMinutes,
    required this.sleepAverageFormatted,
  });

  factory FitnessAnalytics.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'] as Map<String, dynamic>? ?? {};
    final calsJson = json['calories'] as Map<String, dynamic>? ?? {};
    final hrJson = json['heartRate'] as Map<String, dynamic>? ?? {};
    final sleepJson = json['sleep'] as Map<String, dynamic>? ?? {};

    return FitnessAnalytics(
      stepsAverage: (stepsJson['average'] as num?)?.toInt() ?? 0,
      stepsPeak: (stepsJson['peak'] as num?)?.toInt() ?? 0,
      stepsTotal: (stepsJson['total'] as num?)?.toInt() ?? 0,
      caloriesAverage: (calsJson['average'] as num?)?.toDouble() ?? 0.0,
      caloriesPeak: (calsJson['peak'] as num?)?.toDouble() ?? 0.0,
      caloriesTotal: (calsJson['total'] as num?)?.toDouble() ?? 0.0,
      heartRateAverage: (hrJson['average'] as num?)?.toDouble() ?? 0.0,
      heartRatePeak: (hrJson['peak'] as num?)?.toDouble() ?? 0.0,
      heartRateMin: (hrJson['lowest'] as num?)?.toDouble() ?? 0.0,
      sleepAverageMinutes: (sleepJson['averageMinutes'] as num?)?.toInt() ?? 0,
      sleepTotalMinutes: (sleepJson['totalMinutes'] as num?)?.toInt() ?? 0,
      sleepAverageFormatted: sleepJson['averageHoursFormatted']?.toString() ?? '0h 0m',
    );
  }
}

class PatientFitnessSummaryResponse {
  final String patientId;
  final String period;
  final TodayFitnessData? today;
  final FitnessAnalytics? analytics;
  final List<ChartFitnessPoint> chartPoints;

  PatientFitnessSummaryResponse({
    required this.patientId,
    required this.period,
    this.today,
    this.analytics,
    this.chartPoints = const [],
  });

  factory PatientFitnessSummaryResponse.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['chartPoints'] as List<dynamic>? ?? [];
    return PatientFitnessSummaryResponse(
      patientId: json['patientId']?.toString() ?? '',
      period: json['period']?.toString() ?? 'week',
      today: json['today'] != null ? TodayFitnessData.fromJson(Map<String, dynamic>.from(json['today'])) : null,
      analytics: json['analytics'] != null ? FitnessAnalytics.fromJson(Map<String, dynamic>.from(json['analytics'])) : null,
      chartPoints: rawPoints.map((e) => ChartFitnessPoint.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
