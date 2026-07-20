import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/clinx_storage_keys.dart';

enum SecureCacheKey {
  doctorProfile(ClinxStorageKeys.doctorProfile),
  activeAppointments(ClinxStorageKeys.activeAppointments),
  patientQueue(ClinxStorageKeys.patientQueue),
  medicalReportsConfig(ClinxStorageKeys.medicalReportsConfig),
  appVersionInfo(ClinxStorageKeys.appVersionInfo),
  userData(ClinxStorageKeys.userData);

  final String keyName;
  const SecureCacheKey(this.keyName);
}

class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService._(this._secureStorage);

  factory SecureStorageService() {
    const AndroidOptions androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    );

    final IOSOptions iosOptions = const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    );

    return SecureStorageService._(
       FlutterSecureStorage(
        aOptions: androidOptions,
        iOptions: iosOptions,
      ),
    );
  }


  Future<bool> writeSecureValue<T>(SecureCacheKey cacheKey, T value) async {
    try {
      String valueToString;

      if (value is String) {
        valueToString = value;
      } else if (value is bool || value is int || value is double) {
        valueToString = value.toString();
      } else if (value is Map || value is List) {
        valueToString = jsonEncode(value);
      } else {
        throw Exception("Unsupported Type Configuration passed to Secure Storage");
      }

      await _secureStorage.write(key: cacheKey.keyName, value: valueToString);
      return true;
    } catch (error) {
      debugPrint("SecureStorageService Write Error Key [${cacheKey.keyName}]: $error");
      return false;
    }
  }


  Future<T?> readSecureValue<T>(SecureCacheKey cacheKey) async {
    try {
      final String? value = await _secureStorage.read(key: cacheKey.keyName);
      if (value == null) return null;


      if (T == bool) return (value == 'true') as T;
      if (T == int) return int.tryParse(value) as T?;
      if (T == double) return double.tryParse(value) as T?;


      if (T == Map || _isMapType<T>()) {
        final decoded = jsonDecode(value);
        if (decoded is Map) {

          return Map<String, dynamic>.from(decoded) as T;
        }
      }

      if (T == List || _isListType<T>()) {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return List<dynamic>.from(decoded) as T;
        }
      }

      return value as T?;
    } catch (error) {
      debugPrint("SecureStorageService Read Error Key [${cacheKey.keyName}]: $error");
      return null;
    }
  }

  Future<bool> containsKey(SecureCacheKey cacheKey) async {
    try {
      return await _secureStorage.containsKey(key: cacheKey.keyName);
    } catch (error) {
      debugPrint("SecureStorageService ContainsKey Error [${cacheKey.keyName}]: $error");
      return false;
    }
  }


  Future<bool> deleteSecureValue(SecureCacheKey cacheKey) async {
    try {
      await _secureStorage.delete(key: cacheKey.keyName);
      return true;
    } catch (error) {
      debugPrint("SecureStorageService Deletion Error Key [${cacheKey.keyName}]: $error");
      return false;
    }
  }

  Future<bool> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      return true;
    } catch (error) {
      debugPrint("SecureStorageService Clear Wipe Error: $error");
      return false;
    }
  }

  bool _isMapType<T>() => T.toString().startsWith('Map<');
  bool _isListType<T>() => T.toString().startsWith('List<');
}