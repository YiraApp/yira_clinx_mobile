import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/local/flutter_secure_storage.dart';
import '../../di/dependency_injection.dart';
import '../../features/data/models/login/login_model.dart';
import '../../features/domain/entities/login/login_entity.dart';
import '../package/domain/plat_form_info_entity.dart';
import '../use_cases/get_plat_form_info_usecase.dart';

class GlobalSession {
  GlobalSession._internal();
  static final GlobalSession instance = GlobalSession._internal();

  final ValueNotifier<LoginEntity?> userNotifier = ValueNotifier<LoginEntity?>(null);
  final ValueNotifier<PlatformInfoEntity?> platformNotifier = ValueNotifier<PlatformInfoEntity?>(null);

  String? rootPrimaryUserId;

  late SecureStorageService _secureStorage;

  PlatformInfoEntity? get cachedPlatformInfo => platformNotifier.value;

  Future<void> initialize(SecureStorageService secureStorageService) async {
    _secureStorage = secureStorageService;
    try {
      final String? userJson = await _secureStorage.readSecureValue<String>(SecureCacheKey.userData);
      if (userJson != null) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        userNotifier.value = LoginModel.fromJson(userMap);
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
      Map<String, dynamic> jsonMap;
      if (data is LoginModel) {
        jsonMap = data.toJson();
      } else {
        jsonMap = LoginModel.fromEntity(data).toJson();
      }

      final String userJson = jsonEncode(jsonMap);
      await _secureStorage.writeSecureValue<String>(SecureCacheKey.userData, userJson);
    } catch (e, stackTrace) {
      debugPrint("CRITICAL (GlobalSession): Error saving session payload to SecureStorage: $e");
      debugPrint("Stacktrace: $stackTrace");
    }
  }

  Future<void> clear() async {
    userNotifier.value = null;
    try {
      await _secureStorage.deleteSecureValue(SecureCacheKey.userData);
    } catch (e) {
      debugPrint("Error clearing secure storage cache: $e");
    }
  }
}