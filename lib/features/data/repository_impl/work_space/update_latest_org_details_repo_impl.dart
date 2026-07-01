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
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      String token = currentUser?.data?.accessToken ?? '';

      final Map<String, dynamic> requestBody = {
        "userId": currentUser?.data?.id,
        "latestRoleId": latestRoleId,
        "latestOrgId":latestOrgId ,
        "latestHospitalId": latestHospitalId
      };
      final response = await apiClient.account.post(
        URLs.updateLatestOrgDetails,
        data: requestBody,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
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
