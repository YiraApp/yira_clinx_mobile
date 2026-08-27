import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yiraclinics/core/fcm_token/fcm_token_helper.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/use_cases/update_fcm_token_use_case.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _highImportanceChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel delivers high importance clinical pushes and alerts directly to viewports.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initializeNotificationPipeline(
    BuildContext context,
    Function(String) onPayloadReceived,
  ) async {
    try {
      await requestNotificationPermissions();

      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) onPayloadReceived(response.payload!);
        },
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_highImportanceChannel);

      _listenToActiveStateNotifications();
      _listenToBackgroundInteractions(onPayloadReceived);
      _checkSuspendedOrTerminatedStateBoot(onPayloadReceived);
      _listenToTokenRefresh();

      // Initial token sync
      syncFcmTokenWithBackend();
    } catch (e) {
      debugPrint("NotificationService initialization error: $e");
    }
  }

  Future<bool> requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint("requestNotificationPermissions error: $e");
      return false;
    }
  }

  void _listenToActiveStateNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final RemoteNotification? notification = message.notification;
      final String title = notification?.title ?? message.data['title'] ?? 'Yira Clinx';
      final String body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

      if (title.isNotEmpty || body.isNotEmpty) {
        _localNotifications.show(
          id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _highImportanceChannel.id,
              _highImportanceChannel.name,
              channelDescription: _highImportanceChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              presentBanner: true,
              presentList: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  void _listenToBackgroundInteractions(Function(String) onPayloadReceived) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        onPayloadReceived(jsonEncode(message.data));
      }
    });
  }

  void _checkSuspendedOrTerminatedStateBoot(Function(String) onPayloadReceived) async {
    try {
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          onPayloadReceived(jsonEncode(initialMessage.data));
        });
      }
    } catch (e) {
      debugPrint("checkSuspendedOrTerminatedStateBoot error: $e");
    }
  }

  void _listenToTokenRefresh() {
    _fcm.onTokenRefresh.listen((String newToken) {
      debugPrint("FCM token refreshed: $newToken");
      _sendTokenToBackend(newToken);
    });
  }

  /// Fetch the current FCM registration token
  Future<String> getFcmToken() async {
    return await FcmTokenHelper.getProductionFcmToken();
  }

  /// Triggers a test push notification locally to verify UI banner, sound, and navigation
  Future<void> sendTestLocalNotification({
    String title = "🩺 Yira Clinx: Test Appointment Alert",
    String body = "Rahul Verma booked an appointment for Today at 10:30 AM (Live Video)",
    Map<String, dynamic>? customData,
  }) async {
    final Map<String, dynamic> data = customData ?? {
      'type': 'APPOINTMENT_BOOKED',
      'title': title,
      'body': body,
      'appointmentId': '1001',
      'route': '/doctorDashboard',
    };

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _highImportanceChannel.id,
          _highImportanceChannel.name,
          channelDescription: _highImportanceChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  /// Schedules a 10-minute pre-appointment reminder notification
  Future<void> scheduleAppointment10MinReminder({
    required int appointmentId,
    required String title,
    required String body,
    required DateTime appointmentDateTime,
    Map<String, dynamic>? customData,
  }) async {
    final reminderTime = appointmentDateTime.subtract(const Duration(minutes: 10));
    final now = DateTime.now();

    // If the reminder time is in the past, skip
    if (reminderTime.isBefore(now)) return;

    final Duration delay = reminderTime.difference(now);

    Future.delayed(delay, () async {
      await _localNotifications.show(
        id: appointmentId.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _highImportanceChannel.id,
            _highImportanceChannel.name,
            channelDescription: _highImportanceChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
        ),
        payload: jsonEncode(customData ?? {
          'type': 'APPOINTMENT_REMINDER_10MIN',
          'appointmentId': appointmentId.toString(),
          'title': title,
          'body': body,
        }),
      );
    });
  }

  /// Explicitly sync current FCM token with backend
  Future<void> syncFcmTokenWithBackend() async {
    try {
      final String token = await FcmTokenHelper.getProductionFcmToken();
      debugPrint("FCM Registration Token: $token");
      if (token.isNotEmpty && token != 'no_token_available') {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint("syncFcmTokenWithBackend error: $e");
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      if (sl.isRegistered<UpdateFcmTokenUseCase>()) {
        await sl<UpdateFcmTokenUseCase>().call(token);
        debugPrint("FCM token registered with backend successfully: $token");
      }
    } catch (e) {
      debugPrint("Error sending FCM token to backend: $e");
    }
  }

  Future<void> registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}