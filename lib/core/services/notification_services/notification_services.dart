import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class IsolateInitConfig {
  final RootIsolateToken token;
  final SendPort port;
  IsolateInitConfig({required this.token, required this.port});
}

void productionFirebaseInitializer(IsolateInitConfig config) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(config.token);
  try {
    await Firebase.initializeApp();
    config.port.send(true);
  } catch (e) {
    config.port.send(false);
  }
}

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _highImportanceChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel delivers high importance pushes directly to viewports.',
    importance: Importance.max,
    playSound: true,
  );

  /// Initializes listening capabilities, native streams, and local channels
  /// WITHOUT prompting the user for permission on startup.
  Future<void> initializeNotificationPipeline(
      BuildContext context,
      Function(String) onPayloadReceived,
      ) async {
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
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
  }

  Future<bool> requestNotificationPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  void _listenToActiveStateNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _highImportanceChannel.id,
              _highImportanceChannel.name,
              channelDescription: _highImportanceChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android.smallIcon,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  void _listenToBackgroundInteractions(Function(String) onPayloadReceived) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onPayloadReceived(jsonEncode(message.data));
    });
  }

  void _checkSuspendedOrTerminatedStateBoot(Function(String) onPayloadReceived) async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        onPayloadReceived(jsonEncode(initialMessage.data));
      });
    }
  }

  Future<void> registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}