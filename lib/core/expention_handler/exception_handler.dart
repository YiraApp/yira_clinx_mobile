import 'dart:io';
import 'package:yiraclinics/config/app_route/app_routes.dart';

import '../../di/dependency_injection.dart';
import '../constants/clinx_storage_keys.dart';
import '../constants/constants.dart';
import '../local/shared_preferences.dart';
import '../navigation_services/navigation_services.dart';
import '../utils/utils.dart';

class ExceptionHandler {
  const ExceptionHandler._();

  static bool _isRedirecting = false;

  static void processException({
    required int statusCode,
    String? message,
    bool isShownSnack = true,
    bool status = false
  }) {
    if (statusCode == HttpStatus.unauthorized) {
      // Only redirect to sessionExpired if user is actually logged in
      final bool isLoggedIn = sl.isRegistered<SharedPrefsService>() &&
          (sl<SharedPrefsService>().getValue<bool>(ClinxStorageKeys.isUserLoggedIn) ?? false);
      if (!isLoggedIn) {
        return;
      }

      // Do not redirect if user is already on auth, splash, or sessionExpired screens
      final currentRoute = NavigationService.currentRoute;
      if (currentRoute == AppRoutes.sessionExpired ||
          currentRoute == AppRoutes.signIn ||
          currentRoute == AppRoutes.signup ||
          currentRoute == AppRoutes.initial ||
          currentRoute == AppRoutes.verifyOtp ||
          currentRoute == AppRoutes.forgotPassword) {
        return;
      }

      if (_isRedirecting) return;
      _isRedirecting = true;

      NavigationService.navigateTo(AppRoutes.sessionExpired);

      Future.delayed(const Duration(seconds: 2), () => _isRedirecting = false);
      return;
    }
    if (statusCode == socket_exception || statusCode == no_internet) {
      return;
    }

    if (!isShownSnack) return;

    final String finalMessage = _getErrorMessage(statusCode, message);
    // final bool isError = statusCode != HttpStatus.ok;

    Utils.showSnackBar(message: finalMessage, status: status);
  }

  static String _getErrorMessage(int statusCode, String? customMessage) {
    if (customMessage != null && customMessage.trim().isNotEmpty) {
      return customMessage;
    }

    switch (statusCode) {
      case socket_exception:
        return 'Unable to connect to the server. Please check your network and try again.';

      case no_internet:
        return 'No internet connection. Please verify your Wi-Fi or mobile data.';

      case HttpStatus.internalServerError:
        return 'We are experiencing server difficulties. Please try again later.';

      case HttpStatus.gatewayTimeout:
        return 'The connection has timed out. Please try your request again.';

      case HttpStatus.ok:
        return 'Action could not be completed. Please try again.';

      default:
        return 'An unexpected error occurred ($statusCode).';
    }
  }
}
