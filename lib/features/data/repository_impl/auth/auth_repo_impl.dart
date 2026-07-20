import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/clinx_storage_keys.dart';
import 'package:yiraclinics/core/local/flutter_secure_storage.dart';
import '../../../../core/local/shared_preferences.dart';
import '../../../domain/entities/login/login_entity.dart';
import '../../../domain/repositories/auth/auth_repo.dart';
import '../../models/login/login_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SharedPrefsService _prefsService;
  final SecureStorageService _secureStorageService;
  static const String _authKey = ClinxStorageKeys.isUserLoggedIn;

  AuthRepositoryImpl(this._prefsService, this._secureStorageService);

  @override
  bool isUserLoggedIn() {
    return _prefsService.getValue<bool>(_authKey) ?? false;
  }

  @override
  Future<LoginEntity?> localDataCatch() async {
    try {
      final String? userJson = await _secureStorageService.readSecureValue<String>(SecureCacheKey.userData);
      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        return LoginModel.fromJson(userMap);
      }
    } catch (e) {
      debugPrint("Error decoding cached user: $e");
      return null;
    }
    return null;
  }
}