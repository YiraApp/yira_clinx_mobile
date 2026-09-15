import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/local/global_session.dart';
import '../../../core/urls/urls.dart';
import '../../../features/data/models/fitness/patient_fitness_model.dart';
import 'fitness_service.dart';

enum FitnessConnectStatus {
  success,
  missingPlugin,
  healthConnectRequired,
  permissionDenied,
  error,
}

class FitnessConnectResult {
  final FitnessConnectStatus status;
  final String title;
  final String message;

  const FitnessConnectResult({
    required this.status,
    required this.title,
    required this.message,
  });

  bool get isSuccess => status == FitnessConnectStatus.success;
}

class FitnessSyncService {
  FitnessSyncService._();
  static final FitnessSyncService instance = FitnessSyncService._();

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<TodayFitnessData?> todayFitnessNotifier = ValueNotifier<TodayFitnessData?>(null);

  bool _isInitialized = false;

  /// Initialize and load cached data
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await loadCachedStatus();

    // Auto-sync silently if user is connected
    if (isConnectedNotifier.value) {
      syncNow(silent: true);
    }
  }

  /// Check whether fitness permissions are granted and connected
  Future<bool> checkIsConnected() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      final prefs = await SharedPreferences.getInstance();

      bool connected = false;
      if (userId.isNotEmpty) {
        connected = prefs.getBool('fitness_connected_$userId') ?? false;
      }
      if (!connected) {
        connected = prefs.getBool('fitness_connected_default') ?? false;
      }

      // If user was previously connected, check if they revoked permissions
      if (connected) {
        final hasPerms = await FitnessService.instance.hasPermissions();
        if (!hasPerms) {
          connected = false;
          if (userId.isNotEmpty) {
            await prefs.setBool('fitness_connected_$userId', false);
          }
          await prefs.setBool('fitness_connected_default', false);
        }
      }

      isConnectedNotifier.value = connected;
      return connected;
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Error checking isConnected: $e');
      return isConnectedNotifier.value;
    }
  }

  /// Load cached fitness connection flag & today metrics from SharedPreferences
  Future<void> loadCachedStatus() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';

      final prefs = await SharedPreferences.getInstance();
      bool isConnected = false;
      if (userId.isNotEmpty) {
        isConnected = prefs.getBool('fitness_connected_$userId') ?? false;
      }
      if (!isConnected) {
        isConnected = prefs.getBool('fitness_connected_default') ?? false;
      }

      // If flag is true, verify user hasn't revoked permissions in device settings
      if (isConnected) {
        final hasPerms = await FitnessService.instance.hasPermissions();
        if (!hasPerms) {
          isConnected = false;
          if (userId.isNotEmpty) {
            await prefs.setBool('fitness_connected_$userId', false);
          }
          await prefs.setBool('fitness_connected_default', false);
        }
      }

      isConnectedNotifier.value = isConnected;

      final key = userId.isNotEmpty ? 'fitness_today_cached_$userId' : 'fitness_today_cached_default';
      final cachedTodayStr = prefs.getString(key);
      if (cachedTodayStr != null && cachedTodayStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cachedTodayStr);
        todayFitnessNotifier.value = TodayFitnessData.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Error loading cached status: $e');
    }
  }

  /// One-tap Connect Fitness flow
  Future<FitnessConnectResult> connectFitness() async {
    try {
      if (Platform.isAndroid) {
        try {
          final isAvailable = await FitnessService.instance.isHealthConnectAvailable();
          if (!isAvailable) {
            await FitnessService.instance.promptInstallHealthConnect();
            return const FitnessConnectResult(
              status: FitnessConnectStatus.healthConnectRequired,
              title: 'Health Connect Required',
              message: 'Google Health Connect is required to sync your fitness data. Please install it from Google Play Store.',
            );
          }
        } catch (e) {
          final err = e.toString();
          if (err.contains('MissingPluginException') || err.contains('No implementation found')) {
            return const FitnessConnectResult(
              status: FitnessConnectStatus.missingPlugin,
              title: 'App Rebuild Required',
              message: 'The native Health library was newly added to the project. Please stop and re-run the app (flutter run) to link native Health Connect.',
            );
          }
        }
      }

      final granted = await FitnessService.instance.requestPermissions();
      if (granted) {
        final currentUser = GlobalSession.instance.userNotifier.value;
        final userId = currentUser?.data?.id ?? '';
        final prefs = await SharedPreferences.getInstance();
        if (userId.isNotEmpty) {
          await prefs.setBool('fitness_connected_$userId', true);
        }
        await prefs.setBool('fitness_connected_default', true);
        isConnectedNotifier.value = true;

        // Immediately sync recent 30 days of data
        await syncNow(silent: false, days: 30);
        return const FitnessConnectResult(
          status: FitnessConnectStatus.success,
          title: 'Connected',
          message: 'Fitness sensors connected successfully.',
        );
      }

      // Explicitly ensure disconnected status is stored
      isConnectedNotifier.value = false;
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      final prefs = await SharedPreferences.getInstance();
      if (userId.isNotEmpty) {
        await prefs.setBool('fitness_connected_$userId', false);
      }
      await prefs.setBool('fitness_connected_default', false);

      return FitnessConnectResult(
        status: FitnessConnectStatus.permissionDenied,
        title: 'Permission Required',
        message: Platform.isIOS
            ? 'Apple Health access was not granted. Please open Settings > Health > Data Access & Devices > Yira Clinics and turn on permissions.'
            : 'Health Connect access was not granted. Please open Settings and enable permissions.',
      );
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Connect fitness error: $e');
      final err = e.toString();
      if (err.contains('MissingPluginException') || err.contains('No implementation found')) {
        return const FitnessConnectResult(
          status: FitnessConnectStatus.missingPlugin,
          title: 'App Rebuild Required',
          message: 'The native HealthKit / Health Connect library was newly added to the project.\n\nFlutter hot reload cannot link new native code. Please stop the app and rebuild/run it (flutter run) to enable native health sensors.',
        );
      }
      return FitnessConnectResult(
        status: FitnessConnectStatus.error,
        title: 'Connection Error',
        message: 'Could not connect fitness sensors: $e',
      );
    }
  }

  /// Disconnect fitness flow
  Future<void> disconnectFitness() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      final token = currentUser?.data?.accessToken ?? '';

      final prefs = await SharedPreferences.getInstance();
      if (userId.isNotEmpty) {
        await prefs.setBool('fitness_connected_$userId', false);
        await prefs.remove('fitness_today_cached_$userId');
      }
      await prefs.setBool('fitness_connected_default', false);
      await prefs.remove('fitness_today_cached_default');
      isConnectedNotifier.value = false;
      todayFitnessNotifier.value = null;

      // Notify backend
      if (userId.isNotEmpty && token.isNotEmpty) {
        try {
          final client = ApiClient();
          await client.account(showSuccessSnack: false).post(
            URLs.patientFitnessDisconnectUrl,
            data: {'patientId': userId},
            options: Options(
              headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
            ),
          );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Disconnect error: $e');
    }
  }

  /// Synchronize health data between device sensors and the backend MSSQL database
  Future<void> syncNow({bool silent = false, int days = 30}) async {
    if (isSyncingNotifier.value) return;

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final token = currentUser?.data?.accessToken ?? '';

    if (userId.isEmpty) return;

    try {
      if (!silent) isSyncingNotifier.value = true;

      // 1. Fetch today's metrics from native store
      final todayMap = await FitnessService.instance.fetchTodayMetrics();
      final todayData = TodayFitnessData.fromJson(todayMap);
      todayFitnessNotifier.value = todayData;

      // Cache locally immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fitness_today_cached_$userId', jsonEncode(todayMap));

      // 2. Fetch recent historical batch
      final batchRecords = await FitnessService.instance.fetchHistoricalBatch(days: days);

      // 3. Push to backend MSSQL database via REST
      if (token.isNotEmpty && batchRecords.isNotEmpty) {
        final client = ApiClient();
        final response = await client.account(showSuccessSnack: false).post(
          URLs.patientFitnessSyncUrl,
          data: {
            'patientId': userId,
            'source': FitnessService.instance.platformSourceName,
            'records': batchRecords,
          },
          options: Options(
            headers: {
              HttpHeaders.authorizationHeader: 'Bearer $token',
            },
          ),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('✅ [FitnessSyncService] Successfully synced ${batchRecords.length} days to database');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Sync error: $e');
    } finally {
      if (!silent) isSyncingNotifier.value = false;
    }
  }

  /// Retrieve summary and chart trends from backend database
  Future<PatientFitnessSummaryResponse?> fetchSummaryFromBackend({String period = 'week'}) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final token = currentUser?.data?.accessToken ?? '';

    if (userId.isEmpty) return null;

    try {
      final client = ApiClient();
      final response = await client.account(showSuccessSnack: false).get(
        URLs.patientFitnessSummaryUrl,
        queryParameters: {
          'patientId': userId,
          'period': period,
        },
        options: Options(
          headers: {
            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawBody = response.data is Map<String, dynamic>
            ? response.data
            : (response.data is String ? jsonDecode(response.data) : null);

        if (rawBody != null && rawBody['data'] != null) {
          final summary = PatientFitnessSummaryResponse.fromJson(Map<String, dynamic>.from(rawBody['data']));
          if (summary.today != null) {
            todayFitnessNotifier.value = summary.today;
          }
          return summary;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Error fetching summary from backend: $e');
    }
    return null;
  }
}
