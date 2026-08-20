import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/constants.dart';
import '../expention_handler/exception_handler.dart';

class ErrorInterceptor extends Interceptor {
  final bool showSuccessSnack;

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
      ExceptionHandler.processException(
        status: false,
        statusCode: HttpStatus.ok,
        message: serverMessage,
      );

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
  void onError(DioException err, ErrorInterceptorHandler handler) {
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
    ExceptionHandler.processException(
      statusCode: statusCode,
      status: false,
      message: displayMessage,
    );

    return handler.next(err);
  }
}
