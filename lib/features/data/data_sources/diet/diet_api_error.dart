import 'dart:io';

import 'package:dio/dio.dart';

/// Request extras for diet calls that show their own error message, so the
/// global interceptor does not also show a generic one.
const Map<String, dynamic> dietQuietErrors = {'suppressErrorSnack': true};

/// The message the diet API sent back (it uses `error`, sometimes `message`),
/// or [fallback] when there is none, such as for a dropped connection.
String dietApiErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = (data['error'] ?? data['message'])?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'No connection. Check your internet and try again.';
      default:
        if (error.error is SocketException) return "Can't reach the server. Check your connection and try again.";
        break;
    }
  }
  return fallback;
}
