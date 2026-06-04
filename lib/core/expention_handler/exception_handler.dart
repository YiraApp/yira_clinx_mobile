import 'dart:io';

import '../constants/constants.dart';
import '../utils/utils.dart';

class ExceptionHandler {
  static void processException({
    required int statusCode,
    String? message,
    bool isShownSnack = true,
  }) {
    if (!isShownSnack) return;

    String finalMessage = '';

    switch (statusCode) {
      case socket_exception: // 001
        finalMessage = 'Getting exception, please verify the issue';
        break;
      case no_internet:
        finalMessage = 'No internet connection. Please check your network.';
        break;
      case HttpStatus.unauthorized: // 401
        finalMessage = 'Session expired. Please login again.';
        break;
      case HttpStatus.internalServerError: // 500
        finalMessage = 'Server error. Please try again later.';
        break;
      case HttpStatus.gatewayTimeout: // 504
        finalMessage = 'Server is taking too long to respond.';
        break;
      case HttpStatus.ok: // 200 (For status: false cases)
        finalMessage = message ?? 'Authentication failed.';
        break;
      default:
        finalMessage = message?.isNotEmpty == true ? message! : 'Something went wrong ($statusCode)';
    }

    Utils.showSnackBar(message: finalMessage, status: statusCode == HttpStatus.ok);
  }
}