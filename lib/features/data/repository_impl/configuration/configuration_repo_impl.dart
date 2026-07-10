import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/domain/repositories/configuration/configuration_repo.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../models/login/login_model.dart';

class ConfigurationRepoImpl extends ConfigurationRepo {
  final ApiClient _apiClient;

  ConfigurationRepoImpl({required ApiClient apiClient})
    : _apiClient = apiClient;
  @override
  Future<LoginEntity?> getUserData() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      String token = currentUser?.data?.accessToken ?? '';
      final platFormData =  GlobalSession.instance.platformNotifier.value;
      final Map<String, dynamic> requestBody = {
        "userId": currentUser?.data?.id,
        "deviceId": platFormData?.deviceId,
      };
      final response = await _apiClient.account(showSuccessSnack: true).get(
        URLs.getUserDataUrl,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
        data: requestBody,
      );
      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return LoginModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (error, stackTrace) {
      developer.log(
        "getUserData failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: 'LoginRepositoryImpl',
      );
      return null;
    }
  }
}
