import 'dart:async';
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
  linkedToAnotherProfile,
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

class FitnessSyncResult {
  final bool isSuccess;
  final String message;
  final int recordsSynced;
  final TodayFitnessData? todayData;

  const FitnessSyncResult({
    required this.isSuccess,
    required this.message,
    this.recordsSynced = 0,
    this.todayData,
  });
}

/// Keeps one profile's fitness data in step with the phone's health store.
///
/// Health data on a phone belongs to whoever wears it, so one phone feeds one
/// profile at a time. Any profile, a family member's included, can be that
/// profile; linking another one moves the link instead of copying the same
/// readings into two people's records.
///
/// The first sync after connecting (or after upgrading from the old reader)
/// re-reads 30 days and replaces what the server holds. Later syncs read from
/// two days before the last successful sync, because watches often upload a
/// day or two late.
class FitnessSyncService {
  FitnessSyncService._();
  static final FitnessSyncService instance = FitnessSyncService._();

  static const int backfillDays = 30;
  static const int _lateDataDays = 2;
  static const Duration _autoSyncCooldown = Duration(minutes: 3);
  static const int _syncSchema = 2;
  static const int _permissionVersion = 2;

  static const String _ownerKey = 'fitness_device_owner';
  static const String _ownerNameKey = 'fitness_device_owner_name';
  static String _connectedKey(String id) => 'fitness_connected_$id';
  static String _disconnectedKey(String id) => 'fitness_user_disconnected_$id';
  static String _todayKey(String id) => 'fitness_today_cached_$id';
  static String _schemaKey(String id) => 'fitness_sync_schema_$id';
  static String _lastSyncDayKey(String id) => 'fitness_last_sync_day_$id';
  static String _lastSyncAtKey(String id) => 'fitness_last_sync_at_$id';
  static String _sourcesKey(String id) => 'fitness_sources_$id';
  static String _permVersionKey(String id) => 'fitness_perm_version_$id';
  static String _stepGoalKey(String id) => 'fitness_step_goal_$id';

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<TodayFitnessData?> todayFitnessNotifier = ValueNotifier<TodayFitnessData?>(null);
  final ValueNotifier<DateTime?> lastSyncedAtNotifier = ValueNotifier<DateTime?>(null);
  final ValueNotifier<List<String>> sourcesNotifier = ValueNotifier<List<String>>(const []);

  bool _isInitialized = false;
  Future<FitnessSyncResult>? _inFlight;

  String get _userId => GlobalSession.instance.userNotifier.value?.data?.id ?? '';
  String get _token => GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
  String get _userName {
    final d = GlobalSession.instance.userNotifier.value?.data;
    return '${d?.firstName ?? ''} ${d?.lastName ?? ''}'.trim();
  }

  /// Completely resets fitness connection states on user logout
  void reset() {
    _isInitialized = false;
    _inFlight = null;
    isConnectedNotifier.value = false;
    isSyncingNotifier.value = false;
    todayFitnessNotifier.value = null;
    lastSyncedAtNotifier.value = null;
    sourcesNotifier.value = const [];
  }

  /// Reloads state for the profile that just became active.
  void handleProfileSwitched() {
    reset();
    init();
  }

  /// Loads the active profile's cached state and syncs in the background if it's connected.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await loadCachedStatus();
    if (isConnectedNotifier.value) unawaited(syncNow(silent: true));
  }

  /// The profile this phone's health data is linked to, if it's not the active one.
  Future<({String id, String name})?> otherLinkedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final owner = prefs.getString(_ownerKey) ?? '';
    if (owner.isEmpty || owner.toLowerCase() == _userId.toLowerCase()) return null;
    if (prefs.getBool(_connectedKey(owner)) != true) return null;

    // Name it only when it's one of this account's own family profiles.
    final profiles = GlobalSession.instance.userNotifier.value?.data?.profiles ?? [];
    final known = profiles.any((p) => (p.id ?? '').toLowerCase() == owner.toLowerCase());
    return (id: owner, name: known ? (prefs.getString(_ownerNameKey) ?? '') : '');
  }

  /// Check whether fitness permissions are granted and connected
  Future<bool> checkIsConnected() async {
    final connected = await _isConnectedForActiveProfile();
    isConnectedNotifier.value = connected;
    return connected;
  }

  Future<bool> _isConnectedForActiveProfile() async {
    final userId = _userId;
    if (userId.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await _dropLegacySharedKeys(prefs);
      if (prefs.getBool(_disconnectedKey(userId)) == true) return false;
      if (prefs.getBool(_connectedKey(userId)) != true) return false;

      final owner = prefs.getString(_ownerKey) ?? '';
      if (owner.isEmpty) {
        // Connected before the one-phone-one-profile rule: this profile keeps the link.
        await prefs.setString(_ownerKey, userId);
        await prefs.setString(_ownerNameKey, _userName);
      } else if (owner.toLowerCase() != userId.toLowerCase()) {
        return false;
      }

      if (!await FitnessService.instance.hasOsPermission()) {
        await prefs.setBool(_connectedKey(userId), false);
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Error checking isConnected: $e');
      return isConnectedNotifier.value;
    }
  }

  /// Older builds kept one device-wide flag, which made every profile and every
  /// account on the phone look connected. Only per-profile flags count now.
  Future<void> _dropLegacySharedKeys(SharedPreferences prefs) async {
    for (final key in const [
      'fitness_connected_default',
      'fitness_user_disconnected_default',
      'fitness_today_cached_default',
    ]) {
      if (prefs.containsKey(key)) await prefs.remove(key);
    }
  }

  /// Load cached fitness connection flag & today metrics from SharedPreferences
  Future<void> loadCachedStatus() async {
    final userId = _userId;
    final connected = await _isConnectedForActiveProfile();
    isConnectedNotifier.value = connected;
    if (!connected) {
      todayFitnessNotifier.value = null;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAt = prefs.getString(_lastSyncAtKey(userId));
      lastSyncedAtNotifier.value = lastAt == null ? null : DateTime.tryParse(lastAt);
      sourcesNotifier.value = prefs.getStringList(_sourcesKey(userId)) ?? const [];

      final cached = prefs.getString(_todayKey(userId));
      if (cached != null && cached.isNotEmpty) {
        final today = TodayFitnessData.fromJson(jsonDecode(cached));
        // Yesterday's numbers are never shown as today's.
        todayFitnessNotifier.value = today.date == FitnessService.dateKey(DateTime.now()) ? today : null;
      }
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Error loading cached status: $e');
    }
  }

  /// One-tap Connect Fitness flow
  ///
  /// When the phone already feeds another profile, nothing changes unless
  /// [moveLink] is true, in which case that profile stops syncing from here.
  Future<FitnessConnectResult> connectFitness({bool moveLink = false}) async {
    final userId = _userId;
    if (userId.isEmpty) {
      return const FitnessConnectResult(
        status: FitnessConnectStatus.error,
        title: 'Session expired',
        message: 'Please sign in again to connect fitness.',
      );
    }

    final other = await otherLinkedProfile();
    if (other != null && !moveLink) {
      final who = other.name.isNotEmpty ? other.name : 'another profile';
      return FitnessConnectResult(
        status: FitnessConnectStatus.linkedToAnotherProfile,
        title: 'Phone linked to $who',
        message: 'This phone\'s health data already syncs to $who. '
            'Link it to ${_userName.isNotEmpty ? _userName : 'this profile'} instead? '
            '$who will stop syncing from this phone.',
      );
    }

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
      final prefs = await SharedPreferences.getInstance();
      await _dropLegacySharedKeys(prefs);
      if (!granted) {
        await prefs.setBool(_connectedKey(userId), false);
        isConnectedNotifier.value = false;
        return FitnessConnectResult(
          status: FitnessConnectStatus.permissionDenied,
          title: 'Permission Required',
          message: Platform.isIOS
              ? 'Apple Health access was not granted. Please open Settings > Health > Data Access & Devices > Yira Clinics and turn on permissions.'
              : 'Health Connect access was not granted. Please open Settings and enable permissions.',
        );
      }

      if (other != null) {
        await prefs.setBool(_connectedKey(other.id), false);
        await prefs.remove(_todayKey(other.id));
      }
      await prefs.setString(_ownerKey, userId);
      await prefs.setString(_ownerNameKey, _userName);
      await prefs.setBool(_connectedKey(userId), true);
      await prefs.setBool(_disconnectedKey(userId), false);
      await prefs.setInt(_permVersionKey(userId), _permissionVersion);
      // A fresh link always starts with a full 30-day read.
      await prefs.remove(_schemaKey(userId));
      isConnectedNotifier.value = true;

      await syncNow(silent: false);
      return const FitnessConnectResult(
        status: FitnessConnectStatus.success,
        title: 'Connected',
        message: 'Fitness sensors connected successfully.',
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

  /// Asks once for types added since the profile connected (resting heart
  /// rate and distance). Call it from a screen, never from a background sync.
  Future<void> requestNewPermissionsIfNeeded() async {
    final userId = _userId;
    if (userId.isEmpty || !isConnectedNotifier.value) return;
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_permVersionKey(userId)) ?? 1) >= _permissionVersion) return;
    await prefs.setInt(_permVersionKey(userId), _permissionVersion);
    await FitnessService.instance.requestPermissions();
  }

  /// Disconnect fitness flow
  Future<void> disconnectFitness() async {
    final userId = _userId;
    final token = _token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId.isNotEmpty) {
        await prefs.setBool(_connectedKey(userId), false);
        await prefs.setBool(_disconnectedKey(userId), true);
        await prefs.remove(_todayKey(userId));
        await prefs.remove(_schemaKey(userId));
        await prefs.remove(_lastSyncDayKey(userId));
        if ((prefs.getString(_ownerKey) ?? '').toLowerCase() == userId.toLowerCase()) {
          await prefs.remove(_ownerKey);
          await prefs.remove(_ownerNameKey);
        }
      }
      isConnectedNotifier.value = false;
      todayFitnessNotifier.value = null;
      lastSyncedAtNotifier.value = null;

      if (userId.isNotEmpty && token.isNotEmpty) {
        try {
          await ApiClient().account(showSuccessSnack: false).post(
                URLs.patientFitnessDisconnectUrl,
                data: {'patientId': userId},
                options: Options(
                  headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
                  extra: {'suppressErrorSnack': true},
                ),
              );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Disconnect error: $e');
    }
  }

  /// Daily step goal for the active profile.
  Future<int> getStepGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepGoalKey(_userId)) ?? 8000;
  }

  Future<void> setStepGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepGoalKey(_userId), goal.clamp(1000, 50000));
  }

  /// Reads the phone's health store and saves it to the server.
  ///
  /// [fullResync] re-reads the whole 30-day window and replaces the server's
  /// values for it. Silent calls (app resume, dashboard open) are skipped if
  /// the last sync finished under three minutes ago. Concurrent calls share
  /// one run.
  Future<FitnessSyncResult> syncNow({bool silent = false, bool fullResync = false}) {
    final running = _inFlight;
    if (running != null) return running;
    final run = _sync(silent: silent, fullResync: fullResync);
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
  }

  Future<FitnessSyncResult> _sync({required bool silent, required bool fullResync}) async {
    final userId = _userId;
    final token = _token;
    if (userId.isEmpty) {
      return const FitnessSyncResult(isSuccess: false, message: 'User session expired. Please log in again.');
    }
    if (!await _isConnectedForActiveProfile()) {
      isConnectedNotifier.value = false;
      return FitnessSyncResult(
        isSuccess: false,
        message: Platform.isIOS
            ? 'Connect Apple Health to sync your fitness data.'
            : 'Connect Health Connect to sync your fitness data.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final lastAt = DateTime.tryParse(prefs.getString(_lastSyncAtKey(userId)) ?? '');
    final upgraded = (prefs.getInt(_schemaKey(userId)) ?? 0) >= _syncSchema;
    if (silent && !fullResync && upgraded && lastAt != null && DateTime.now().difference(lastAt) < _autoSyncCooldown) {
      return FitnessSyncResult(isSuccess: true, message: 'Already up to date', todayData: todayFitnessNotifier.value);
    }

    // Re-read 30 days on first sync, after the reader upgrade, or on request.
    final repair = fullResync || !upgraded;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var from = today.subtract(const Duration(days: backfillDays - 1));
    if (!repair) {
      final lastDay = DateTime.tryParse(prefs.getString(_lastSyncDayKey(userId)) ?? '');
      if (lastDay != null) {
        final resume = lastDay.subtract(const Duration(days: _lateDataDays));
        if (resume.isAfter(from)) from = resume;
      }
    }

    try {
      if (!silent) isSyncingNotifier.value = true;

      final days = await FitnessService.instance.readDays(from: from);
      final todayDay = days.firstWhere(
        (d) => d.dateKey == FitnessService.dateKey(today),
        orElse: () => FitnessDay(today),
      );
      final latestWeight = todayDay.weightKg ?? await FitnessService.instance.readLatestWeight();
      final todayMap = _todayMap(todayDay, latestWeight, now);
      final todayData = TodayFitnessData.fromJson(todayMap);
      todayFitnessNotifier.value = todayData;
      await prefs.setString(_todayKey(userId), jsonEncode(todayMap));

      final sources = <String>{for (final d in days) ...d.sources}.toList()..sort();
      if (sources.isNotEmpty) {
        sourcesNotifier.value = sources;
        await prefs.setStringList(_sourcesKey(userId), sources);
      }

      final records = [for (final d in days) if (d.hasAnyReading) d.toPayload()];
      if (records.isEmpty) {
        await _markSynced(prefs, userId, now);
        return FitnessSyncResult(
          isSuccess: true,
          message: 'No new readings on this phone yet',
          todayData: todayData,
        );
      }
      if (token.isEmpty) {
        return const FitnessSyncResult(isSuccess: false, message: 'User session expired. Please log in again.');
      }

      final response = await ApiClient().account(showSuccessSnack: false).post(
            URLs.patientFitnessSyncUrl,
            data: {
              'patientId': userId,
              'source': FitnessService.instance.platformSourceName,
              'schema': _syncSchema,
              'repair': repair,
              'records': records,
            },
            options: Options(
              headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
              extra: {'suppressErrorSnack': true},
            ),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _markSynced(prefs, userId, now);
        debugPrint('✅ [FitnessSyncService] Synced ${records.length} days (repair: $repair)');
        return FitnessSyncResult(
          isSuccess: true,
          message: repair ? 'Synced the last $backfillDays days' : 'Fitness data is up to date',
          recordsSynced: records.length,
          todayData: todayData,
        );
      }
      return FitnessSyncResult(isSuccess: false, message: 'Server returned error status ${response.statusCode}');
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Sync error: $e');
      return const FitnessSyncResult(
        isSuccess: false,
        message: 'Couldn\'t sync right now. Check your connection and try again.',
      );
    } finally {
      if (!silent) isSyncingNotifier.value = false;
    }
  }

  Future<void> _markSynced(SharedPreferences prefs, String userId, DateTime now) async {
    await prefs.setInt(_schemaKey(userId), _syncSchema);
    await prefs.setString(_lastSyncDayKey(userId), FitnessService.dateKey(now));
    await prefs.setString(_lastSyncAtKey(userId), now.toIso8601String());
    lastSyncedAtNotifier.value = now;
  }

  Map<String, dynamic> _todayMap(FitnessDay day, double? latestWeight, DateTime now) {
    final sleep = day.sleepMinutes;
    return {
      ...day.toPayload(),
      'weightKg': latestWeight == null ? null : double.parse(latestWeight.toStringAsFixed(1)),
      'sleepFormatted': sleep == null ? null : '${sleep ~/ 60}h ${sleep % 60}m',
      'hourly': day.hourly,
      'source': FitnessService.instance.platformSourceName,
      'lastSynced': now.toIso8601String(),
    };
  }

  /// Summary and chart points for the active profile, or [patientId] when a
  /// family member's data is being viewed.
  Future<PatientFitnessSummaryResponse?> fetchSummaryFromBackend({String period = 'week', String? patientId}) async {
    final userId = patientId ?? _userId;
    final token = _token;
    if (userId.isEmpty) return null;

    try {
      final response = await ApiClient().account(showSuccessSnack: false).get(
            URLs.patientFitnessSummaryUrl,
            queryParameters: {
              'patientId': userId,
              'period': period,
              'todayDate': FitnessService.dateKey(DateTime.now()),
            },
            options: Options(
              headers: {if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token'},
              extra: {'suppressErrorSnack': true},
            ),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawBody = response.data is Map<String, dynamic>
            ? response.data
            : (response.data is String ? jsonDecode(response.data) : null);
        if (rawBody != null && rawBody['data'] != null) {
          return PatientFitnessSummaryResponse.fromJson(Map<String, dynamic>.from(rawBody['data']));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [FitnessSyncService] Error fetching summary from backend: $e');
    }
    return null;
  }
}
