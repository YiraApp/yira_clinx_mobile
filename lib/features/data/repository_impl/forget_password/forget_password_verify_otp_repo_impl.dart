import 'dart:developer' as developer;

import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/features/domain/entities/forget_password/forget_password_verify_otp_enity.dart';

import '../../../../core/urls/urls.dart';
import '../../../domain/repositories/foget_password/forget_password_verify_otp_repo.dart';
import '../../models/forget_password/forget_passord_verify_otp_model.dart';

class ForgetPasswordVerifyOtpRepoImpl extends ForgetPasswordVerifyOtpRepo {
  final ApiClient _apiClient;

  ForgetPasswordVerifyOtpRepoImpl(this._apiClient);

  @override
  Future<ForgetPasswordVerifyOtpEntity?> verifyOtp({
    required String identity,
    required String contactType,
    required String countryCode,
    required String sessionId,
    required String otp,
  })
  async {
    try {
      final Map<String, dynamic> requestBody = {
        "identity": identity.trim(),
        "contactType": contactType,
        "countryCode": countryCode,
        "sessionId": sessionId,
        "otp": otp,
      };

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.forgetVerifyOtpURl,
        data: requestBody,
      );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return ForgetPasswordVerifyOtpModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        "forget password Verify Otp failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "ForgetPasswordVerifyOtpRepoImpl",
      );
      return null;
    }
  }
}
