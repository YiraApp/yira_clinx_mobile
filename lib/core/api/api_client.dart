



import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../error_interceptor/error_interceptor.dart';
import 'base_api_configuration.dart';

enum ApiType { account, health }

class ApiClient {
  late final Dio _accountDio;
  late final Dio _healthDio;

  final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _accountDio = _createDio(EnvironmentService.config.accountBaseUrl);
    _healthDio = _createDio(EnvironmentService.config.healthCampBaseUrl);
  }

  Dio _createDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: "https://$baseUrl",
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(ErrorInterceptor());

    return dio;
  }

  Dio client(ApiType type) {
    switch (type) {
      case ApiType.account:
        return _accountDio;
      case ApiType.health:
        return _healthDio;
    }
  }

  Dio get account => _accountDio;
  Dio get health => _healthDio;
}
