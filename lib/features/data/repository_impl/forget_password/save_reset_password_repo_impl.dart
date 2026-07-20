import 'dart:developer' as developer;

import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/features/data/models/common/common_model.dart';
import 'package:yiraclinics/features/domain/entities/common/common_entity.dart';

import '../../../../core/urls/urls.dart';
import '../../../domain/repositories/foget_password/save_reset_password_repo.dart';

class SaveResetPasswordRepoImpl extends SaveResetPasswordRepo {
  final ApiClient _apiClient;

  SaveResetPasswordRepoImpl(this._apiClient);

  @override
  Future<CommonEntity?> savePassword({
    required String identity,
    required String contactType,
    required String countryCode,
    required String newPassword,
    required String confirmPassword,
  })async {
    try {
      final Map<String, dynamic> requestBody = {
        "identity": identity.trim(),
        "contactType": contactType,
        "countryCode": countryCode,
        "newPassword": newPassword,
        "confirmPassword": confirmPassword
      };

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.saveResetPasswordURl,
        data: requestBody,
      );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return CommonModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        "Save password failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "SaveResetPasswordRepoImpl",
      );
      return null;
    }
  }
}
