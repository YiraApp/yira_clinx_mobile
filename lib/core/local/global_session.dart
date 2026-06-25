import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/local/flutter_secure_storage.dart';
import '../../features/data/models/login/login_model.dart';
import '../../features/domain/entities/login/login_entity.dart';

class GlobalSession {
  GlobalSession._internal();
  static final GlobalSession instance = GlobalSession._internal();

  final ValueNotifier<LoginEntity?> userNotifier = ValueNotifier<LoginEntity?>(null);
  late SecureStorageService _secureStorage;

  Future<void> initialize(SecureStorageService secureStorageService) async {
    _secureStorage = secureStorageService;
    try {
      final String? userJson = await _secureStorage.readSecureValue<String>(SecureCacheKey.userData);
      if (userJson != null) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        // Safely map from stored cached maps back into memory
        userNotifier.value = LoginModel.fromJson(userMap);
      }
    } catch (e) {
      debugPrint("CRITICAL (GlobalSession): Cache initialization failed: $e");
      userNotifier.value = null;
    }
  }

  Future<void> update(LoginEntity data) async {
    userNotifier.value = data;
    try {
      Map<String, dynamic> jsonMap;

      // FIX: Safely evaluate type instead of forcing an unsafe implicit runtime cast
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