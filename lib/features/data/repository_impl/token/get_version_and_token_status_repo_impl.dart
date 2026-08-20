import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/features/data/models/token/get_version_and_token_status_model.dart';
import 'package:yiraclinics/features/domain/entities/token/get_version_and_token_status_entity.dart';
import 'package:yiraclinics/features/domain/repositories/token/get_version_and_token_status_repo.dart';

import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';

class GetVersionAndTokenStatusRepoImpl extends GetVersionAndTokenStatusRepo {
  final ApiClient apiClient;

  GetVersionAndTokenStatusRepoImpl(this.apiClient);
  @override
  Future<VersionTokenStatusEntity?> getVersionAndTokenStatus() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      String token = currentUser?.data?.accessToken ?? '';
      final platFormData = GlobalSession.instance.platformNotifier.value;
      final String osPlatform = Platform.isIOS ? 'ios' : 'android';
      final String platform = (platFormData?.platform != null && platFormData!.platform.isNotEmpty)
          ? (platFormData.platform.toLowerCase().contains('ios') ? 'ios' : 'android')
          : osPlatform;
      final Map<String, dynamic> requestBody = {
        "platform": platform,
        "currentVersion": platFormData?.version ?? '1.0.0',
        "deviceId": platFormData?.deviceId ?? 'unknown_id',
      };
      final response = await apiClient.account(showSuccessSnack: false).post(
        URLs.getVersionAndTokenStatus,
        data: requestBody,
        options: Options(
          extra: {'showSuccessSnack': false},
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return GetVersionAndTokenStatusModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        "get version and token status failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "GetVersionAndTokenStatusRepoImpl",
      );
      return null;
    }
  }
}
