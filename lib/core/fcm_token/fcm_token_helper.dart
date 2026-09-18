import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmTokenHelper {
  static Future<String> getProductionFcmToken() async {
    try {
      if (kIsWeb) return '';
      final messaging = FirebaseMessaging.instance;

      if (Platform.isAndroid) {
        String? androidToken;
        try {
          androidToken = await messaging.getToken();
        } catch (e) {
          debugPrint("FCM getToken on Android retry needed: $e");
          await Future.delayed(const Duration(milliseconds: 600));
          androidToken = await messaging.getToken();
        }
        return androidToken ?? '';
      } else if (Platform.isIOS) {
        // 1. Wait/retry for Apple APNs token (takes 1-3 seconds on iOS devices)
        String? apnsToken;
        for (int i = 0; i < 8; i++) {
          try {
            apnsToken = await messaging.getAPNSToken();
            if (apnsToken != null && apnsToken.isNotEmpty) {
              debugPrint("[FcmTokenHelper] APNS token acquired on attempt ${i + 1}");
              break;
            }
          } catch (e) {
            debugPrint("[FcmTokenHelper] APNS attempt ${i + 1} error: $e");
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // 2. Fetch real FCM registration token
        try {
          final String? token = await messaging.getToken();
          if (token != null && token.isNotEmpty) {
            debugPrint("[FcmTokenHelper] Real FCM token acquired: ${token.substring(0, 25)}...");
            return token;
          }
        } catch (e) {
          debugPrint("[FcmTokenHelper] FCM getToken on iOS error: $e");
        }

        // 3. Fallback for iOS Simulator ONLY
        try {
          final deviceInfo = DeviceInfoPlugin();
          final iosInfo = await deviceInfo.iosInfo;
          if (!iosInfo.isPhysicalDevice) {
            debugPrint("[FcmTokenHelper] Running on iOS Simulator, using simulator identifier");
            return "ios_sim_${iosInfo.identifierForVendor ?? 'device'}";
          }
        } catch (_) {
          return "ios_device_token";
        }
      }
      return '';
    } catch (error) {
      debugPrint("FcmTokenHelper - Graceful token fallback: $error");
      return '';
    }
  }
}
