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
      "doctorId": userId.trim(),
      "orgId": latestOrgId,
      "hospitalId": latestHospitalId,
    };
    var endPoint = URLs.doctorDashBoardUrl;
    final String fullCacheKey = _generateDeterministicCacheKey(
      customPrefix: doctorDashboardKey,
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
      return fetchDirectFromKey(fullCacheKey);
    }

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient
          .account(showSuccessSnack: true)
          .post(
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
      if (cachedJsonString != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedJsonString);
        developer.log(
          "Direct cache key fetch execution hit success.",
          name: "DoctorDashboardRepoImpl",
        );
        return DoctorDashBoardModel.fromJson(decodedData);
      }
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
