import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/local/flutter_secure_storage.dart';
import '../../di/dependency_injection.dart';
import '../../features/data/models/login/login_model.dart';
import '../../features/domain/entities/login/login_entity.dart';
import '../constants/clinx_storage_keys.dart';
import '../package/domain/plat_form_info_entity.dart';
import '../services/notification_services/notification_services.dart';
import '../use_cases/get_plat_form_info_usecase.dart';
import 'shared_preferences.dart';

class GlobalSession {
  GlobalSession._internal();
  static final GlobalSession instance = GlobalSession._internal();

  final ValueNotifier<LoginEntity?> userNotifier = ValueNotifier<LoginEntity?>(null);
  final ValueNotifier<PlatformInfoEntity?> platformNotifier = ValueNotifier<PlatformInfoEntity?>(null);

  String? rootPrimaryUserId;

  void setRootPrimaryUserId(String? id) {
    rootPrimaryUserId = id;
    if (id != null && id.isNotEmpty) {
      try {
        _secureStorage.writeSecureValue<String>(SecureCacheKey.rootPrimaryUserId, id);
      } catch (_) {}
    }
  }

  bool get isCurrentProfilePrimary {
    final current = userNotifier.value?.data;
    if (current == null) return false;
    final currentId = (current.id ?? '').trim().toLowerCase();
    if (currentId.isEmpty) return false;

    // 1. If rootPrimaryUserId is set and differs from current active user ID, it's not primary
    final rootId = (rootPrimaryUserId ?? '').trim().toLowerCase();
    if (rootId.isNotEmpty && currentId != rootId) {
      return false;
    }

    // 2. Check the profiles list inside current session
    final profiles = current.profiles ?? [];
    if (profiles.isNotEmpty) {
      ProfileEntity? match;
      for (int i = 0; i < profiles.length; i++) {
        final p = profiles[i];
        if ((p.id ?? '').trim().toLowerCase() == currentId) {
          match = p;
          // If this matching profile is not at index 0, it is a dependent/child profile
          if (i > 0) return false;
          break;
        }
      }

      if (match != null) {
        final rel = (match.relation ?? '').trim().toLowerCase();
        final bool isFamilyRelation = rel.isNotEmpty &&
            rel != 'self' &&
            rel != 'primary' &&
            rel != 'admin';

        if (match.isPrimary == false ||
            match.accountType?.toLowerCase() == 'dependent' ||
            isFamilyRelation) {
          return false;
        }
      }
    }

    return true;
  }

  bool get isCurrentProfileChild => !isCurrentProfilePrimary;

  late SecureStorageService _secureStorage;

  PlatformInfoEntity? get cachedPlatformInfo => platformNotifier.value;

  Future<void> initialize(SecureStorageService secureStorageService) async {
    _secureStorage = secureStorageService;
    try {
      final bool isLoggedIn = sl.isRegistered<SharedPrefsService>() &&
          (sl<SharedPrefsService>().getValue<bool>(ClinxStorageKeys.isUserLoggedIn) ?? false);
      if (!isLoggedIn) {
        userNotifier.value = null;
        return;
      }
      final String? userJson = await _secureStorage.readSecureValue<String>(SecureCacheKey.userData);
      if (userJson != null) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        userNotifier.value = LoginModel.fromJson(userMap);
      }
      final String? cachedRootId = await _secureStorage.readSecureValue<String>(SecureCacheKey.rootPrimaryUserId);
      if (cachedRootId != null && cachedRootId.isNotEmpty) {
        rootPrimaryUserId = cachedRootId;
      } else if (userNotifier.value?.data != null) {
        final profiles = userNotifier.value!.data!.profiles ?? [];
        if (profiles.isNotEmpty && (profiles[0].id ?? '').isNotEmpty) {
          setRootPrimaryUserId(profiles[0].id);
        } else if ((userNotifier.value!.data!.id ?? '').isNotEmpty) {
          setRootPrimaryUserId(userNotifier.value!.data!.id);
        }
      }
    } catch (e) {
      debugPrint("CRITICAL (GlobalSession): Cache initialization failed: $e");
      userNotifier.value = null;
    }
  }

  Future<void> initializePlatformTelemetry({bool forceRefresh = false}) async {
    if (platformNotifier.value != null && !forceRefresh) {
      return;
    }

    try {
      debugPrint("GlobalSession: Syncing native platform telemetry info...");
      final getPlatformInfo = sl<GetPlatformInfoUseCase>();
      platformNotifier.value = await getPlatformInfo();
    } catch (e) {
      debugPrint("CRITICAL (GlobalSession): Failed to gather hardware metadata: $e");
      platformNotifier.value ??= const PlatformInfoEntity(
        deviceId: 'fallback_production_id',
        platform: 'Android',
        version: '1.0.0',
        buildNumber: '1',
        appName: 'Yira Clinics',
      );
    }
  }

  Future<void> update(LoginEntity data) async {
    userNotifier.value = data;
    try {
      if ((rootPrimaryUserId ?? '').isEmpty) {
        final profiles = data.data?.profiles ?? [];
        if (profiles.isNotEmpty && (profiles[0].id ?? '').isNotEmpty) {
          setRootPrimaryUserId(profiles[0].id);
        } else if ((data.data?.id ?? '').isNotEmpty) {
          setRootPrimaryUserId(data.data?.id);
        }
      }

      Map<String, dynamic> jsonMap;
      if (data is LoginModel) {
        jsonMap = data.toJson();
      } else {
        jsonMap = LoginModel.fromEntity(data).toJson();
      }

      final String userJson = jsonEncode(jsonMap);
      await _secureStorage.writeSecureValue<String>(SecureCacheKey.userData, userJson);
      // Automatically register FCM token for the newly authenticated session
      NotificationService.instance.syncFcmTokenWithBackend();
    } catch (e, stackTrace) {
      debugPrint("CRITICAL (GlobalSession): Error saving session payload to SecureStorage: $e");
      debugPrint("Stacktrace: $stackTrace");
    }
  }

  Future<void> updateTokens({
    required String newAccessToken,
    required String newRefreshToken,
  }) async {
    final current = userNotifier.value;
    if (current == null || current.data == null) return;

    try {
      final Map<String, dynamic> jsonMap =
          (current is LoginModel ? current.toJson() : LoginModel.fromEntity(current).toJson());

      if (jsonMap['data'] is Map<String, dynamic>) {
        final dataMap = jsonMap['data'] as Map<String, dynamic>;
        dataMap['accessToken'] = newAccessToken;
        dataMap['refreshToken'] = newRefreshToken;
      }

      final updatedModel = LoginModel.fromJson(jsonMap);
      await update(updatedModel);
      debugPrint("GlobalSession: Access token refreshed and persisted cleanly.");
    } catch (e) {
      debugPrint("CRITICAL (GlobalSession): Failed to update tokens: $e");
    }
  }

  Future<void> clear() async {
    userNotifier.value = null;
    rootPrimaryUserId = null;
    try {
      await _secureStorage.deleteSecureValue(SecureCacheKey.userData);
      await _secureStorage.deleteSecureValue(SecureCacheKey.rootPrimaryUserId);
    } catch (e) {
      debugPrint("Error clearing secure storage cache: $e");
    }
  }
}