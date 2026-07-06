/*
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:yiraclinics/features/data/models/dashboard/doctor_dashbaord_model.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/doctor_dashboard_entity.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../../domain/repositories/dash_board/doctor_dashboard_repo.dart';

class DoctorDashboardRepoImpl extends DoctorDashboardRepo {
  final ApiClient _apiClient;
  DoctorDashboardRepoImpl(this._apiClient);
  @override
  Future<DoctorDashboardEntity?> fetchData({
    required String userId,
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId,
  })  async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      String token = currentUser?.data?.accessToken ?? '';
      final Map<String, dynamic> queryParameters = {
        "userId": userId.trim(),
        "latestRoleId": latestRoleId.trim(),
        "latestOrgId": latestOrgId,
        "latestHospitalId": latestHospitalId,
      };
      final response = await _apiClient.account.get(
        URLs.doctorDashBoardUrl,
        queryParameters: queryParameters,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return DoctorDashBoardModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        "doctor details failed inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "DoctorDashboardRepoImpl",
      );
      return null;
    }
  }
}
*/
import 'dart:developer' as developer;

import 'package:yiraclinics/features/data/models/dashboard/doctor_dashbaord_model.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/doctor_dashboard_entity.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/repositories/dash_board/doctor_dashboard_repo.dart';

/*
class DoctorDashboardRepoImpl extends DoctorDashboardRepo {
  final ApiClient _apiClient;

  DoctorDashboardRepoImpl(this._apiClient);

  @override
  Future<DoctorDashboardEntity?> fetchData({
    required String userId,
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final Map<String, dynamic> mockJsonResponse = {
        "status": true,
        "message": "Login successful! Welcome back.",
        "data": {
          "profile": {
            "name": "Dr. Rajesh Nagalingam",
            "specialty": "Dentist",
            "clinicAddress": "Ocimum dental clinic, Journalist colony, Hyd 500034"
          },
          "metrics": {
            "today": {"title": "Today", "value": 2, "subtext": "01 completed"},
            "patients": {"title": "Patients", "value": 4, "subtext": "01 new this week"},
            "done": {"title": "Done", "value": 10, "subtext": "04 follow-ups"},
            "stats": {"title": "Stats", "value": 10, "subtext": "05 new patients"}
          },
          "todaysSchedule": [
            {
              "patientUserId": 1,
              "orgId": 1,
              "hospitalId": 1,
              "appointmentId": 1,
              "patientName": "Sarah Jenkins",
              "time": "09:30 AM",
              "consultationType": "Teleconsultation",
              "reason": "Follow-up Consultation",
              "statusTag": "LIVE VIDEO"
            },
            {
              "patientUserId": 2,
              "orgId": 2,
              "hospitalId": 2,
              "appointmentId": 2,
              "patientName": "Sara Alikhan",
              "time": "10:30 AM",
              "consultationType": "Teleconsultation",
              "reason": "Follow-up Consultation",
              "statusTag": "LIVE VIDEO"
            }
          ],
          "recentPatients": [
            {
              "patientUserId": 1,
              "orgId": 1,
              "hospitalId": 1,
              "appointmentId": 1,
              "name": "Mani Jay",
              "date": "19/5/2026",
              "consultationType": "Historical Consultation",
              "condition": "Acute Migraine headaches",
              "status": "COMPLETED"
            },
            {
              "patientUserId": 2,
              "orgId": 2,
              "hospitalId": 2,
              "appointmentId": 2,
              "name": "Anil Kumar",
              "date": "18/5/2026",
              "consultationType": "Historical Consultation",
              "condition": "Common Cold & Nasal Congestion",
              "status": "COMPLETED"
            }
          ],
          "weeklyAppointments": {
            "averagePerDay": 3,
            "dailyData": [
              {"label": "MON", "value": 40},
              {"label": "TUE", "value": 30},
              {"label": "WED", "value": 20},
              {"label": "THU", "value": 20},
              {"label": "FRI", "value": 50},
              {"label": "SAT", "value": 30},
              {"label": "SUN", "value": 10}
            ]
          },
          "monthlyPatients": {
            "yearlyTotal": 156,
            "monthlyData": [
          {"label": "JAN", "value": 12},
          {"label": "FEB", "value": 18},
          {"label": "MAR", "value": 22},
          {"label": "APR", "value": 28},
          {"label": "MAY", "value": 5},
          {"label": "JUN", "value": 8},
          {"label": "JUL", "value": 18},
          {"label": "AUG", "value": 24},
          {"label": "SEP", "value": 20},
          {"label": "OCT", "value": 15},
        {"label": "NOV", "value": 15},
        {"label": "DEC", "value": 8}
    ]
    }
    }
    };

    return DoctorDashBoardModel.fromJson(mockJsonResponse);

    } catch (error, stackTrace) {
    developer.log(
    "doctor details failed inside mock repository layer",
    error: error,
    stackTrace: stackTrace,
    name: "DoctorDashboardRepoImpl",
    );
    return null;
    }
  }
}*/
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/core/local/cache/local_cache_data_source.dart';

class DoctorDashboardRepoImpl extends DoctorDashboardRepo {
  final ApiClient _apiClient;
  final LocalCacheDataSource _localCache;
  final Connectivity _connectivity;

  DoctorDashboardRepoImpl(
    this._apiClient,
    this._localCache, [
    Connectivity? connectivity,
  ]) : _connectivity = connectivity ?? Connectivity();

  @override
  Future<DoctorDashboardEntity?> fetchData({
    required String userId,
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId,
  }) async {
    final Map<String, dynamic> requestBody = {
      "userId": userId.trim(),
      "latestRoleId": latestRoleId.trim(),
      "latestOrgId": latestOrgId,
      "latestHospitalId": latestHospitalId,
    };
    final String fullCacheKey = _generateDeterministicCacheKey(
      customPrefix: doctorDashboardKey,
      baseUrl: URLs.doctorDashBoardUrl,
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
      return fetchDirectFromKey(fullCacheKey);
    }

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account.get(
        URLs.doctorDashBoardUrl,
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
          return DoctorDashBoardModel.fromJson(rawData);
        }
      }
    } on DioException catch (dioError) {
      developer.log(
        "Dio network error handled: ${dioError.type}. Recovering context gracefully via cache pipeline.",
        error: dioError,
        name: "DoctorDashboardRepoImpl",
      );
    } catch (unexpectedError, stackTrace) {
      developer.log(
        "Unexpected formatting model processing exception occurred inside repository.",
        error: unexpectedError,
        stackTrace: stackTrace,
        name: "DoctorDashboardRepoImpl",
      );
    }

    return fetchDirectFromKey(fullCacheKey);
  }

  @override
  Future<DoctorDashboardEntity?> fetchDirectFromKey(String cacheKey) async {
    try {
      final String? cachedJsonString = await _localCache.getCachedResponse(
        cacheKey,
      );
      final Map<String, dynamic> mockJsonResponse = {
        "status": true,
        "message": "Login successful! Welcome back.",
        "data": {
          "profile": {
            "name": "Dr. Rajesh Nagalingam",
            "specialty": "Dentist",
            "clinicAddress":
                "Ocimum dental clinic, Journalist colony, Hyd 500034",
          },
          "metrics": {
            "today": {"title": "Today", "value": 2, "subtext": "01 completed"},
            "patients": {
              "title": "Patients",
              "value": 4,
              "subtext": "01 new this week",
            },
            "done": {"title": "Done", "value": 10, "subtext": "04 follow-ups"},
            "stats": {
              "title": "Stats",
              "value": 10,
              "subtext": "05 new patients",
            },
          },
          "todaysSchedule": [
            {
              "patientUserId": 1,
              "orgId": 1,
              "hospitalId": 1,
              "appointmentId": 1,
              "patientName": "Sarah Jenkins",
              "time": "09:30 AM",
              "consultationType": "Teleconsultation",
              "reason": "Follow-up Consultation",
              "statusTag": "LIVE VIDEO",
            },
            {
              "patientUserId": 2,
              "orgId": 2,
              "hospitalId": 2,
              "appointmentId": 2,
              "patientName": "Sara Alikhan",
              "time": "10:30 AM",
              "consultationType": "Teleconsultation",
              "reason": "Follow-up Consultation",
              "statusTag": "LIVE VIDEO",
            },
          ],
          "recentPatients": [
            {
              "patientUserId": 1,
              "orgId": 1,
              "hospitalId": 1,
              "appointmentId": 1,
              "name": "Mani Jay",
              "date": "19/5/2026",
              "consultationType": "Historical Consultation",
              "condition": "Acute Migraine headaches",
              "status": "COMPLETED",
            },
            {
              "patientUserId": 2,
              "orgId": 2,
              "hospitalId": 2,
              "appointmentId": 2,
              "name": "Anil Kumar",
              "date": "18/5/2026",
              "consultationType": "Historical Consultation",
              "condition": "Common Cold & Nasal Congestion",
              "status": "COMPLETED",
            },
          ],
          "weeklyAppointments": {
            "averagePerDay": 3,
            "dailyData": [
              {"label": "MON", "value": 40},
              {"label": "TUE", "value": 30},
              {"label": "WED", "value": 20},
              {"label": "THU", "value": 20},
              {"label": "FRI", "value": 50},
              {"label": "SAT", "value": 30},
              {"label": "SUN", "value": 10},
            ],
          },
          "monthlyPatients": {
            "yearlyTotal": 156,
            "monthlyData": [
              {"label": "JAN", "value": 12},
              {"label": "FEB", "value": 18},
              {"label": "MAR", "value": 22},
              {"label": "APR", "value": 28},
              {"label": "MAY", "value": 5},
              {"label": "JUN", "value": 8},
              {"label": "JUL", "value": 18},
              {"label": "AUG", "value": 24},
              {"label": "SEP", "value": 20},
              {"label": "OCT", "value": 15},
              {"label": "NOV", "value": 15},
              {"label": "DEC", "value": 8},
            ],
          },
        },
      };

      return DoctorDashBoardModel.fromJson(mockJsonResponse);
      /*if (cachedJsonString != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedJsonString);
        developer.log("Direct cache key fetch execution hit success.", name: "DoctorDashboardRepoImpl");
        return DoctorDashBoardModel.fromJson(decodedData);
      }*/
    } catch (cacheError, stackTrace) {
      developer.log(
        "Critical failure resolving direct database registers.",
        error: cacheError,
        stackTrace: stackTrace,
        name: "DoctorDashboardRepoImpl",
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
