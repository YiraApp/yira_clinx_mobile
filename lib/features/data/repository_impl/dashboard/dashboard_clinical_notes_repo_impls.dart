import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:yiraclinics/features/data/models/dashboard/dashboard_patient_clinical_notes_model.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_clinical_notes_entity.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/cache/local_cache_data_source.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../../domain/repositories/dash_board/dashboard_patient_clinical_notes_repo.dart';

class DashboardClinicalNotesRepoImpl extends DashboardPatientClinicalNotesRepo {
  final ApiClient _apiClient;
  final LocalCacheDataSource _localCache;
  final Connectivity _connectivity;
  DashboardClinicalNotesRepoImpl(
      this._apiClient,
      this._localCache, [
        Connectivity? connectivity,
      ]) : _connectivity = connectivity ?? Connectivity();
  @override
  Future<DashBoardPatientDetailsClinicalNotesEntity?> fetchPatientClinicalData({
    required String appointmentId,
    required String patientId,
    required String orgId,
    required String hospitalId,
  })
  async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final Map<String, dynamic> requestBody = {
      "userId": currentUser?.data?.id ?? '',
      "patientId": patientId,
      "orgId": orgId,
      "hospitalId": hospitalId,
      "appointmentId": appointmentId
    };
    var endPoint = URLs.dashboardPatientClinicalDetailsUrl;
    final String fullCacheKey = _generateDeterministicCacheKey(
      customPrefix: dashboardPatientClinicalDetailsKey,
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
        name: "DoctorDashboardRepoImpl",
      );
      return fetchPatientClinicalDataDirectFromKey(fullCacheKey);
    }
    try {
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account(showSuccessSnack: false).post(
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
          return DashBoardPatientDetailsClinicalNotesModel.fromJson(rawData);
        }
      }
    } on DioException catch (dioError) {
      developer.log(
        "Dio network error handled: ${dioError.type}. Recovering context gracefully via cache pipeline.",
        error: dioError,
        name: "DashboardClinicalNotesRepoImpl",
      );
    } catch (unexpectedError, stackTrace) {
      developer.log(
        "Unexpected formatting model processing exception occurred inside repository.",
        error: unexpectedError,
        stackTrace: stackTrace,
        name: "DashboardClinicalNotesRepoImpl",
      );
    }
    return fetchPatientClinicalDataDirectFromKey(fullCacheKey);
  }

  @override
  Future<DashBoardPatientDetailsClinicalNotesEntity?>
  fetchPatientClinicalDataDirectFromKey(String cacheKey)
  async {
    try {
      final String? cachedJsonString = await _localCache.getCachedResponse(
        cacheKey,
      );
      if (cachedJsonString != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedJsonString);
        developer.log("Direct cache key fetch execution hit success.", name: "DoctorDashboardRepoImpl");
        return DashBoardPatientDetailsClinicalNotesModel.fromJson(decodedData);
      }

      final Map<String, dynamic> mockJsonResponse = {
        "status": true,
        "message": "Patient clinical data retrieved successfully",
        "data": {
          "clinical_notes": [
            {
              "id": 1,
              "doctor_name": "Dr. bhargav c",
              "date": "Jun 05",
              "note": "sdfdsmnfdsfkfds"
            },
            {
              "id": 2,
              "doctor_name": "Dr. bhargav c",
              "date": "Jun 05",
              "note": "ljfsajnfkfsdfds"
            },
            {
              "id": 3,
              "doctor_name": "Dr. bhargav c",
              "date": "Jun 04",
              "note": "hello"
            }
          ]
        }
      };

      return DashBoardPatientDetailsClinicalNotesModel.fromJson(mockJsonResponse);
    } catch (cacheError, stackTrace) {
      developer.log(
        "Critical failure resolving direct database registers.",
        error: cacheError,
        stackTrace: stackTrace,
        name: "DashboardClinicalNotesRepoImpl",
      );
    }
    return null;
  }
  String _generateDeterministicCacheKey({
    required String customPrefix,
    required String baseUrl,
    required Map<String, dynamic> params,
  })
  {
    final sortedKeys = params.keys.toList()..sort();
    final String queryString = sortedKeys
        .map((key) => "$key=${Uri.encodeComponent(params[key].toString())}")
        .join('&');
    return "${customPrefix.trim()}#$baseUrl?$queryString";
  }
}
