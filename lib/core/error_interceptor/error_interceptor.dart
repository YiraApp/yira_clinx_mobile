import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/base_api_configuration.dart';
import '../constants/constants.dart';
import '../expention_handler/exception_handler.dart';
import '../local/global_session.dart';
import '../urls/urls.dart';

class ErrorInterceptor extends Interceptor {
  final bool showSuccessSnack;
  static bool _isRefreshing = false;

  ErrorInterceptor({this.showSuccessSnack = true});
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return handler.next(response);
    }
    final bool isSuccess = data['status'] ?? true;
    final String? serverMessage = data['message']?.toString();

    if (!isSuccess) {
      final bool suppressErrorSnack =
          response.requestOptions.extra['suppressErrorSnack'] == true ||
          response.requestOptions.path.toLowerCase().contains('device-token');

      if (!suppressErrorSnack) {
        ExceptionHandler.processException(
          status: false,
          statusCode: HttpStatus.ok,
          message: serverMessage,
        );
      }

      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: serverMessage ?? 'Business logic failure',
        ),
      );
    }
    // Success toasts intentionally disabled — only error toasts are shown
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    int statusCode = err.response?.statusCode ?? 0;

    switch (err.type) {
      case DioExceptionType.connectionError:
        statusCode = socket_exception;
        break;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        statusCode = HttpStatus.gatewayTimeout;
        break;
      case DioExceptionType.cancel:
        return handler.next(err);
      default:
        break;
    }

    String? displayMessage;
    final responseData = err.response?.data;
    if (responseData is Map<String, dynamic>) {
      displayMessage = responseData['message']?.toString();
    }
    displayMessage ??= err.message;

    final String path = err.requestOptions.path.toLowerCase();
    final bool isAuthEndpoint = path.contains('login') ||
        path.contains('register') ||
        path.contains('signup') ||
        path.contains('sendotp') ||
        path.contains('verify') ||
        path.contains('forgot') ||
        path.contains('reset') ||
        path.contains('refresh');

    // Attempt transparent token refresh on 401 Unauthorized
    if (statusCode == HttpStatus.unauthorized && !isAuthEndpoint && !_isRefreshing) {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String? refreshToken = currentUser?.data?.refreshToken;

      if (refreshToken != null && refreshToken.isNotEmpty) {
        _isRefreshing = true;
        try {
          final refreshDio = Dio(BaseOptions(
            baseUrl: EnvironmentService.config.accountBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ));

          final refreshRes = await refreshDio.post(
            URLs.refreshTokenUrl,
            data: {'refreshToken': refreshToken},
          );

          if (refreshRes.statusCode == HttpStatus.ok && refreshRes.data != null) {
            final dynamic raw = refreshRes.data;
            final dynamic payload = raw is Map<String, dynamic> ? (raw['data'] ?? raw['result'] ?? raw) : null;
            final String? newAccess = payload?['accessToken']?.toString();
            final String newRefresh = payload?['refreshToken']?.toString() ?? refreshToken;

            if (newAccess != null && newAccess.isNotEmpty) {
              await GlobalSession.instance.updateTokens(
                newAccessToken: newAccess,
                newRefreshToken: newRefresh,
              );

              _isRefreshing = false;

              // Retry original request with freshly acquired access token
              final retryOptions = err.requestOptions;
              retryOptions.headers[HttpHeaders.authorizationHeader] = 'Bearer $newAccess';

              final retryResponse = await refreshDio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (refreshErr) {
          debugPrint('⚠️ [ErrorInterceptor] Transparent token refresh failed: $refreshErr');
        } finally {
          _isRefreshing = false;
        }
      }
    }

    final bool isDeactivatedError = displayMessage != null &&
        displayMessage.toLowerCase().contains('deactivated');
    final bool isInactiveError = displayMessage != null &&
        (displayMessage.toLowerCase().contains('inactive') ||
            displayMessage.toLowerCase().contains('contact admin'));

    final bool suppressErrorSnack =
        err.requestOptions.extra['suppressErrorSnack'] == true ||
        err.requestOptions.path.toLowerCase().contains('device-token');

    final bool suppressSessionExpired =
        err.requestOptions.extra['suppressSessionExpired'] == true;

    if (!suppressErrorSnack &&
        !suppressSessionExpired &&
        (!isAuthEndpoint || isDeactivatedError || isInactiveError)) {
      String msg = displayMessage ?? '';
      if (isDeactivatedError) {
        msg = 'Your account was deactivated. Contact administrator.';
      } else if (isInactiveError) {
        msg = 'Your account is inactive. Contact admin.';
      }
      ExceptionHandler.processException(
        statusCode: statusCode,
        status: false,
        message: msg,
      );
    }

    return handler.next(err);
  }
}
