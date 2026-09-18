import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/fcm_token/fcm_token_helper.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/notification_services/notification_badge_service.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/use_cases/update_fcm_token_use_case.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("[NotificationService] Background message received: ${message.messageId}");
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

  bool _isInitialized = false;

  Future<void> initializeNotificationPipeline(
    BuildContext context,
    Function(String) onPayloadReceived,
  ) async {
    if (_isInitialized) return;
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

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_highImportanceChannel);

      _listenToActiveStateNotifications();
      _listenToBackgroundInteractions(onPayloadReceived);
      _checkSuspendedOrTerminatedStateBoot(onPayloadReceived);
      _listenToTokenRefresh();

      _isInitialized = true;

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

      // On Android 13+ (API 33+), also request runtime notification permission explicitly
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint("requestNotificationPermissions error: $e");
      return false;
    }
  }

  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$fileName';
      final File file = File(filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      await file.writeAsBytes(response.data);
      debugPrint("[NotificationService] Notification image downloaded to: $filePath");
      return filePath;
    } catch (e) {
      debugPrint("[NotificationService] Error downloading notification image: $e");
      return null;
    }
  }

  void _listenToActiveStateNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("[NotificationService] Foreground notification received: ${message.data}");
      NotificationBadgeService.instance.increment();
      final RemoteNotification? notification = message.notification;
      final String title = notification?.title ?? message.data['title'] ?? projectTitle;
      final String body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

      final String? imageUrl = notification?.android?.imageUrl ??
          notification?.apple?.imageUrl ??
          message.data['imageUrl'] ??
          message.data['image'];

      if (title.isNotEmpty || body.isNotEmpty) {
        final int notificationId = (message.messageId != null
            ? message.messageId.hashCode
            : DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF;

        String? localImagePath;
        if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith("http")) {
          final String extension = imageUrl.split('?').first.split('.').last;
          final String safeExt = (extension.length <= 4 && extension.isNotEmpty) ? extension : 'jpg';
          localImagePath = await _downloadAndSaveFile(imageUrl, 'notif_$notificationId.$safeExt');
        }

        BigPictureStyleInformation? bigPictureStyleInformation;
        if (localImagePath != null && Platform.isAndroid) {
          bigPictureStyleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(localImagePath),
            largeIcon: FilePathAndroidBitmap(localImagePath),
            contentTitle: title,
            summaryText: body,
            htmlFormatContentTitle: true,
            htmlFormatSummaryText: true,
            hideExpandedLargeIcon: false,
          );
        }

        List<DarwinNotificationAttachment>? iosAttachments;
        if (localImagePath != null && Platform.isIOS) {
          iosAttachments = [DarwinNotificationAttachment(localImagePath)];
        }

        await _localNotifications.show(
          id: notificationId,
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
              styleInformation: bigPictureStyleInformation,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              attachments: iosAttachments,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  /// Manually triggers an immediate local notification (e.g. for instant booking confirmation)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final int notificationId = (DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF;
      await _localNotifications.show(
        id: notificationId,
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
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint("[NotificationService] showNotification error: $e");
    }
  }

  void _listenToBackgroundInteractions(Function(String) onPayloadReceived) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("[NotificationService] Notification opened from background: ${message.data}");
      if (message.data.isNotEmpty) {
        onPayloadReceived(jsonEncode(message.data));
      }
    });
  }

  void _checkSuspendedOrTerminatedStateBoot(Function(String) onPayloadReceived) async {
    try {
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        debugPrint("[NotificationService] App launched from terminated push: ${initialMessage.data}");
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
      debugPrint("[NotificationService] FCM token refreshed: $newToken");
      _sendTokenToBackend(newToken);
    });
  }

  /// Explicitly sync current FCM token with backend
  Future<void> syncFcmTokenWithBackend() async {
    try {
      final String token = await FcmTokenHelper.getProductionFcmToken();
      debugPrint("\n========================================================");
      debugPrint("🔥 [FCM] YOUR DEVICE TOKEN: $token");
      debugPrint("========================================================\n");
      if (token.isNotEmpty && token != 'no_token_available') {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint("syncFcmTokenWithBackend error: $e");
    }
  }

  /// Triggers a test local notification popup (heads-up banner with sound) after a brief delay
  Future<void> sendTestNotification({int delaySeconds = 3}) async {
    Future.delayed(Duration(seconds: delaySeconds), () {
      showNotification(
        title: "Test Alert • Dr. Appointment",
        body: "Dr. Rajesh Sharma confirmed your appointment for 04:30 PM today!",
        payload: jsonEncode({
          "type": "APPOINTMENT_BOOKED",
          "route": "/patientDashboard",
        }),
      );
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      if (currentUser == null || (currentUser.data?.id ?? '').isEmpty) {
        debugPrint("[NotificationService] Skipping token sync: user not logged in yet");
        return;
      }

      if (sl.isRegistered<UpdateFcmTokenUseCase>()) {
        await sl<UpdateFcmTokenUseCase>().call(token);
        debugPrint("[NotificationService] FCM token registered with backend successfully for user ${currentUser.data?.id}");
      }
    } catch (e) {
      debugPrint("[NotificationService] Error sending FCM token to backend: $e");
    }
  }

  Future<void> registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}