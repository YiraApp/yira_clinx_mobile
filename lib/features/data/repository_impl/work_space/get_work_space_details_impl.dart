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
  })
  async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      String token = currentUser?.data?.accessToken ?? '';

      final Map<String, dynamic> queryParameters = {
        "userId": userId.trim(),
        "roleId": roleId.trim(),
      };
      final response = await _apiClient.account.get(
        URLs.workspaceDetailsUrl,
        queryParameters: queryParameters,

        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
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
