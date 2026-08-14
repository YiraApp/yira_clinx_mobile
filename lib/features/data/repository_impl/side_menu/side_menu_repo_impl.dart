import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/data/models/side_menu/side_menu_model.dart';
import 'package:yiraclinics/features/domain/entities/side_menu/side_menu_entity.dart';
import 'package:yiraclinics/features/domain/repositories/side_menu/side_menu_repo.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/local/cache/local_cache_data_source.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';

class SideMenuRepoImpl extends SideMenuRepo {
  final ApiClient _apiClient;
  final LocalCacheDataSource _localCache;
  final Connectivity _connectivity;

  SideMenuRepoImpl(
    this._apiClient,
    this._localCache, [
    Connectivity? connectivity,
  ]) : _connectivity = connectivity ?? Connectivity();
  @override
  Future<SideMenuEntity?> fetchData({
    required String userId,
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId,
  }) async {
    var endPoint = URLs.sideMenuUrl;
    var requestBody = {
      "userId": userId.trim(),
      "latestRoleId": latestRoleId.trim(),
      "latestOrgId": latestOrgId,
      "latestHospitalId": latestHospitalId,
    };
    final String fullCacheKey = _generateDeterministicCacheKey(
      customPrefix: sideMenuKey,
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
        name: "SideMenuRepoImpl",
      );
      return fetchDirectFromKey(fullCacheKey);
    }
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account(showSuccessSnack: true).post(
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
          return SideMenuModel.fromJson(rawData);
        }
      }
    } on DioException catch (dioError) {
      developer.log(
        "Dio network error handled: ${dioError.type}. Recovering context gracefully via cache pipeline.",
        error: dioError,
        name: "SideMenuRepoImpl",
      );
    } catch (unexpectedError, stackTrace) {
      developer.log(
        "Unexpected formatting model processing exception occurred inside repository.",
        error: unexpectedError,
        stackTrace: stackTrace,
        name: "SideMenuRepoImpl",
      );
    }
    return fetchDirectFromKey(fullCacheKey);
  }

  @override
  Future<SideMenuEntity?> fetchDirectFromKey(String cacheKey)
  async {
    try {
      final String? cachedJsonString = await _localCache.getCachedResponse(
        cacheKey,
      );
      final Map<String, dynamic> mockJsonResponse = {
        "status": true,
        "message": "SideMenu Details fetched successfully",
        "data": [
          {
            "title": "Doctor Dashboard",
            "taskCode": "1",
            "taskId": 1,
            "ImagePath": "",
          },
          {
            "title": "Switch Organization",
            "taskCode": "2",
            "taskId": 2,
            "ImagePath": "",
          },
          {
            "title": "Appointments",
            "taskCode": "3",
            "taskId": 3,
            "ImagePath": "",
          },
          {"title": "Patients", "taskCode": "4", "taskId": 4, "ImagePath": ""},
          {
            "title": "Doctor  Slots",
            "taskCode": "5",
            "taskId": 5,
            "ImagePath": "",
          },
          {
            "title": "Read about us",
            "taskCode": "6",
            "taskId": 6,
            "ImagePath": "",
          },
          {
            "title": "Contact Us",
            "taskCode": "7",
            "taskId": 7,
            "ImagePath": "",
          },
          {
            "title": "Privacy Policy",
            "taskCode": "8",
            "taskId": 8,
            "ImagePath": "",
          },
          {"title": "Settings", "taskCode": "9", "taskId": 9, "ImagePath": ""},
        ],
      };

      return SideMenuModel.fromJson(mockJsonResponse);
      /*if (cachedJsonString != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedJsonString);
        developer.log("Direct cache key fetch execution hit success.", name: "SideMenuRepoImpl");
        return SideMenuModel.fromJson(decodedData);
      }*/
    } catch (cacheError, stackTrace) {
      developer.log(
        "Critical failure resolving direct database registers.",
        error: cacheError,
        stackTrace: stackTrace,
        name: "SideMenuRepoImpl",
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
