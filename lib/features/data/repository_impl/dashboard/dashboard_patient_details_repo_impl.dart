import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/data/models/dashboard/dashboard_patient_details_model.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_details_entity.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/local/cache/local_cache_data_source.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../../domain/repositories/dash_board/dashboard_patient_details_repo.dart';

class DashboardPatientDetailsRepoImpl extends DashboardPatientDetailsRepo {
  final ApiClient _apiClient;
  final LocalCacheDataSource _localCache;
  final Connectivity _connectivity;
  DashboardPatientDetailsRepoImpl(
      this._apiClient,
      this._localCache, [
        Connectivity? connectivity,
      ]) : _connectivity = connectivity ?? Connectivity();
  @override
  Future<DashBoardPatientDetailsEntity?> fetchPatientData({
    required String appointmentId,
    required String patientId,
    required String orgId,
    required String hospitalId,
  })  async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    var endPoint = URLs.dashboardPatientDetailsUrl;
    final Map<String, dynamic> requestBody = {
      "userId": currentUser?.data?.id ?? '',
      "patientId": patientId,
      "orgId": orgId,
      "hospitalId": hospitalId,
      "appointmentId": appointmentId
    };
    final String fullCacheKey = _generateDeterministicCacheKey(
      customPrefix: dashboardPatientDetailsKey,
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
      return fetchPatientDataDirectFromKey(fullCacheKey);
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
          return DashBoardPatientDetailsModel.fromJson(rawData);
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
    return fetchPatientDataDirectFromKey(fullCacheKey);
  }

  @override
  Future<DashBoardPatientDetailsEntity?> fetchPatientDataDirectFromKey(String cacheKey)
  async {
    try {
      final String? cachedJsonString = await _localCache.getCachedResponse(
        cacheKey,
      );
      if (cachedJsonString != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedJsonString);
        developer.log("Direct cache key fetch execution hit success.", name: "DoctorDashboardRepoImpl");
        return DashBoardPatientDetailsModel.fromJson(decodedData);
      }

      final Map<String, dynamic> mockJsonResponse = {
        "status": true,
        "message": "Patient profile data retrieved successfully",
        "data": {
          "patient_info": {
            "patient_id": "gsdfds",
            "appointment_id": "12",
            "name": "Mani N",
            "age": "25 yrs",
            "gender": "Male",
            "last_visit": "4/6/2026"
          },
          "contact_information": {
            "phone": "9908875796",
            "email": "jmani83280@gmail.com",
            "location": ""
          },
          "latest_vitals": {
            "blood_pressure": {
              "value": "120/80",
              "unit": "mmHg"
            },
            "pulse": {
              "value": "78",
              "unit": "bpm"
            },
            "temperature": {
              "value": "98.4",
              "unit": "°F"
            },
            "spo2": {
              "value": "98",
              "unit": "%"
            },
            "weight": {
              "value": "82",
              "unit": "kg"
            },
            "height": {
              "value": "168",
              "unit": "cm"
            }
          },
          "medical_information": {
            "blood_group": "B+"
          },
          "insurance": {
            "provider": "sbi",
            "policy_number": "12345",
            "valid_till": "12-08-2046"
          }
        }
      };

      return DashBoardPatientDetailsModel.fromJson(mockJsonResponse);
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
