import 'dart:io';
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
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_DELTA,
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
    }
  }

  /// Core types that are essential for primary fitness tracking
  List<HealthDataType> get coreTypes {
    if (Platform.isIOS) {
      return [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.SLEEP_ASLEEP,
      ];
    } else {
      return [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
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
        final permissions = List.filled(coreTypes.length, HealthDataAccess.READ);
        final hasGranted = await _health.hasPermissions(coreTypes, permissions: permissions);
        return hasGranted ?? false;
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
      if (!granted) return false;

      // Check whether user actually allowed permissions
      final verified = await hasPermissions();
      return verified;
    } catch (e) {
      debugPrint('⚠️ [FitnessService] Error requesting health permissions: $e');
      rethrow;
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
    try {
      final dataPoints = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: supportedTypes,
      );

      final cleanPoints = _health.removeDuplicates(dataPoints);

      final List<double> hrValues = [];

      for (final point in cleanPoints) {
        final val = _extractNumericValue(point.value);

        switch (point.type) {
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            totalCalories += val;
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
            sleepMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
            break;
          default:
            break;
        }
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

    // If sleep data for today was 0, check last night's window (8 PM yesterday to noon today)
    if (sleepMinutes == 0) {
      try {
        final yesterdayEvening = midnight.subtract(const Duration(hours: 4));
        final sleepPoints = await _health.getHealthDataFromTypes(
          startTime: yesterdayEvening,
          endTime: now,
          types: [
            HealthDataType.SLEEP_ASLEEP,
            HealthDataType.SLEEP_DEEP,
            HealthDataType.SLEEP_REM,
            HealthDataType.SLEEP_LIGHT,
          ],
        );
        final cleanSleep = _health.removeDuplicates(sleepPoints);
        for (final p in cleanSleep) {
          sleepMinutes += p.dateTo.difference(p.dateFrom).inMinutes;
        }
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

  /// Fetch past N days of daily aggregates to sync with backend
  Future<List<Map<String, dynamic>>> fetchHistoricalBatch({int days = 30}) async {
    await configure();
    final List<Map<String, dynamic>> records = [];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
      final dayEnd = i == 0 ? now : DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

      int steps = 0;
      double calories = 0.0;
      double distance = 0.0;
      double avgHr = 0.0;
      double minHr = 0.0;
      double maxHr = 0.0;
      double spO2 = 0.0;
      int sleep = 0;
      double weight = 0.0;

      try {
        final stepCount = await _health.getTotalStepsInInterval(dayStart, dayEnd);
        steps = stepCount ?? 0;
      } catch (_) {}

      try {
        final points = await _health.getHealthDataFromTypes(
          startTime: dayStart,
          endTime: dayEnd,
          types: supportedTypes,
        );

        final cleanPoints = _health.removeDuplicates(points);
        final List<double> hrs = [];

        for (final p in cleanPoints) {
          final val = _extractNumericValue(p.value);
          if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) calories += val;
          if (p.type == HealthDataType.DISTANCE_WALKING_RUNNING || p.type == HealthDataType.DISTANCE_DELTA) distance += val;
          if (p.type == HealthDataType.HEART_RATE && val > 0) hrs.add(val);
          if (p.type == HealthDataType.BLOOD_OXYGEN && val > 0) spO2 = val;
          if (p.type == HealthDataType.WEIGHT && val > 0) weight = val;
          if (p.type == HealthDataType.SLEEP_ASLEEP || p.type == HealthDataType.SLEEP_DEEP || p.type == HealthDataType.SLEEP_REM) {
            sleep += p.dateTo.difference(p.dateFrom).inMinutes;
          }
        }

        if (hrs.isNotEmpty) {
          avgHr = hrs.reduce((a, b) => a + b) / hrs.length;
          minHr = hrs.reduce((a, b) => a < b ? a : b);
          maxHr = hrs.reduce((a, b) => a > b ? a : b);
        }
      } catch (_) {}

      final dateStr = targetDate.toIso8601String().split('T')[0];
      records.add({
        'date': dateStr,
        'steps': steps,
        'calories': double.parse(calories.toStringAsFixed(1)),
        'distanceMeters': double.parse(distance.toStringAsFixed(1)),
        'heartRateAvg': double.parse(avgHr.toStringAsFixed(1)),
        'heartRateMin': double.parse(minHr.toStringAsFixed(1)),
        'heartRateMax': double.parse(maxHr.toStringAsFixed(1)),
        'bloodOxygen': double.parse(spO2.toStringAsFixed(1)),
        'sleepMinutes': sleep,
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
    }
    return 0.0;
  }
}
