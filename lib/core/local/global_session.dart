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
        userNotifier.value = LoginModel.fromJson(userMap);
      }
    } catch (e) {
      debugPrint("Error initializing GlobalSession: $e");
      userNotifier.value = null;
    }
  }

  Future<void> update(LoginEntity data) async {
    userNotifier.value = data;
    try {
      final String userJson = jsonEncode((data as LoginModel).toJson());
      await _secureStorage.writeSecureValue<String>(SecureCacheKey.userData, userJson);
    } catch (e) {
      debugPrint("Error saving to SecureStorage: $e");
    }
  }

  Future<void> clear() async {
    userNotifier.value = null;
    await _secureStorage.deleteSecureValue(SecureCacheKey.userData);
  }
}