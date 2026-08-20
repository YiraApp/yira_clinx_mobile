import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmTokenHelper {
  static Future<String> getProductionFcmToken() async {
    try {
      if (kIsWeb) return '';
      final messaging = FirebaseMessaging.instance;
      if (Platform.isAndroid) {
        final String? androidToken = await messaging.getToken();
        return androidToken ?? '';
      } else if (Platform.isIOS) {
        String? apnsToken;
        int retryCount = 0;
        while (retryCount < 4) {
          try {
            apnsToken = await messaging.getAPNSToken();
            if (apnsToken != null) break;
          } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 400));
          retryCount++;
        }
        if (apnsToken != null) {
          try {
            final String? iosToken = await messaging.getToken();
            return iosToken ?? '';
          } catch (_) {
            return '';
          }
        }
        return '';
      }
      return '';
    } catch (error) {
      debugPrint("FcmTokenHelper - Graceful token fallback: $error");
      return '';
    }
  }
}
