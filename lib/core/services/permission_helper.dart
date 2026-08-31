import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/notification_services/notification_services.dart';

class PermissionHelper {
  PermissionHelper._();

  static bool _hasRequestedInitial = false;

  /// Requests Notifications, Photos/Media, and Camera permissions once at app startup
  static Future<void> requestAppLaunchPermissions() async {
    if (_hasRequestedInitial || kIsWeb) return;
    _hasRequestedInitial = true;

    try {
      debugPrint('[PermissionHelper] Starting app launch permissions sequence...');

      // 1. Notification Permission
      await NotificationService.instance.requestNotificationPermissions();
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Photos / Storage Permission
      if (Platform.isIOS) {
        final photosStatus = await Permission.photos.request();
        debugPrint('[PermissionHelper] iOS Photos permission status: $photosStatus');
        await Future.delayed(const Duration(milliseconds: 400));
        final cameraStatus = await Permission.camera.request();
        debugPrint('[PermissionHelper] iOS Camera permission status: $cameraStatus');
      } else if (Platform.isAndroid) {
        try {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            final photosStatus = await Permission.photos.request();
            debugPrint('[PermissionHelper] Android 13+ Photos status: $photosStatus');
          } else {
            final storageStatus = await Permission.storage.request();
            debugPrint('[PermissionHelper] Android Storage status: $storageStatus');
          }
        } catch (e) {
          final storageStatus = await Permission.storage.request();
          debugPrint('[PermissionHelper] Android Storage fallback status: $storageStatus');
        }

        await Future.delayed(const Duration(milliseconds: 400));
        final cameraStatus = await Permission.camera.request();
        debugPrint('[PermissionHelper] Android Camera status: $cameraStatus');
      }
      debugPrint('[PermissionHelper] App launch permissions sequence completed.');
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
    if (Platform.isIOS) {
      await showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => CupertinoAlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(message),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        ),
      );
    } else {
      final theme = Theme.of(context);
      final isDarkMode = theme.brightness == Brightness.dark;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
            title: CommonText(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleMedium?.color,
                fontFamily: appPoppinFont,
              ),
            ),
            content: CommonText(
              message,
              maxLines: null,
              softWrap: true,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                fontFamily: appPoppinFont,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: CommonText(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontFamily: appPoppinFont,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await openAppSettings();
                },
                child: const CommonText(
                  'Open Settings',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: appPoppinFont,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}
