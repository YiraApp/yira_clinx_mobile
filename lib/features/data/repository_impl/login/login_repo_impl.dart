import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/urls/urls.dart';

import '../../../../core/api/api_client.dart';
import '../../../domain/entities/login/login_entity.dart';
import '../../../domain/repositories/login/login_repo.dart';
import '../../models/login/login_model.dart';

class LoginRepositoryImpl implements LoginRepository {
  final ApiClient _apiClient;

  const LoginRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<LoginEntity?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "identity": email,
        "password": password,
        "loginType": "email",
      };
      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.loginUrl,
        data: requestBody,
      );

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      } else{
        return LoginModel.fromJson(response.data as Map<String, dynamic>);

      }
    } catch (error, stackTrace) {
      developer.log(
        "loginWithEmail failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "LoginRepositoryImpl",
      );
      return null;
    }
  }

  @override
  Future<LoginEntity?> loginWithMobile({
    required String mobileNumber,
    required String otp,
    required String sessionId,
    String? countryCode,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "identity": mobileNumber,
        "password": otp,
        "sessionId": sessionId,
        "loginType": "mobileNumber",
        if (countryCode != null && countryCode.isNotEmpty)
          "countryCode": countryCode.replaceAll('+', '').trim(),
      };
      debugPrint('login requestBody --$requestBody');

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.loginUrl,
        data: requestBody,
      );
      debugPrint('login response --$response');

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      }

      return LoginModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error, stackTrace) {
      developer.log(
        "loginWithMobile failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "LoginRepositoryImpl",
      );
      return null;
    }
  }

  @override
  Future<LoginEntity?> registerPatient({
    required String firstName,
    required String lastName,
    String? email,
    required String mobileNumber,
    required String countryCode,
    required String password,
    required String otp,
    required String sessionId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "firstName": firstName.trim(),
        "lastName": lastName.trim(),
        if (email != null && email.trim().isNotEmpty) "email": email.trim(),
        "phoneNumber": mobileNumber.trim(),
        "identity": mobileNumber.trim(),
        "countryCode": countryCode.replaceAll('+', '').trim(),
        "password": password,
        "otp": otp.trim(),
        "sessionId": sessionId.trim(),
      };
      debugPrint('register requestBody --$requestBody');

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.registrationUrl,
        data: requestBody,
      );
      debugPrint('register response --$response');

      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      }

      return LoginModel.fromJson(response.data as Map<String, dynamic>);
    } catch (error, stackTrace) {
      developer.log(
        "registerPatient failed gracefully inside repository layer",
        error: error,
        stackTrace: stackTrace,
        name: "LoginRepositoryImpl",
      );
      if (error is DioException) {
        if (error.response?.data != null && error.response!.data is Map<String, dynamic>) {
          try {
            return LoginModel.fromJson(error.response!.data as Map<String, dynamic>);
          } catch (e) {
            developer.log("Failed parsing error response JSON", error: e);
          }
        }
        final String? msg = error.response?.data is Map
            ? error.response?.data['message']?.toString()
            : error.message;
        return LoginModel(
          status: false,
          message: msg ?? "Registration failed. Please try again.",
        );
      }
      return null;
    }
  }
}
