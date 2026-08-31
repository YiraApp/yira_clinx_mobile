
import 'package:flutter/material.dart';

import '../services/notification_services/notification_services.dart';
import '../services/permission_helper.dart';

class NotificationListenerWrapper extends StatefulWidget {
  final Widget child;
  final Function(String) onNotificationPayload;

  const NotificationListenerWrapper({
    super.key,
    required this.child,
    required this.onNotificationPayload
  });

  @override
  State<NotificationListenerWrapper> createState() => _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState extends State<NotificationListenerWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.initializeNotificationPipeline(
          context,
          widget.onNotificationPayload
      );
      await PermissionHelper.requestAppLaunchPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}