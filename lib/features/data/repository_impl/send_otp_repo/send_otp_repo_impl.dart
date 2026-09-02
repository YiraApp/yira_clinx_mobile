import 'dart:developer' as developer;
import 'package:dio/dio.dart';
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
      if (error is DioException && error.response?.data != null) {
        final responseData = error.response!.data;
        if (responseData is Map<String, dynamic>) {
          try {
            return SendOtpModel.fromJson(responseData);
          } catch (e) {
            developer.log("Failed parsing error response JSON", error: e);
          }
        }
      }
      return null;
    }
  }

  @override
  Future<SendOtpEntity?> sendSignupOtp({
    required String mobileNumber,
    required String countryCode,
    String? email,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "phoneNumber": mobileNumber.trim(),
        "identity": mobileNumber.trim(),
        "countryCode": countryCode.replaceAll('+', '').trim(),
        if (email != null && email.trim().isNotEmpty) "email": email.trim(),
      };

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.signupOtpUrl,
        data: requestBody,
      );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      }

      return SendOtpModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error, stackTrace) {
      developer.log(
        "sendSignupOtp failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "SendOtpRepositoryImpl",
      );
      if (error is DioException) {
        if (error.response?.data != null && error.response!.data is Map<String, dynamic>) {
          try {
            return SendOtpModel.fromJson(error.response!.data as Map<String, dynamic>);
          } catch (e) {
            developer.log("Failed parsing error response JSON", error: e);
          }
        }
        final String? msg = error.response?.data is Map
            ? error.response?.data['message']?.toString()
            : error.message;
        return SendOtpModel(
          status: false,
          message: msg ?? "Failed to send signup verification code.",
        );
      }
      return null;
    }
  }
}
