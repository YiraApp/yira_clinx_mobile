import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

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

  /// Supported health data types for iOS & Android
  List<HealthDataType> get supportedTypes {
    if (Platform.isIOS) {
      return [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.WATER,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      ];
    } else {
      // Android Google Health Connect
      return [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.NUTRITION,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_SESSION,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.WATER,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      ];
    }
  }

  /// Core types that are essential for primary fitness tracking
  List<HealthDataType> get coreTypes {
    if (Platform.isIOS) {
      return [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.SLEEP_ASLEEP,
      ];
    } else {
      return [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.SLEEP_ASLEEP,
      ];
    }
  }

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

  /// Check if user has already granted health permissions
  Future<bool> hasPermissions() async {
    await configure();
    try {
      if (Platform.isIOS) {
        // On iOS, verify whether any core metrics have write permissions granted
        final hasSteps = await _health.hasPermissions(
          [HealthDataType.STEPS],
          permissions: [HealthDataAccess.WRITE],
        );
        final hasHeart = await _health.hasPermissions(
          [HealthDataType.HEART_RATE],
          permissions: [HealthDataAccess.WRITE],
        );
        final hasEnergy = await _health.hasPermissions(
          [HealthDataType.ACTIVE_ENERGY_BURNED],
          permissions: [HealthDataAccess.WRITE],
        );
        return (hasSteps == true) || (hasHeart == true) || (hasEnergy == true);
      } else {
        // On Android Health Connect, check individual core metrics so that if the user granted
        // Steps, Heart Rate, Calories, Distance, etc., the app recognizes authorization correctly
        // rather than failing due to containsAll on ungranted optional types.
        final typesToCheck = [
          HealthDataType.STEPS,
          HealthDataType.HEART_RATE,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.TOTAL_CALORIES_BURNED,
          HealthDataType.WORKOUT,
          HealthDataType.DISTANCE_DELTA,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.BLOOD_OXYGEN,
          HealthDataType.WEIGHT,
        ];
        for (final t in typesToCheck) {
          try {
            final has = await _health.hasPermissions([t], permissions: [HealthDataAccess.READ]);
            if (has == true) return true;
          } catch (_) {}
        }
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ [FitnessService] Error checking permissions: $e');
      return false;
    }
  }

  /// Request authorization from user for all supported health data types
  Future<bool> requestPermissions() async {
    await configure();
    try {
      final types = supportedTypes;
      List<HealthDataAccess> permissions;
      if (Platform.isIOS) {
        // Types in HealthKit that support both read and write
        const writeableTypes = {
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.HEART_RATE,
          HealthDataType.DISTANCE_WALKING_RUNNING,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.WEIGHT,
          HealthDataType.HEIGHT,
          HealthDataType.WATER,
          HealthDataType.BLOOD_OXYGEN,
        };

        permissions = types.map((t) {
          if (writeableTypes.contains(t)) {
            return HealthDataAccess.READ_WRITE;
          }
          return HealthDataAccess.READ;
        }).toList();
      } else {
        permissions = List.filled(types.length, HealthDataAccess.READ);
      }

      final granted = await _health.requestAuthorization(types, permissions: permissions);
      // On Android Health Connect, requestAuthorization may return true or false depending
      // on whether all or partial permissions were granted. Verify if any core permission is granted.
      final verified = await hasPermissions();
      return granted || verified;
    } catch (e) {
      debugPrint('⚠️ [FitnessService] Error requesting health permissions: $e');
      return await hasPermissions();
    }
  }

  /// Fetch today's aggregated fitness metrics (midnight to now)
  Future<Map<String, dynamic>> fetchTodayMetrics() async {
    await configure();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    int totalSteps = 0;
    double totalCalories = 0.0;
    double totalDistance = 0.0;
    double latestHeartRate = 0.0;
    double avgHeartRate = 0.0;
    double minHeartRate = 0.0;
    double maxHeartRate = 0.0;
    double bloodOxygen = 0.0;
    int sleepMinutes = 0;
    double weightKg = 0.0;

    // 1. Step count
    try {
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      totalSteps = steps ?? 0;
    } catch (e) {
      debugPrint('⚠️ [FitnessService] Error reading steps: $e');
    }

    // 2. Query all health data points for today
    int sleepStagesMinutes = 0;
    int sleepSessionMinutes = 0;

    try {
      final cleanPoints = await _safeGetHealthData(
        startTime: midnight,
        endTime: now,
        types: supportedTypes,
      );

      final List<double> hrValues = [];
      int stepsFromPoints = 0;
      double activeCalories = 0.0;
      double totalCaloriesFromPoints = 0.0;
      double workoutCalories = 0.0;
      double basalCalories = 0.0;

      for (final point in cleanPoints) {
        final val = _extractNumericValue(point.value);

        switch (point.type) {
          case HealthDataType.STEPS:
            stepsFromPoints += val.toInt();
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            activeCalories += val;
            break;
          case HealthDataType.TOTAL_CALORIES_BURNED:
            totalCaloriesFromPoints += val;
            break;
          case HealthDataType.BASAL_ENERGY_BURNED:
            basalCalories += val;
            break;
          case HealthDataType.WORKOUT:
            if (point.value is WorkoutHealthValue) {
              final w = point.value as WorkoutHealthValue;
              if (w.totalEnergyBurned != null && w.totalEnergyBurned! > 0) {
                workoutCalories += w.totalEnergyBurned!.toDouble();
              }
              if (w.totalSteps != null && w.totalSteps! > 0) {
                stepsFromPoints += w.totalSteps!;
              }
              if (w.totalDistance != null && w.totalDistance! > 0) {
                totalDistance += w.totalDistance!.toDouble();
              }
            } else if (val > 0) {
              workoutCalories += val;
            }
            break;
          case HealthDataType.DISTANCE_WALKING_RUNNING:
          case HealthDataType.DISTANCE_DELTA:
            totalDistance += val;
            break;
          case HealthDataType.HEART_RATE:
            if (val > 0) hrValues.add(val);
            break;
          case HealthDataType.BLOOD_OXYGEN:
            if (val > 0) bloodOxygen = val;
            break;
          case HealthDataType.WEIGHT:
            if (val > 0) weightKg = val;
            break;
          case HealthDataType.SLEEP_ASLEEP:
          case HealthDataType.SLEEP_DEEP:
          case HealthDataType.SLEEP_REM:
          case HealthDataType.SLEEP_LIGHT:
            sleepStagesMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
            break;
          case HealthDataType.SLEEP_SESSION:
            sleepSessionMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
            break;
          default:
            break;
        }
      }

      sleepMinutes = sleepStagesMinutes > 0 ? sleepStagesMinutes : sleepSessionMinutes;

      // Compute total calories without double counting
      if (totalCaloriesFromPoints > 0) {
        final maxActive = math.max(activeCalories, workoutCalories);
        totalCalories = math.max(totalCaloriesFromPoints, maxActive);
      } else if (activeCalories > 0 && workoutCalories > 0) {
        totalCalories = math.max(activeCalories, workoutCalories);
      } else if (activeCalories > 0) {
        totalCalories = activeCalories;
      } else if (workoutCalories > 0) {
        totalCalories = workoutCalories;
      } else if (basalCalories > 0) {
        totalCalories = basalCalories;
      }

      if (totalSteps == 0 && stepsFromPoints > 0) {
        totalSteps = stepsFromPoints;
      }

      if (totalCalories == 0 && totalSteps > 0) {
        totalCalories = totalSteps * 0.04;
      }

      if (hrValues.isNotEmpty) {
        latestHeartRate = hrValues.last;
        avgHeartRate = hrValues.reduce((a, b) => a + b) / hrValues.length;
        minHeartRate = hrValues.reduce((a, b) => a < b ? a : b);
        maxHeartRate = hrValues.reduce((a, b) => a > b ? a : b);
      }
    } catch (e) {
      debugPrint('⚠️ [FitnessService] Error reading today points: $e');
    }

    // Weight fallback: if weight wasn't logged today, fetch latest from past 30 days
    if (weightKg == 0) {
      try {
        final monthAgo = midnight.subtract(const Duration(days: 30));
        final weightPoints = await _safeGetHealthData(
          startTime: monthAgo,
          endTime: now,
          types: [HealthDataType.WEIGHT],
        );
        if (weightPoints.isNotEmpty) {
          weightPoints.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
          final lastW = _extractNumericValue(weightPoints.last.value);
          if (lastW > 0) weightKg = lastW;
        }
      } catch (_) {}
    }

    // If sleep data for today was 0, check last night's window (8 PM yesterday to noon today)
    if (sleepMinutes == 0) {
      try {
        final yesterdayEvening = midnight.subtract(const Duration(hours: 4));
        final sleepPoints = await _safeGetHealthData(
          startTime: yesterdayEvening,
          endTime: now,
          types: [
            HealthDataType.SLEEP_ASLEEP,
            HealthDataType.SLEEP_DEEP,
            HealthDataType.SLEEP_REM,
            HealthDataType.SLEEP_LIGHT,
            HealthDataType.SLEEP_SESSION,
          ],
        );
        int fallbackStages = 0;
        int fallbackSession = 0;
        for (final p in sleepPoints) {
          if (p.type == HealthDataType.SLEEP_SESSION) {
            fallbackSession += p.dateTo.difference(p.dateFrom).inMinutes;
          } else {
            fallbackStages += p.dateTo.difference(p.dateFrom).inMinutes;
          }
        }
        sleepMinutes = fallbackStages > 0 ? fallbackStages : fallbackSession;
      } catch (_) {}
    }

    final dateStr = now.toIso8601String().split('T')[0];
    final sleepHours = sleepMinutes ~/ 60;
    final sleepMins = sleepMinutes % 60;

    return {
      'date': dateStr,
      'steps': totalSteps,
      'calories': double.parse(totalCalories.toStringAsFixed(1)),
      'distanceMeters': double.parse(totalDistance.toStringAsFixed(1)),
      'heartRateAvg': double.parse(avgHeartRate.toStringAsFixed(1)),
      'heartRateMin': double.parse(minHeartRate.toStringAsFixed(1)),
      'heartRateMax': double.parse(maxHeartRate.toStringAsFixed(1)),
      'restingHeartRate': double.parse(latestHeartRate.toStringAsFixed(1)),
      'bloodOxygen': double.parse(bloodOxygen.toStringAsFixed(1)),
      'sleepMinutes': sleepMinutes,
      'sleepFormatted': '${sleepHours}h ${sleepMins}m',
      'weightKg': double.parse(weightKg.toStringAsFixed(1)),
      'source': platformSourceName,
      'lastSynced': DateTime.now().toIso8601String(),
    };
  }

  /// Fetch past N days of daily aggregates to sync with backend.
  /// Queries in a single batch over the entire window to avoid Android Health Connect
  /// IPC rate-limiting and timeouts.
  Future<List<Map<String, dynamic>>> fetchHistoricalBatch({int days = 30}) async {
    await configure();
    final List<Map<String, dynamic>> records = [];
    final now = DateTime.now();

    // Query in ONE single batch from start of history window to now
    final earliestDate = now.subtract(Duration(days: days));
    final rangeStart = DateTime(earliestDate.year, earliestDate.month, earliestDate.day, 0, 0, 0);

    List<HealthDataPoint> allPoints = [];
    try {
      allPoints = await _safeGetHealthData(
        startTime: rangeStart,
        endTime: now,
        types: supportedTypes,
      );
    } catch (e) {
      debugPrint('⚠️ [FitnessService] Error reading batch health points: $e');
    }

    // Group health points by local calendar date "YYYY-MM-DD"
    final Map<String, List<HealthDataPoint>> pointsByDate = {};
    for (final p in allPoints) {
      final dateKey =
          "${p.dateFrom.year.toString().padLeft(4, '0')}-${p.dateFrom.month.toString().padLeft(2, '0')}-${p.dateFrom.day.toString().padLeft(2, '0')}";
      pointsByDate.putIfAbsent(dateKey, () => []).add(p);
    }

    // Direct aggregated steps for today if available
    int todayAggregatedSteps = 0;
    try {
      final midnight = DateTime(now.year, now.month, now.day);
      final s = await _health.getTotalStepsInInterval(midnight, now);
      todayAggregatedSteps = s ?? 0;
    } catch (_) {}

    for (int i = 0; i < days; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final dateStr =
          "${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      final dayPoints = pointsByDate[dateStr] ?? [];

      int steps = 0;
      double activeCalories = 0.0;
      double totalCaloriesFromPoints = 0.0;
      double workoutCalories = 0.0;
      double basalCalories = 0.0;
      double distance = 0.0;
      final List<double> hrs = [];
      double spO2 = 0.0;
      int sleepStages = 0;
      int sleepSession = 0;
      double weight = 0.0;

      for (final p in dayPoints) {
        final val = _extractNumericValue(p.value);
        switch (p.type) {
          case HealthDataType.STEPS:
            steps += val.toInt();
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            activeCalories += val;
            break;
          case HealthDataType.TOTAL_CALORIES_BURNED:
            totalCaloriesFromPoints += val;
            break;
          case HealthDataType.BASAL_ENERGY_BURNED:
            basalCalories += val;
            break;
          case HealthDataType.WORKOUT:
            if (p.value is WorkoutHealthValue) {
              final w = p.value as WorkoutHealthValue;
              if (w.totalEnergyBurned != null && w.totalEnergyBurned! > 0) {
                workoutCalories += w.totalEnergyBurned!.toDouble();
              }
              if (w.totalSteps != null && w.totalSteps! > 0) {
                steps += w.totalSteps!;
              }
              if (w.totalDistance != null && w.totalDistance! > 0) {
                distance += w.totalDistance!.toDouble();
              }
            } else if (val > 0) {
              workoutCalories += val;
            }
            break;
          case HealthDataType.DISTANCE_WALKING_RUNNING:
          case HealthDataType.DISTANCE_DELTA:
            distance += val;
            break;
          case HealthDataType.HEART_RATE:
            if (val > 0) hrs.add(val);
            break;
          case HealthDataType.BLOOD_OXYGEN:
            if (val > 0) spO2 = val;
            break;
          case HealthDataType.WEIGHT:
            if (val > 0) weight = val;
            break;
          case HealthDataType.SLEEP_ASLEEP:
          case HealthDataType.SLEEP_DEEP:
          case HealthDataType.SLEEP_REM:
          case HealthDataType.SLEEP_LIGHT:
            sleepStages += p.dateTo.difference(p.dateFrom).inMinutes;
            break;
          case HealthDataType.SLEEP_SESSION:
            sleepSession += p.dateTo.difference(p.dateFrom).inMinutes;
            break;
          default:
            break;
        }
      }

      final daySleep = sleepStages > 0 ? sleepStages : sleepSession;

      double dayCalories = 0.0;
      if (totalCaloriesFromPoints > 0) {
        final maxActive = math.max(activeCalories, workoutCalories);
        dayCalories = math.max(totalCaloriesFromPoints, maxActive);
      } else if (activeCalories > 0 && workoutCalories > 0) {
        dayCalories = math.max(activeCalories, workoutCalories);
      } else if (activeCalories > 0) {
        dayCalories = activeCalories;
      } else if (workoutCalories > 0) {
        dayCalories = workoutCalories;
      } else if (basalCalories > 0) {
        dayCalories = basalCalories;
      }

      // Today preference: use native interval aggregation if higher
      if (i == 0 && todayAggregatedSteps > steps) {
        steps = todayAggregatedSteps;
      }

      // For recent 7 days, if point steps is 0, attempt interval query fallback
      if (steps == 0 && i < 7) {
        try {
          final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
          final dayEnd = i == 0 ? now : DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
          final stepCount = await _health.getTotalStepsInInterval(dayStart, dayEnd);
          if (stepCount != null && stepCount > 0) {
            steps = stepCount;
          }
        } catch (_) {}
      }

      if (dayCalories == 0 && steps > 0) {
        dayCalories = steps * 0.04;
      }

      double avgHr = 0.0;
      double minHr = 0.0;
      double maxHr = 0.0;
      if (hrs.isNotEmpty) {
        avgHr = hrs.reduce((a, b) => a + b) / hrs.length;
        minHr = hrs.reduce((a, b) => a < b ? a : b);
        maxHr = hrs.reduce((a, b) => a > b ? a : b);
      }

      records.add({
        'date': dateStr,
        'steps': steps,
        'calories': double.parse(dayCalories.toStringAsFixed(1)),
        'distanceMeters': double.parse(distance.toStringAsFixed(1)),
        'heartRateAvg': double.parse(avgHr.toStringAsFixed(1)),
        'heartRateMin': double.parse(minHr.toStringAsFixed(1)),
        'heartRateMax': double.parse(maxHr.toStringAsFixed(1)),
        'bloodOxygen': double.parse(spO2.toStringAsFixed(1)),
        'sleepMinutes': daySleep,
        'weightKg': double.parse(weight.toStringAsFixed(1)),
        'source': platformSourceName,
      });
    }

    return records;
  }

  /// Safely extracts numeric value from generic HealthValue
  double _extractNumericValue(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    } else if (value is WorkoutHealthValue) {
      return (value.totalEnergyBurned ?? 0).toDouble();
    } else if (value is NutritionHealthValue) {
      return (value.calories ?? 0).toDouble();
    }
    return 0.0;
  }

  /// Safely queries health data points per type.
  /// If any single data type fails (e.g. permission ungranted, or device sensor missing),
  /// it gracefully skips it without aborting the other metrics.
  Future<List<HealthDataPoint>> _safeGetHealthData({
    required DateTime startTime,
    required DateTime endTime,
    required List<HealthDataType> types,
  }) async {
    final List<HealthDataPoint> allPoints = [];
    for (final type in types) {
      try {
        final pts = await _health.getHealthDataFromTypes(
          startTime: startTime,
          endTime: endTime,
          types: [type],
        );
        allPoints.addAll(pts);
      } catch (e) {
        debugPrint('⚠️ [FitnessService] Skipping unsupported/denied type $type: $e');
      }
    }
    return _health.removeDuplicates(allPoints);
  }
}
