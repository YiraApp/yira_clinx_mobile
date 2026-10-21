import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How a medicine reminder push is shown on Android.
enum MedicationAlertStyle {
  /// The normal notification in the status bar and notification shade.
  notification,

  /// A floating card shown over whatever app is open (needs the
  /// "Display over other apps" permission), as well as the notification.
  floatingPopup,
}

/// The dose a floating popup is about.
class MedicationPopupData {
  final String reminderId;
  final String medicineName;
  final String dosage;
  final String mealRelation;
  final String time;
  final String date;

  const MedicationPopupData({
    required this.reminderId,
    required this.medicineName,
    this.dosage = '',
    this.mealRelation = '',
    this.time = '',
    this.date = '',
  });

  /// From the data of a MEDICATION_REMINDER push.
  factory MedicationPopupData.fromPush(Map<String, dynamic> data) {
    String text(String key) => (data[key] ?? '').toString().trim();
    return MedicationPopupData(
      reminderId: text('reminderId').isNotEmpty ? text('reminderId') : text('referenceId'),
      medicineName: text('medicineName').isNotEmpty ? text('medicineName') : text('title'),
      dosage: text('dosage') == 'null' ? '' : text('dosage'),
      mealRelation: text('mealRelation') == 'null' ? '' : text('mealRelation'),
      time: text('scheduledTime'),
      date: text('date'),
    );
  }

  factory MedicationPopupData.fromJson(Map<String, dynamic> json) => MedicationPopupData(
        reminderId: (json['reminderId'] ?? '').toString(),
        medicineName: (json['medicineName'] ?? '').toString(),
        dosage: (json['dosage'] ?? '').toString(),
        mealRelation: (json['mealRelation'] ?? '').toString(),
        time: (json['time'] ?? '').toString(),
        date: (json['date'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'reminderId': reminderId,
        'medicineName': medicineName,
        'dosage': dosage,
        'mealRelation': mealRelation,
        'time': time,
        'date': date,
      };
}

/// Optional floating popup for medicine reminders on Android. Reminders are
/// pushed by the server (FCM); when the patient picks the floating popup, the
/// push also opens a card over other apps. iOS always uses normal banners.
class MedicationPopupService {
  MedicationPopupService._();

  /// Read natively by MainApplication.kt as "flutter.med_alert_style_v1".
  static const String styleKey = 'med_alert_style_v1';

  /// The dose the popup shows; written before the popup opens.
  static const String payloadKey = 'med_popup_payload_v1';

  static const String pushType = 'MEDICATION_REMINDER';

  /// Floating popups are an Android-only feature.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static Future<MedicationAlertStyle> getStyle() async {
    if (!isSupported) return MedicationAlertStyle.notification;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getString(styleKey) == MedicationAlertStyle.floatingPopup.name
          ? MedicationAlertStyle.floatingPopup
          : MedicationAlertStyle.notification;
    } catch (_) {
      return MedicationAlertStyle.notification;
    }
  }

  static Future<void> setStyle(MedicationAlertStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(styleKey, style.name);
  }

  static Future<bool> hasOverlayPermission() async {
    if (!isSupported) return false;
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's "Display over other apps" page; true once it is allowed.
  static Future<bool> requestOverlayPermission() async {
    if (!isSupported) return false;
    try {
      return await FlutterOverlayWindow.requestPermission() ?? false;
    } catch (e) {
      debugPrint('[MedicationPopup] Overlay permission request failed: $e');
      return false;
    }
  }

  /// Shows the floating popup for a reminder push when the patient chose it
  /// and the permission is granted. Returns true when a popup was shown.
  /// Safe to call from the background push handler.
  static Future<bool> handlePush(Map<String, dynamic> data) async {
    if (!isSupported) return false;
    if ((data['type'] ?? '').toString() != pushType) return false;
    if (await getStyle() != MedicationAlertStyle.floatingPopup) return false;
    if (!await hasOverlayPermission()) return false;
    final popup = MedicationPopupData.fromPush(data);
    if (popup.medicineName.isEmpty) return false;
    return show(popup);
  }

  static Future<bool> show(MedicationPopupData popup) async {
    if (!isSupported) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(payloadKey, jsonEncode(popup.toJson()));

      // A popup already on screen is replaced by the new dose.
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.shareData(jsonEncode(popup.toJson()));
        return true;
      }

      // Full-screen transparent window; the card sits at the bottom and a tap
      // anywhere else closes it, so the app behind is never stuck covered.
      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        overlayTitle: 'Medicine reminder',
        overlayContent: [popup.medicineName, if (popup.time.isNotEmpty) popup.time].join(' · '),
        enableDrag: false,
      );
      return true;
    } catch (e) {
      debugPrint('[MedicationPopup] Could not show the popup: $e');
      return false;
    }
  }

  /// Shows a sample popup so the patient can see what it looks like.
  static Future<bool> showTest() => show(
        const MedicationPopupData(
          reminderId: '',
          medicineName: 'Sample medicine',
          dosage: '1 tablet',
          mealRelation: 'After Food',
          time: 'Now',
        ),
      );

  static Future<void> close() async {
    if (!isSupported) return;
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
  }
}
