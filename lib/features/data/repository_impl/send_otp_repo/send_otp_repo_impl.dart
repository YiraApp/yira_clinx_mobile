import 'dart:developer' as developer;
import 'package:yiraclinics/core/urls/urls.dart';

import '../../../../core/api/api_client.dart';
import '../../../domain/entities/send_otp/send_otp_entity.dart';
import '../../../domain/repositories/send_otp/send_otp_repo.dart';
import '../../models/send_otp/send_otp_model.dart'; // Adjust path

class SendOtpRepositoryImpl implements SendOtpRepo {
  final ApiClient _apiClient;

  const SendOtpRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<SendOtpEntity?> sendOtp({
    required String mobileNumber,
    required String countryCode,
    required bool isReSend,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "identity": mobileNumber.trim(),
        "countryCode": countryCode.replaceAll('+', '').trim(),
        "isResend": isReSend,
      };

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.sendOtpUrl,
        data: requestBody,
      );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      }

      return SendOtpModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error, stackTrace) {
      developer.log(
        "sendOtp failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "SendOtpRepositoryImpl",
      );
      return null;
    }
  }
}
