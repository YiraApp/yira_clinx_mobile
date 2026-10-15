import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/constants/clinx_storage_keys.dart';
import 'package:yiraclinics/core/fcm_token/fcm_token_helper.dart';
import 'package:yiraclinics/core/global_session/global_menu_session.dart';
import 'package:yiraclinics/core/local/flutter_secure_storage.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/local/shared_preferences.dart';
import 'package:yiraclinics/core/navigation_services/navigation_services.dart';
import 'package:yiraclinics/core/services/favorite_patients_service.dart';
import 'package:yiraclinics/core/services/notification_services/notification_services.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

class AuthLogoutService {
  static bool _isLoggingOut = false;

  /// Performs an end-to-end atomic logout:
  /// 1. Tells backend to deactivate FCM token and revoke session.
  /// 2. Deletes local Firebase messaging token to prevent further push delivery.
  /// 3. Cancels all notifications on device and resets badge.
  /// 4. Wipes in-memory session (GlobalSession, GlobalMenuSession, FavoritePatientsService).
  /// 5. Wipes secure storage and shared preferences.
  /// 6. Redirects cleanly to AppRoutes.signIn.
  static Future<void> performLogout({BuildContext? context}) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String? refreshToken = currentUser?.data?.refreshToken;
      final String? accessToken = currentUser?.data?.accessToken;
      final String? userId = currentUser?.data?.id;

      // 1. Retrieve current FCM token and device ID for targeted server deactivation
      String currentFcmToken = '';
      try {
        currentFcmToken = await FcmTokenHelper.getProductionFcmToken();
      } catch (_) {}

      final platFormData = GlobalSession.instance.platformNotifier.value;
      String deviceId = platFormData?.deviceId ?? '';
      if (deviceId.isEmpty || deviceId == 'unknown_id') {
        deviceId = (userId != null && userId.isNotEmpty) ? 'dev_$userId' : '';
      }

      // 2. Notify backend to revoke session and deactivate push tokens on this device
      try {
        final requestHeaders = <String, dynamic>{
          HttpHeaders.contentTypeHeader: 'application/json',
        };
        if (accessToken != null && accessToken.isNotEmpty) {
          requestHeaders[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
        }
        if (userId != null && userId.isNotEmpty) {
          requestHeaders['x-user-id'] = userId;
        }
        if (deviceId.isNotEmpty) {
          requestHeaders['x-device-id'] = deviceId;
        }

        await sl<ApiClient>().account(showSuccessSnack: false).post(
          URLs.logoutUrl,
          data: {
            'userId': userId ?? '',
            'refreshToken': refreshToken ?? '',
            'fcmToken': currentFcmToken,
            'deviceId': deviceId,
            'one': true,
          },
          options: Options(
            extra: {
              'showSuccessSnack': false,
              'suppressErrorSnack': true,
              'suppressSessionExpired': true,
            },
            headers: requestHeaders,
          ),
        );
        debugPrint("[AuthLogoutService] Backend logout successful: device and tokens deactivated.");
      } catch (backendError) {
        debugPrint("[AuthLogoutService] Backend logout notification skipped/failed: $backendError");
      }

      // 3. Delete FCM token on Firebase so this device stops receiving any push notifications
      try {
        await FirebaseMessaging.instance.deleteToken();
        debugPrint("[AuthLogoutService] Local Firebase messaging token deleted successfully.");
      } catch (fcmError) {
        debugPrint("[AuthLogoutService] Firebase deleteToken error: $fcmError");
      }

      // 4. Cancel all active local notifications on device and clear badge
      try {
        await NotificationService.instance.cancelAllNotifications();
      } catch (_) {}

      // 5. Clear in-memory session states
      await GlobalSession.instance.clear();
      GlobalMenuSession.instance.clear();
      FavoritePatientsService().favoriteIdsNotifier.value = {};

      // 6. Clear local storage
      try {
        await sl<SecureStorageService>().clearAllSecureData();
        await sl<SharedPrefsService>().clearAll();
      } catch (_) {}

      // 7. Explicitly flag user as logged out
      try {
        await sl<SharedPrefsService>().setValue<bool>(ClinxStorageKeys.isUserLoggedIn, false);
      } catch (_) {}

      // 8. Safely redirect to sign in
      if (context != null && context.mounted) {
        _navigateToSignIn(context);
      } else {
        _navigateToSignIn(null);
      }
    } catch (e) {
      debugPrint("[AuthLogoutService] Exception during logout sequence: $e");
      await GlobalSession.instance.clear();
      try {
        await sl<SecureStorageService>().clearAllSecureData();
        await sl<SharedPrefsService>().clearAll();
        await sl<SharedPrefsService>().setValue<bool>(ClinxStorageKeys.isUserLoggedIn, false);
      } catch (_) {}
      if (context != null && context.mounted) {
        _navigateToSignIn(context);
      } else {
        _navigateToSignIn(null);
      }
    } finally {
      _isLoggingOut = false;
    }
  }

  static void _navigateToSignIn(BuildContext? context) {
    if (context != null && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.signIn,
        (route) => false,
      );
    } else {
      NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.signIn,
        (route) => false,
      );
    }
  }
}
