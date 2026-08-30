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
        try {
          await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (_) {}

        try {
          final apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null) {
            final String? token = await messaging.getToken();
            if (token != null && token.isNotEmpty) {
              return token;
            }
          } else {
            debugPrint("APNS token not available on this iOS device/simulator yet, using local identifier fallback.");
          }
        } catch (e) {
          debugPrint("FCM getToken on iOS: $e");
        }

        // Fallback for iOS Simulator / local testing
        try {
          final deviceInfo = DeviceInfoPlugin();
          final iosInfo = await deviceInfo.iosInfo;
          return "ios_sim_${iosInfo.identifierForVendor ?? 'device'}";
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
