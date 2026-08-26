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

class PatientOverViewRepoImpl extends PatientOverViewRepo {
  final ApiClient _apiClient;
  final LocalCacheDataSource _localCache;
  final Connectivity _connectivity;

  PatientOverViewRepoImpl(
    this._apiClient,
    this._localCache, [
    Connectivity? connectivity,
  ]) : _connectivity = connectivity ?? Connectivity();

  @override
  Future<PatientOverViewEntity?> fetchOverViewData({
    required String userId,
    String? orgId,
    String? hospitalId,
  }) async {
    var endPoint = URLs.patientOverViewUrl;
    final currentUser = GlobalSession.instance.userNotifier.value;

    final dynamic finalOrgId = (orgId != null && orgId.trim().isNotEmpty)
        ? (int.tryParse(orgId.trim()) ?? orgId.trim())
        : 1;
    final dynamic finalHospId = (hospitalId != null && hospitalId.trim().isNotEmpty)
        ? (int.tryParse(hospitalId.trim()) ?? hospitalId.trim())
        : 1;

    var requestBody = {
      "patientId": userId,
      "orgId": finalOrgId,
      "hospitalId": finalHospId,
    };

    final String fullCacheKey = _generateDeterministicCacheKey(
      customPrefix: patientOverViewKey,
      baseUrl: endPoint,
      params: requestBody,
    );
    final List<ConnectivityResult> connectivityResults =
        await _connectivity.checkConnectivity();
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
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account(showSuccessSnack: false).post(
        endPoint,
        data: requestBody,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      dynamic rawBody = response.data;
      Map<String, dynamic>? rawData;
      if (rawBody is Map<String, dynamic>) {
        rawData = rawBody;
      } else if (rawBody is Map) {
        rawData = Map<String, dynamic>.from(rawBody);
      } else if (rawBody is String && rawBody.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawBody);
          if (decoded is Map) {
            rawData = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      if (rawData != null) {
        final bool isSuccessStatus =
            rawData['status'] == true || rawData['success'] == true;
        final dynamic nestedPayload =
            rawData['data'] ?? rawData['result'] ?? rawData['payload'];

        if (isSuccessStatus && nestedPayload != null) {
          try {
            await _localCache.saveResponse(fullCacheKey, jsonEncode(rawData));
          } catch (_) {}
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
  Future<PatientOverViewEntity?> fetchOverViewDirectFromKey(
      String cacheKey) async {
    try {
      final String? cachedJsonString =
          await _localCache.getCachedResponse(cacheKey);
      if (cachedJsonString != null && cachedJsonString.trim().isNotEmpty) {
        final dynamic decodedData = jsonDecode(cachedJsonString);
        if (decodedData is Map) {
          developer.log("Direct cache key fetch execution hit success.",
              name: "PatientOverViewRepoImpl");
          return PatientOverViewModel.fromJson(Map<String, dynamic>.from(decodedData));
        }
      }
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