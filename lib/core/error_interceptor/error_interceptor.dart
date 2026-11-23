import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/base_api_configuration.dart';
import '../constants/constants.dart';
import '../expention_handler/exception_handler.dart';
import '../local/global_session.dart';
import '../urls/urls.dart';
import 'token_refresh_gate.dart';

class ErrorInterceptor extends Interceptor {
  final bool showSuccessSnack;

  /// Shared by every API client, so calls refused together renew the token once.
  static final TokenRefreshGate _refreshGate = TokenRefreshGate();
  static const _retriedKey = 'retriedAfterTokenRefresh';

  /// The client that renews the token and retries a refused call (replaced in tests).
  @visibleForTesting
  static Dio Function() refreshClient = () => Dio(BaseOptions(
        baseUrl: EnvironmentService.config.accountBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

  ErrorInterceptor({this.showSuccessSnack = true});

  /// Renews the session tokens with the refresh token; the new access token, or null.
  static Future<String?> _renewTokens() async {
    final String? refreshToken = GlobalSession.instance.userNotifier.value?.data?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final refreshRes = await refreshClient().post(
        URLs.refreshTokenUrl,
        data: {'refreshToken': refreshToken},
      );
      if (refreshRes.statusCode != HttpStatus.ok || refreshRes.data == null) return null;
      final dynamic raw = refreshRes.data;
      final dynamic payload = raw is Map<String, dynamic> ? (raw['data'] ?? raw['result'] ?? raw) : null;
      final String? newAccess = payload?['accessToken']?.toString();
      if (newAccess == null || newAccess.isEmpty) return null;
      await GlobalSession.instance.updateTokens(
        newAccessToken: newAccess,
        newRefreshToken: payload?['refreshToken']?.toString() ?? refreshToken,
      );
      return newAccess;
    } catch (refreshErr) {
      debugPrint('⚠️ [ErrorInterceptor] Transparent token refresh failed: $refreshErr');
      return null;
    }
  }

  static String? _bearer(dynamic header) {
    final value = header?.toString().trim() ?? '';
    return value.toLowerCase().startsWith('bearer ') ? value.substring(7).trim() : (value.isEmpty ? null : value);
  }
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return handler.next(response);
    }
    // Only a true/false `status` is a success flag; some APIs send a text
    // status (e.g. "active"), which must not be read as a failure or crash.
    final dynamic rawStatus = data['status'];
    final bool isSuccess = rawStatus is bool ? rawStatus : true;
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

    final bool isTimeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;

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
      displayMessage = responseData['message']?.toString() ??
          responseData['error']?.toString();
    }

    // Do NOT leak raw Dio debug messages (e.g. "The request connection took longer than 0:00:30.000000...")
    // into displayMessage. Only use clean user-friendly fallback if no server message is provided.
    if (displayMessage == null && isTimeout) {
      displayMessage = 'The connection timed out. Please check your network and try again.';
    }

    final String path = err.requestOptions.path.toLowerCase();
    final String method = err.requestOptions.method.toUpperCase();
    final bool isReadOnly = method == 'GET';

    final bool isAuthEndpoint = path.contains('login') ||
        path.contains('register') ||
        path.contains('signup') ||
        path.contains('sendotp') ||
        path.contains('verify') ||
        path.contains('forgot') ||
        path.contains('reset') ||
        path.contains('refresh');

    final bool isBackgroundPath = path.contains('device-token') ||
        path.contains('notification') ||
        path.contains('fitness') ||
        path.contains('sidebar') ||
        path.contains('app-version') ||
        path.contains('status') ||
        path.contains('check');

    // Attempt transparent token refresh on 401 Unauthorized. Calls refused at the same time wait
    // for one renewal, then each is retried once with the new token; only a call that is still
    // refused (or a failed renewal) goes on to Session Expired.
    if (statusCode == HttpStatus.unauthorized && !isAuthEndpoint && err.requestOptions.extra[_retriedKey] != true) {
      final String? newAccess = await _refreshGate.freshToken(
        sentToken: _bearer(err.requestOptions.headers[HttpHeaders.authorizationHeader]),
        currentToken: GlobalSession.instance.userNotifier.value?.data?.accessToken,
        renew: _renewTokens,
      );
      if (newAccess != null && newAccess.isNotEmpty) {
        final retryOptions = err.requestOptions;
        retryOptions.headers[HttpHeaders.authorizationHeader] = 'Bearer $newAccess';
        retryOptions.extra[_retriedKey] = true;
        try {
          final retryResponse = await refreshClient().fetch(retryOptions);
          return handler.resolve(retryResponse);
        } on DioException catch (retryErr) {
          // Handled like any other failure, without renewing again.
          onError(retryErr, handler);
          return;
        }
      }
    }

    final bool isDeactivatedError = displayMessage != null &&
        displayMessage.toLowerCase().contains('deactivated');
    final bool isInactiveError = displayMessage != null &&
        (displayMessage.toLowerCase().contains('inactive') ||
            displayMessage.toLowerCase().contains('contact admin'));

    // Suppress error snackbars for:
    // 1. Explicitly suppressed calls (extra['suppressErrorSnack'] == true)
    // 2. Background polling / sync services (device-token, notifications, fitness, etc.)
    // 3. Read-only (GET) requests that timed out or encountered network socket errors (repositories have cache fallbacks)
    final bool suppressErrorSnack =
        err.requestOptions.extra['suppressErrorSnack'] == true ||
        isBackgroundPath ||
        (isReadOnly && (isTimeout || statusCode == socket_exception));

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
