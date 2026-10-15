import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/features/domain/entities/work_space/update_latest_org_details_entity.dart';
import 'package:yiraclinics/features/domain/repositories/work_space/update_latest_org_details_repo.dart';

import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../models/work_space/update_latest_org_details_model.dart';

class UpdateLatestOrgDetailsRepoImpl extends UpdateLatestOrgDetailsRepo {
  final ApiClient apiClient;

  UpdateLatestOrgDetailsRepoImpl(this.apiClient);
  @override
  Future<UpdateLatestOrgDetailsEntity?> updateLatestOrgDetails({
    String? userId,
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      String token = currentUser?.data?.accessToken ?? '';

      final platFormData = GlobalSession.instance.platformNotifier.value ??
          GlobalSession.instance.cachedPlatformInfo;
      final String effectiveUserId = (userId != null && userId.trim().isNotEmpty)
          ? userId.trim()
          : (currentUser?.data?.id ?? '').trim();
      String deviceId = platFormData?.deviceId ?? '';
      if (deviceId.isEmpty || deviceId == 'unknown_id') {
        deviceId = (effectiveUserId.isNotEmpty)
            ? 'dev_$effectiveUserId'
            : 'device_${DateTime.now().millisecondsSinceEpoch}';
      }

      final Map<String, dynamic> requestBody = {
        "userId": effectiveUserId,
        "deviceId": deviceId,
        "latestRoleId": latestRoleId,
        "latestOrgId": latestOrgId,
        "latestHospitalId": latestHospitalId,
      };

      final Map<String, dynamic> headers = {
        HttpHeaders.contentTypeHeader: 'application/json',
        'x-user-id': effectiveUserId,
        'x-device-id': deviceId,
      };
      if (token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }

      final response = await apiClient
          .account(showSuccessSnack: true)
          .post(
            URLs.updateLatestOrgDetails,
            data: requestBody,
            options: Options(
              headers: headers,
            ),
          );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return UpdateLatestOrgDetailsModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        "Update latest org details failed inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "UpdateLatestOrgDetailsRepoImpl",
      );
      return null;
    }
  }
}
