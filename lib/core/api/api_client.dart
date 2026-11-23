/*




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
*/
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../error_interceptor/error_interceptor.dart';
import '../local/global_session.dart';
import 'base_api_configuration.dart';

enum ApiType { account, health }

class ApiClient {
  String get _accountBaseUrl => EnvironmentService.config.accountBaseUrl;
  String get _healthBaseUrl => EnvironmentService.config.healthCampBaseUrl;

  final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal();

  /// One Dio per base URL and snack setting. A new Dio per call opened a new
  /// connection (TCP + TLS handshake) for every request; reusing one keeps the
  /// connection alive between calls. The token is still read on each request.
  final Map<String, Dio> _dios = {};

  Dio _createDio(String baseUrl, bool showSuccessSnack) =>
      _dios.putIfAbsent('$showSuccessSnack|${baseUrl.trim()}', () => _buildDio(baseUrl, showSuccessSnack));

  Dio _buildDio(String baseUrl, bool showSuccessSnack) {
    String formattedUrl = baseUrl.trim();
    if (!formattedUrl.startsWith("http://") && !formattedUrl.startsWith("https://")) {
      if (formattedUrl.contains("192.168.") ||
          formattedUrl.contains("10.") ||
          formattedUrl.contains("localhost") ||
          formattedUrl.contains(":")) {
        formattedUrl = "http://$formattedUrl";
      } else {
        formattedUrl = "https://$formattedUrl";
      }
    }
    while (formattedUrl.endsWith("/")) {
      formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: formattedUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
            options.headers.remove('content-type');
            options.contentType = null;
          }
          // Every call to our API carries the session token, unless the caller set its own.
          final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
          final isOwnApi = options.uri.host == Uri.parse(formattedUrl).host;
          if (isOwnApi && token.isNotEmpty && options.headers[HttpHeaders.authorizationHeader] == null) {
            options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    dio.interceptors.add(ErrorInterceptor(showSuccessSnack: showSuccessSnack));

    return dio;
  }

  Dio client(ApiType type, {bool showSuccessSnack = true}) {
    switch (type) {
      case ApiType.account:
        return _createDio(_accountBaseUrl, showSuccessSnack);
      case ApiType.health:
        return _createDio(_healthBaseUrl, showSuccessSnack);
    }
  }

  Dio account({bool showSuccessSnack = true}) => _createDio(_accountBaseUrl, showSuccessSnack);
  Dio health({bool showSuccessSnack = true}) => _createDio(_healthBaseUrl, showSuccessSnack);
}