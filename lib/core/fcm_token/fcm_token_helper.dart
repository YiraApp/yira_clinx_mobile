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
        int retryCount = 0;
        while (retryCount < 6) {
          final apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null) break;

          await Future.delayed(const Duration(milliseconds: 500));
          retryCount++;
        }
        final String? iosToken = await messaging.getToken();
        return iosToken ?? '';
      }
      return '';
    } catch (error, stackTrace) {
      debugPrint(
        "FcmTokenHelper Error - Falling back gracefully: $error\n$stackTrace",
      );
      return '';
    }
  }
}
