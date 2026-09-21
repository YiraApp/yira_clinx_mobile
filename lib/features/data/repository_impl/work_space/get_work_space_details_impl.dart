import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:yiraclinics/features/data/models/work_space/get_work_space_model.dart';
import 'package:yiraclinics/features/domain/entities/work_space/get_work_space_entity.dart';
import 'package:yiraclinics/features/domain/repositories/work_space/get_work_space_details_repo.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';

class GetWorkSpaceDetailsImpl extends GetWorkSpaceDetailsRepo {
  final ApiClient _apiClient;
  GetWorkSpaceDetailsImpl({required ApiClient apiClient})
    : _apiClient = apiClient;
  @override
  Future<GetWorkSpaceDetailsEntity?> getWorkSpaceDetails({
    required String userId,
    required String roleId,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      String token = currentUser?.data?.accessToken ?? '';

      final platFormData = GlobalSession.instance.platformNotifier.value ??
          GlobalSession.instance.cachedPlatformInfo;
      String deviceId = platFormData?.deviceId ?? '';
      if (deviceId.isEmpty || deviceId == 'unknown_id') {
        deviceId = (userId.trim().isNotEmpty)
            ? 'dev_${userId.trim()}'
            : 'device_${DateTime.now().millisecondsSinceEpoch}';
      }

      final Map<String, dynamic> queryParameters = {
        "userId": userId.trim(),
        "roleId": roleId.trim(),
        "deviceId": deviceId,
      };

      final Map<String, dynamic> headers = {
        HttpHeaders.contentTypeHeader: 'application/json',
        'x-user-id': userId.trim(),
        'x-device-id': deviceId,
      };
      if (token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }

      final response = await _apiClient
          .account(showSuccessSnack: false)
          .get(
            URLs.workspaceDetailsUrl,
            queryParameters: queryParameters,
            options: Options(
              headers: headers,
              extra: {'suppressSessionExpired': true},
            ),
          );
      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return GetWorkSpaceDetailsModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        "getWorkSpaceDetails failed inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "GetWorkSpaceDetailsImpl",
      );
      return null;
    }
  }
}
