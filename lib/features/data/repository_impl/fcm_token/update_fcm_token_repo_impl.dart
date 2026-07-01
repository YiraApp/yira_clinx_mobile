import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/domain/entities/fcm_token/update_fcm_token_entity.dart';
import 'package:yiraclinics/features/domain/repositories/fcm_token/update_fcm_token_repo.dart';
import 'package:yiraclinics/features/data/models/fcm_token/update_fcm_token_model.dart';

class UpdateFcmRepoImpl extends UpdateFcmRepository {
  final ApiClient _apiClient;

  UpdateFcmRepoImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<FcmTokenEntity?> updateFcmToken({required String fcmToken}) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final platFormData = GlobalSession.instance.platformNotifier.value;

      final String token = currentUser?.data?.accessToken ?? '';

      final Map<String, dynamic> requestBody = {
        "userId": currentUser?.data?.id ?? '',
        "platform": platFormData?.platform ?? Platform.operatingSystem,
        "currentVersion": platFormData?.version ?? '1.0.0',
        "deviceId": platFormData?.deviceId ?? 'unknown_id',
        "fcmToken": fcmToken,
      };

      final response = await _apiClient.account.post(
        URLs.updateFcmTokenUrl,
        data: requestBody,
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return UpdateFcmTokenModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        "updateFcmToken failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: 'UpdateFcmRepoImpl',
      );
      return null;
    }
  }
}
