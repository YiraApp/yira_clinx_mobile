import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/constants.dart';
import '../expention_handler/exception_handler.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map<String, dynamic>) {
      final bool status = response.data['status'] ?? true;
      if (!status) {
        ExceptionHandler.processException(
          statusCode: HttpStatus.ok,
          message: response.data['message'],
        );
        return handler.reject(DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        ));
      }
      else {
        if (response.data['message'] != null && response.data['message'].isNotEmpty) {
          ExceptionHandler.processException(
            statusCode: HttpStatus.ok,
            message: response.data['message'],
          );
        }
      }

    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    int statusCode = err.response?.statusCode ?? 0;

    if (err.type == DioExceptionType.connectionError) statusCode = socket_exception;
    if (err.type == DioExceptionType.connectionTimeout) statusCode = HttpStatus.gatewayTimeout;

    ExceptionHandler.processException(statusCode: statusCode, message: err.message);
    return handler.next(err);
  }
}