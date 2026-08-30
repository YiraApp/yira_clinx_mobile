import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common_size_helpers/common_size_helpers.dart';
import '../common_widgets/common_text.dart';
import '../constants/constants.dart';
import '../global_scaffold_key/global_scaffold_key.dart';

class Utils {
  static void printText(String message, {String tag = 'APP_LOG'}) {
    debugPrint('[$tag] $message');
  }
  static Future<void> launchURL(
      String urlString, {
        void Function(String errorMessage)? onLaunchFailure,
      }) async {
    final String trimmedUrl = urlString.trim();

    if (trimmedUrl.isEmpty) {
      _handleError('URL string is empty', onLaunchFailure);
      return;
    }

    String formattedUrl = trimmedUrl;
    if (!formattedUrl.startsWith("http://") &&
        !formattedUrl.startsWith("https://") &&
        !formattedUrl.contains("://")) {
      formattedUrl = "https://$formattedUrl";
    }

    Uri? parsedUri = Uri.tryParse(formattedUrl);
    if (parsedUri == null || !parsedUri.hasScheme) {
      parsedUri = Uri.tryParse(Uri.encodeFull(formattedUrl));
    }
    if (parsedUri == null) {
      _handleError('Could not parse invalid URL: $formattedUrl', onLaunchFailure);
      return;
    }

    try {
      bool launched = false;
      try {
        launched = await launchUrl(
          parsedUri,
          mode: LaunchMode.inAppBrowserView,
        );
      } catch (e) {
        debugPrint('[Utils.launchURL] inAppBrowserView attempt error: $e');
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            parsedUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('[Utils.launchURL] externalApplication attempt error: $e');
        }
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            parsedUri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          debugPrint('[Utils.launchURL] platformDefault attempt error: $e');
        }
      }

      if (!launched) {
        _handleError('Could not launch URL: $formattedUrl', onLaunchFailure);
      }
    } catch (e, stackTrace) {
      _handleError(
        'Unexpected error launching URL: $e',
        onLaunchFailure,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> launchMeetingURL(
    String urlString, {
    String? displayName,
    void Function(String errorMessage)? onLaunchFailure,
  }) async {
    String url = urlString.trim();
    if (url.isEmpty) {
      _handleError('Meeting link is empty', onLaunchFailure);
      return;
    }

    if (displayName != null && displayName.trim().isNotEmpty) {
      try {
        final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
        final params = Map<String, String>.from(uri.queryParameters);
        final name = displayName.trim();

        if (url.contains('zoom.us') || url.contains('/wc/')) {
          if (!params.containsKey('uname')) params['uname'] = name;
          if (!params.containsKey('dn')) params['dn'] = name;
          url = uri.replace(queryParameters: params).toString();
        } else if (url.contains('meet.jit.si')) {
          if (!url.contains('userInfo.displayName')) {
            url = '$url#userInfo.displayName=${Uri.encodeComponent('"$name"')}';
          }
        }
      } catch (_) {}
    }

    await launchURL(url, onLaunchFailure: onLaunchFailure);
  }

  static void _handleError(
      String message,
      void Function(String)? onFailureCallback, {
        Object? error,
        StackTrace? stackTrace,
      }) {
    log(
      message,
      name: 'UrlLauncherUtils',
      error: error,
      stackTrace: stackTrace,
    );

    if (onFailureCallback != null) {
      onFailureCallback(message);
    }
  }
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent, // Or errorRedColor from your config
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
        ),
      ),
    );
  }
  static Future<File?> compressImage(
    String filePath,
    String fileNamePrefix,
  ) async {
    final file = File(filePath);
    final fileName = '$fileNamePrefix - ${generateUniqueName()}';
    final fileExtension = filePath.split('.').last;
    final newFileName = '$fileName.$fileExtension';

    final directory = await getApplicationDocumentsDirectory();
    final compressedFilePath = '${directory.path}/$newFileName';

    try {
      final compressedImageData = await FlutterImageCompress.compressAndGetFile(
        file.path,
        '${directory.path}/$newFileName',
        keepExif: false,
      );
      String filePath = compressedImageData!.path;
      File files = File(filePath);
      List<int> imageBytes = await files.readAsBytes();
      final compressedFile = File(compressedFilePath);
      await compressedFile.writeAsBytes(imageBytes);

      return compressedFile;
    } on CompressError {
      return null;
    }
  }

  static Future<bool> getCameraPermission(
    BuildContext context,
    Color buttonPrimaryColor,
  ) async {
    var status = await Permission.camera.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      PermissionStatus newStatus = await Permission.camera.request();
      if (newStatus.isGranted || newStatus.isLimited) {
        return true;
      }
      status = newStatus;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        if (Platform.isAndroid) {
          await androidDialogue(
            context,
            'Camera permission needed',
            'To take photos, please grant access to your device\'s camera.',
            buttonPrimaryColor,
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/images/ic_dark.png'
                : 'assets/images/ic_light.png',
            2.0,
          );
        } else {
          await showAlertDialog(
            context,
            'Camera permission needed',
            'To take photos, please grant access to your device\'s camera.',
          );
        }
      }
    }

    return await Permission.camera.isGranted || await Permission.camera.isLimited;
  }

  static Future<bool> getStoragePermission(
    BuildContext context,
    Color buttonPrimaryColor,
  ) async {
    Permission permission = Permission.storage;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt > 32) {
        permission = Permission.photos;
      }
    }

    var status = await permission.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      PermissionStatus newStatus = await permission.request();
      if (newStatus.isGranted || newStatus.isLimited) {
        return true;
      }
      status = newStatus;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        if (Platform.isAndroid) {
          await androidDialogue(
            context,
            'Storage permission needed',
            'To pick files and documents, please grant storage access.',
            buttonPrimaryColor,
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/images/ic_dark.png'
                : 'assets/images/ic_light.png',
            2.0,
          );
        } else {
          await showAlertDialog(
            context,
            'Storage permission needed',
            'To pick files and documents, please grant storage access.',
          );
        }
      }
    }

    return await permission.isGranted;
  }

  static Future<bool> getStoragePermissionIOS(BuildContext context) async {
    var status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      PermissionStatus newStatus = await Permission.photos.request();
      if (newStatus.isGranted || newStatus.isLimited) {
        return true;
      }
      status = newStatus;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await showAlertDialog(
          context,
          'Photo permission needed',
          'To select photos, please grant photo access in settings.',
        );
      }
    }

    return await Permission.photos.isGranted;
  }

  static Future<void> showAlertDialog(context, String title, String reason) =>
      showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => CupertinoTheme(
          data: CupertinoThemeData(brightness: Brightness.light),
          child: CupertinoAlertDialog(
            title: Text(
              title,
              style: TextStyle(
                fontSize: displayWidth(context) * 0.038,
                color: Colors.black,
              ),
            ),
            content: Text(
              reason,
              style: TextStyle(
                fontSize: displayWidth(context) * 0.03,
                color: Colors.black,
              ),
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => openAppSettings(),
                child: const Text('Settings'),
              ),
            ],
          ),
        ),
      );
  static void showSnackBar({
    String? message,
    int duration = 3,
    bool status = true,
  }) {
    final context = Globals.scaffoldMessengerKey.currentContext;
    if (context == null) return;

    final bool isTab = isTablet(context);
    final double iconSize = displayHeight(context) * 0.022;
    final double fontSize = isTab
        ? displayWidth(context) * 0.016
        : displayWidth(context) * 0.03;

    final snackBar = SnackBar(
      backgroundColor: status ? Colors.green.shade700 : Colors.red.shade800,
      duration: Duration(seconds: duration),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
      content: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.info_outline,
            color: Colors.white,
            size: iconSize,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message ?? '',
              softWrap: true,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    Globals.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    Globals.scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  static Future<dynamic> androidDialogue(
    BuildContext context,
    String title,
    String reason,
    Color buttonPrimaryColor,
    String image,
    double padding,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Container(
            height: displayHeight(context) * 0.08,
            width: displayHeight(context) * 0.08,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.transparent : Colors.grey.shade100,
            ),
            child: Center(child: Image.asset(image, fit: BoxFit.contain)),
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          backgroundColor: theme.dialogBackgroundColor,
          title: Column(
            children: [
              CommonText(
                title,
                style: TextStyle(
                  fontSize: displayWidth(context) * 0.038,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          content: CommonText(
            maxLines: null,
            softWrap: true,
            reason,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: displayWidth(context) * 0.034,
              fontWeight: FontWeight.w400,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
          contentPadding: const EdgeInsets.only(left: 10, right: 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CommonText(
                'Later',
                style: TextStyle(
                  fontSize: displayWidth(context) * 0.034,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await openAppSettings();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: CommonText(
                'Go to settings',
                style: TextStyle(
                  fontSize: displayWidth(context) * 0.034,
                  fontWeight: FontWeight.w600,
                  color: buttonPrimaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> getNotificationPermission(
    BuildContext context,
    Color buttonPrimaryColor, [
    Permission permission = Permission.notification,
  ]) async {
    bool isPermissionGranted = false;

    try {
      if (await permission.request().isGranted) {
        isPermissionGranted = true;
        return isPermissionGranted;
      } else if (await permission.request().isPermanentlyDenied) {
        isPermissionGranted = false;
        if (Platform.isAndroid) {
          androidDialogue(
            context,
            'Notification permission needed',
            'To receive notifications, please grant access to notifications.',
            buttonPrimaryColor,
            'assets/images/ic_noti.png',
            10,
          );
        } else {
          showAlertDialog(
            context,
            'Notification permission needed',
            'To receive notifications, please grant access to notifications.',
          );
        }
        return isPermissionGranted;
      } else if (await Permission.notification.request().isDenied) {
        isPermissionGranted = false;
        return isPermissionGranted;
      } else {
        isPermissionGranted = false;
        return isPermissionGranted;
      }
    } catch (e) {
      isPermissionGranted = false;
      return isPermissionGranted;
    }
  }

  static Future<bool> getNotificationPermissionMain([
    Permission permission = Permission.notification,
  ]) async {
    bool isPermissionGranted = false;

    try {
      if (await permission.request().isGranted) {
        isPermissionGranted = true;
        return isPermissionGranted;
      } else if (await permission.request().isPermanentlyDenied) {
        isPermissionGranted = false;

        return isPermissionGranted;
      } else if (await Permission.notification.request().isDenied) {
        isPermissionGranted = false;
        return isPermissionGranted;
      } else {
        isPermissionGranted = false;
        return isPermissionGranted;
      }
    } catch (e) {
      isPermissionGranted = false;
      return isPermissionGranted;
    }
  }

  static String generateUniqueName() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String uniqueName = timestamp.toString();
    return uniqueName;
  }
}
