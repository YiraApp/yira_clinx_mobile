

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:yiraclinics/features/data/models/over_view/over_view_model.dart';
import 'package:yiraclinics/features/domain/entities/over_view/over_view_entity.dart';
import 'package:yiraclinics/features/domain/repositories/patient_over_view_repo/patient_over_view_repo.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/cache/local_cache_data_source.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';

class PatientOverViewRepoImpl extends PatientOverViewRepo{
  final ApiClient _apiClient;
  final LocalCacheDataSource _localCache;
  final Connectivity _connectivity;

  PatientOverViewRepoImpl(
      this._apiClient,
      this._localCache, [
        Connectivity? connectivity,
      ]) : _connectivity = connectivity ?? Connectivity();
  @override
  Future<PatientOverViewEntity?> fetchOverViewData({required String userId}) async {
    var endPoint = URLs.patientOverViewUrl;
    var requestBody = {
      "userId": userId,
    };
    final String fullCacheKey = _generateDeterministicCacheKey(
      customPrefix: patientOverViewKey,
      baseUrl: endPoint,
      params: requestBody,
    );
    final List<ConnectivityResult> connectivityResults = await _connectivity
        .checkConnectivity();
    final bool isHardwareOffline = connectivityResults.contains(
      ConnectivityResult.none,
    );
    if (isHardwareOffline) {
      developer.log(
        "Hardware interface disconnected. Directing thread logic instantly to SQLite cache.",
        name: "PatientOverViewRepoImpl",
      );
      return fetchOverViewDirectFromKey(fullCacheKey);
    }

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account(showSuccessSnack: true).get(
        endPoint,
        data: requestBody,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> rawData =
        response.data as Map<String, dynamic>;

        final bool isSuccessStatus =
            rawData['status'] == true || rawData['success'] == true;
        final dynamic nestedPayload =
            rawData['data'] ?? rawData['result'] ?? rawData['payload'];

        if (isSuccessStatus && nestedPayload != null) {
          await _localCache.saveResponse(fullCacheKey, jsonEncode(rawData));
          return PatientOverViewModel.fromJson(rawData);
        }
      }
    } on DioException catch (dioError) {
      developer.log(
        "Dio network error handled: ${dioError.type}. Recovering context gracefully via cache pipeline.",
        error: dioError,
        name: "PatientOverViewRepoImpl",
      );
    } catch (unexpectedError, stackTrace) {
      developer.log(
        "Unexpected formatting model processing exception occurred inside repository.",
        error: unexpectedError,
        stackTrace: stackTrace,
        name: "PatientOverViewRepoImpl",
      );
    }
    return fetchOverViewDirectFromKey(fullCacheKey);
  }

  @override
  Future<PatientOverViewEntity?> fetchOverViewDirectFromKey(String cacheKey)
  async {
    try {
      final String? cachedJsonString = await _localCache.getCachedResponse(
        cacheKey,
      );
      final Map<String, dynamic> mockJsonResponse = {
        "status": true,
        "message": "Overview details fetched successfully",
        "data": {
          "contact_information": {
            "phone": "6303012453",
            "email_address": "teja@gmail.com",
            "residential_address": "Sandhya techno 1, Hyderabad, pin code - 500081",
            "emergency_contact": {
              "name": "Rajesh",
              "phone": "9908875796"
            }
          },
          "medical_information": {
            "condition": "Severe persistent hand pain in the right distal radius extending up through the metacarpal joints.",
            "allergies": "illness",
            "blood_group": "B+",
            "total_visits": 0
          },
          "insurance": {
            "policy_name": "Star Health Premier",
            "policy_number": "ST-99482-XYZ"
          },
          "visit_history": {
            "initial_registration": "May 26, 2026",
            "last_check_in_visit": "May 26, 2026",
            "next_scheduled_appointment": "July 16, 2026"
          },
          "summary": "Severe persistent hand pain in the right distal radius extending up through the metacarpal joints."
        }
      };

      return PatientOverViewModel.fromJson(mockJsonResponse);
      /*if (cachedJsonString != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedJsonString);
        developer.log("Direct cache key fetch execution hit success.", name: "SideMenuRepoImpl");
        return PatientOverViewModel.fromJson(decodedData);
      }*/
    } catch (cacheError, stackTrace) {
      developer.log(
        "Critical failure resolving direct database registers.",
        error: cacheError,
        stackTrace: stackTrace,
        name: "PatientOverViewRepoImpl",
      );
    }
    return null;
  }
  String _generateDeterministicCacheKey({
    required String customPrefix,
    required String baseUrl,
    required Map<String, dynamic> params,
  }) {
    final sortedKeys = params.keys.toList()..sort();
    final String queryString = sortedKeys
        .map((key) => "$key=${Uri.encodeComponent(params[key].toString())}")
        .join('&');
    return "${customPrefix.trim()}#$baseUrl?$queryString";
  }
}