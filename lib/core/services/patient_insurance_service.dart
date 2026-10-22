import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/base_api_configuration.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/data/models/insurance/patient_insurance_policy_model.dart';

class PatientInsuranceService {
  PatientInsuranceService._();
  static final PatientInsuranceService instance = PatientInsuranceService._();

  final ValueNotifier<List<PatientInsurancePolicyModel>> policiesNotifier =
      ValueNotifier<List<PatientInsurancePolicyModel>>([]);

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  String _getStorageKey(String userId) => 'patient_insurance_policies_$userId';

  /// Resolves the effective patient user ID
  String _resolveUserId({String? overrideUserId}) {
    if (overrideUserId != null && overrideUserId.trim().isNotEmpty) {
      return overrideUserId.trim();
    }
    final sessionUser = GlobalSession.instance.userNotifier.value;
    final id = (sessionUser?.data?.id ?? '').toString().trim();
    return id.isNotEmpty ? id : 'default_patient';
  }

  /// Loads all global insurance policies for the current patient
  Future<List<PatientInsurancePolicyModel>> getPolicies({
    String? userId,
    bool forceRefresh = false,
  }) async {
    final effectiveUserId = _resolveUserId(overrideUserId: userId);
    isLoadingNotifier.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(effectiveUserId);
      final cachedStr = prefs.getString(key);

      List<PatientInsurancePolicyModel> loaded = [];

      if (cachedStr != null && cachedStr.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedStr);
          loaded = decoded
              .map((item) => PatientInsurancePolicyModel.fromJson(Map<String, dynamic>.from(item)))
              .where((p) => !p.isDeleted)
              .toList();
        } catch (e) {
          debugPrint('[PatientInsuranceService] Cache decode error: $e');
        }
      }

      // Check backend API if available using direct Dio (bypassing global ErrorInterceptor to prevent 404 snackbars)
      try {
        final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
        if (token.isNotEmpty) {
          final dio = _createDirectDio(token: token);
          final response = await dio.get(
            '/v1/api/user/patient/insurances',
            queryParameters: {'userId': effectiveUserId},
          );

          if (response.statusCode == 200 && response.data != null) {
            final dynamic listData = response.data['data'] ?? response.data['insurances'];
            if (listData is List && listData.isNotEmpty) {
              final remoteList = listData
                  .map((e) => PatientInsurancePolicyModel.fromJson(Map<String, dynamic>.from(e)))
                  .where((p) => !p.isDeleted)
                  .toList();

              // Merge remote with local items without overriding same-provider policies
              final Map<String, PatientInsurancePolicyModel> map = {};
              for (final p in loaded) {
                final key = (p.id != null && p.id.toString().isNotEmpty)
                    ? p.id.toString()
                    : '${p.policyNumber}_${p.insuranceProvider}_${p.policyName}_${p.createdAt?.millisecondsSinceEpoch ?? loaded.indexOf(p)}';
                map[key] = p;
              }
              for (final r in remoteList) {
                final key = (r.id != null && r.id.toString().isNotEmpty)
                    ? r.id.toString()
                    : '${r.policyNumber}_${r.insuranceProvider}_${r.policyName}_${r.createdAt?.millisecondsSinceEpoch ?? remoteList.indexOf(r)}';
                map[key] = r;
              }
              loaded = map.values.toList();
              await _saveToStorage(effectiveUserId, loaded);
            }
          }
        }
      } catch (_) {
        // Backend endpoint not yet deployed (404) or offline; silently fallback to local persistence with zero error popups
      }

      policiesNotifier.value = loaded;
      return loaded;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Saves (creates or updates) a policy
  Future<PatientInsurancePolicyModel> savePolicy(
    PatientInsurancePolicyModel policy, {
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(overrideUserId: userId);
    final currentList = List<PatientInsurancePolicyModel>.from(policiesNotifier.value);

    PatientInsurancePolicyModel policyToSave = policy;
    if (policyToSave.id == null || policyToSave.id.toString().isEmpty) {
      final generatedId = DateTime.now().millisecondsSinceEpoch;
      policyToSave = policyToSave.copyWith(
        id: generatedId,
        userId: effectiveUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      currentList.insert(0, policyToSave);
    } else {
      policyToSave = policyToSave.copyWith(
        userId: effectiveUserId,
        updatedAt: DateTime.now(),
      );
      final index = currentList.indexWhere((p) => p.id.toString() == policyToSave.id.toString());
      if (index >= 0) {
        currentList[index] = policyToSave;
      } else {
        currentList.insert(0, policyToSave);
      }
    }

    // Persist to local storage
    await _saveToStorage(effectiveUserId, currentList);
    policiesNotifier.value = currentList;

    // Sync with backend API and ensure smooth visual feedback on submit button
    await Future.wait([
      _syncWithBackend(policyToSave),
      Future.delayed(const Duration(milliseconds: 650)),
    ]);

    return policyToSave;
  }

  /// Soft deletes a policy
  Future<bool> deletePolicy(dynamic policyId, {String? userId}) async {
    final effectiveUserId = _resolveUserId(overrideUserId: userId);
    final currentList = List<PatientInsurancePolicyModel>.from(policiesNotifier.value);

    final index = currentList.indexWhere((p) => p.id.toString() == policyId.toString());
    if (index >= 0) {
      // Await backend deletion with minimum duration so the loading spinner inside button is clearly visible
      await Future.wait([
        _deleteFromBackend(policyId, effectiveUserId),
        Future.delayed(const Duration(milliseconds: 650)),
      ]);

      currentList.removeAt(index);
      await _saveToStorage(effectiveUserId, currentList);
      policiesNotifier.value = currentList;
      return true;
    }
    return false;
  }

  Future<void> _saveToStorage(String userId, List<PatientInsurancePolicyModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_getStorageKey(userId), jsonEncode(jsonList));
  }

  Dio _createDirectDio({String? token}) {
    String baseUrl = EnvironmentService.config.accountBaseUrl.trim();
    if (!baseUrl.startsWith("http://") && !baseUrl.startsWith("https://")) {
      if (baseUrl.contains("192.168.") ||
          baseUrl.contains("10.") ||
          baseUrl.contains("localhost") ||
          baseUrl.contains(":")) {
        baseUrl = "http://$baseUrl";
      } else {
        baseUrl = "https://$baseUrl";
      }
    }
    while (baseUrl.endsWith("/")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<void> _syncWithBackend(PatientInsurancePolicyModel policy) async {
    try {
      final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
      if (token.isEmpty) return;

      final dio = _createDirectDio(token: token);
      await dio.post(
        '/v1/api/user/patient/insurances',
        data: policy.toJson(),
      );
    } catch (_) {
      // Backend not yet ready or offline; graceful local persistence
    }
  }

  Future<void> _deleteFromBackend(dynamic policyId, String userId) async {
    try {
      final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
      if (token.isEmpty) return;

      final dio = _createDirectDio(token: token);
      await dio.delete(
        '/v1/api/user/patient/insurances/$policyId',
        data: {'userId': userId},
      );
    } catch (_) {}
  }
}
