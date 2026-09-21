import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/domain/repositories/configuration/configuration_repo.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/clinx_storage_keys.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/local/shared_preferences.dart';
import '../../../../core/urls/urls.dart';
import '../../../../di/dependency_injection.dart';
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
      final platFormData = GlobalSession.instance.platformNotifier.value ??
          GlobalSession.instance.cachedPlatformInfo;
      String deviceId = platFormData?.deviceId ?? '';
      if (deviceId.isEmpty || deviceId == 'unknown_id') {
        deviceId = (currentUser?.data?.id != null && currentUser!.data!.id!.isNotEmpty)
            ? 'dev_${currentUser.data!.id}'
            : 'device_${DateTime.now().millisecondsSinceEpoch}';
      }
      final Map<String, dynamic> requestBody = {
        "userId": currentUser?.data?.id ?? '',
        "deviceId": deviceId,
      };
      final Map<String, dynamic> headers = {
        HttpHeaders.contentTypeHeader: 'application/json',
        'x-user-id': currentUser?.data?.id ?? '',
        'x-device-id': deviceId,
      };
      if (token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
      final response = await _apiClient.account(showSuccessSnack: false).get(
        URLs.getUserDataUrl,
        queryParameters: requestBody,
        options: Options(
          headers: headers,
          extra: {'suppressSessionExpired': true},
        ),
      );
      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return LoginModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (error, stackTrace) {
      if (error is DioException && error.response?.statusCode == HttpStatus.unauthorized) {
        // Token is unauthorized (e.g. environment switch QA -> DEV).
        // Clear the stale session so app transitions cleanly to Login.
        await GlobalSession.instance.clear();
        await sl<SharedPrefsService>().remove(ClinxStorageKeys.isUserLoggedIn);
      }
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
