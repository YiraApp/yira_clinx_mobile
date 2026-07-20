import 'dart:developer' as developer;

import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/features/data/models/forget_password/forget_password_send_otp_model.dart';
import 'package:yiraclinics/features/domain/entities/forget_password/forget_password_send_otp_entity.dart';

import '../../../../core/urls/urls.dart';
import '../../../domain/repositories/foget_password/forget_password_send_otp_repo.dart';

class ForgetPasswordSendOtpRepoImpl extends ForgetPasswordSendOtpRepo {
  final ApiClient _apiClient;

  ForgetPasswordSendOtpRepoImpl(this._apiClient);
  @override
  Future<ForgetPasswordSendOtpEntity?> sendOtp({
    required String identity,
    required String contactType,
    required String countryCode,
    required bool isResend,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "identity": identity.trim(),
        "contactType": contactType,
        "countryCode": countryCode.replaceAll('+', '').trim(),
        "isResend": isResend,
      };

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.forgetSendOtpURl,
        data: requestBody,
      );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else {
        return ForgetPasswordSendOtpModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        "forget password sendOtp failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "ForgetPasswordSendOtpRepoImpl",
      );
      return null;
    }
  }
}
