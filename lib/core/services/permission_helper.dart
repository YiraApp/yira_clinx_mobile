import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import 'package:yiraclinics/core/services/notification_services/notification_services.dart';

class PermissionHelper {
  PermissionHelper._();

  static bool _hasRequestedInitial = false;

  /// Requests Notification permission once at app startup.
  /// All other permissions (Camera, Photos/Storage) are collected on-demand when needed.
  static Future<void> requestAppLaunchPermissions() async {
    if (_hasRequestedInitial || kIsWeb) return;
    _hasRequestedInitial = true;

    try {
      debugPrint('[PermissionHelper] Requesting app launch notification permission...');

      // Only Notification Permission at app launch
      await NotificationService.instance.requestNotificationPermissions();

      debugPrint('[PermissionHelper] App launch notification permission completed.');
    } catch (e) {
      debugPrint('[PermissionHelper] requestAppLaunchPermissions error: $e');
    }
  }

  /// Verifies Photos/Media permission on-demand with fallback to Settings dialog
  static Future<bool> ensurePhotosPermission(BuildContext context) async {
    if (kIsWeb) return true;

    Permission permission = Permission.photos;
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 33) {
          permission = Permission.storage;
        }
      } catch (_) {
        permission = Permission.storage;
      }
    }

    var status = await permission.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
    }

    if (status.isPermanentlyDenied || status.isRestricted || status.isDenied) {
      if (context.mounted) {
        await _showPermissionSettingsDialog(
          context: context,
          title: 'Photo Library Access Needed',
          message:
              'To select and upload medical records and photos, please enable Photo Library access in your device settings.',
        );
      }
    }

    return await permission.isGranted || await permission.isLimited;
  }

  /// Verifies Document/Storage permission on-demand before file picking with fallback to Settings dialog
  static Future<bool> ensureDocumentPermission(BuildContext context) async {
    if (kIsWeb) return true;

    Permission permission = Permission.photos;
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 33) {
          permission = Permission.storage;
        }
      } catch (_) {
        permission = Permission.storage;
      }
    }

    var status = await permission.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
    }

    if (status.isPermanentlyDenied || status.isRestricted || status.isDenied) {
      if (context.mounted) {
        await _showPermissionSettingsDialog(
          context: context,
          title: 'Storage & Document Access Needed',
          message:
              'To select and upload medical records, reports, and documents, please enable storage access in your device settings.',
        );
      }
    }

    return await permission.isGranted || await permission.isLimited;
  }

  /// Verifies Camera permission on-demand with fallback to Settings dialog
  static Future<bool> ensureCameraPermission(BuildContext context) async {
    if (kIsWeb) return true;

    var status = await Permission.camera.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
    }

    if (status.isPermanentlyDenied || status.isRestricted || status.isDenied) {
      if (context.mounted) {
        await _showPermissionSettingsDialog(
          context: context,
          title: 'Camera Access Needed',
          message:
              'To take photos and scan medical documents, please enable Camera access in your device settings.',
        );
      }
    }

    return await Permission.camera.isGranted || await Permission.camera.isLimited;
  }

  /// Shows platform-adapted settings dialog
  static Future<void> _showPermissionSettingsDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AppDialog(
        title: title,
        message: message,
        tone: AppDialogTone.warning,
        icon: Icons.lock_outline_rounded,
        primaryLabel: 'Open Settings',
        onPrimary: () async {
          Navigator.of(dialogContext).pop();
          await openAppSettings();
        },
        secondaryLabel: 'Cancel',
        onSecondary: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}
