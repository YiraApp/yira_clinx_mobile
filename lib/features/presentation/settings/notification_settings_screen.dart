import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/services/notification_services/notification_services.dart';
import 'package:yiraclinics/features/presentation/settings/setting_bloc/setting_bloc.dart';

import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/constants/constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  AuthorizationStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (mounted) {
        setState(() {
          _permissionStatus = settings.authorizationStatus;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final bool isPermissionDenied =
        _permissionStatus == AuthorizationStatus.denied;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(
        titleText: "Notification Preferences",
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.status == SettingsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? "An error occurred"),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenHorizontalSpacePadding,
              vertical: screenTopPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning if iOS Notification Permission is blocked
                if (isPermissionDenied)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Notifications Disabled in iOS",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                "Allow notifications in iOS Settings to receive push alerts.",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: openAppSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Enable",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Notification Channels
                _buildCardGroup(
                  isTab: isTab,
                  context,
                  theme: theme,
                  title: "Notification Channels",
                  children: [
                    _NotificationTile(
                      isTab: isTab,
                      title: "Push Notifications",
                      subtitle: "Receive live clinical alerts on this device",
                      value: state.pushEnabled,
                      onChanged: (val) => context
                          .read<SettingsBloc>()
                          .add(NotificationToggleChanged('push', val)),
                    ),
                    _NotificationTile(
                      isTab: isTab,
                      title: "Email Notifications",
                      subtitle: "Receive updates via email",
                      value: state.emailEnabled,
                      onChanged: (val) => context
                          .read<SettingsBloc>()
                          .add(NotificationToggleChanged('email', val)),
                    ),
                    _NotificationTile(
                      isTab: isTab,
                      title: "SMS Notifications",
                      subtitle: "Receive updates via SMS",
                      value: state.smsEnabled,
                      onChanged: (val) => context
                          .read<SettingsBloc>()
                          .add(NotificationToggleChanged('sms', val)),
                    ),
                  ],
                ),
                const SizedBox(height: fieldSpace),

                // 2. Notification Types
                _buildCardGroup(
                  isTab: isTab,
                  context,
                  theme: theme,
                  title: "Notification Types",
                  children: [
                    _NotificationTile(
                      isTab: isTab,
                      title: "Appointment Reminders (10 Mins)",
                      subtitle: "Get reminded 10 minutes before upcoming consultations",
                      value: state.appointmentReminders,
                      onChanged: (val) => context
                          .read<SettingsBloc>()
                          .add(NotificationToggleChanged('appointment', val)),
                    ),
                    _NotificationTile(
                      isTab: isTab,
                      title: "Medical Records & Documents",
                      subtitle: "Alerts when doctor adds records, vitals, or clinical notes",
                      value: state.labResultsNotif,
                      onChanged: (val) => context
                          .read<SettingsBloc>()
                          .add(NotificationToggleChanged('lab', val)),
                    ),
                    _NotificationTile(
                      isTab: isTab,
                      title: "Prescription Refills & Issues",
                      subtitle: "Notified when doctor prescribes or updates medication",
                      value: state.prescriptionReminders,
                      onChanged: (val) => context
                          .read<SettingsBloc>()
                          .add(NotificationToggleChanged('user_prescription', val)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardGroup(
    BuildContext context, {
    required ThemeData theme,
    required String title,
    required List<Widget> children,
    required bool isTab,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            title,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab
                  ? displayWidth(context) * 0.022
                  : displayWidth(context) * 0.036,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isTab;

  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab
                        ? displayWidth(context) * 0.02
                        : displayWidth(context) * 0.038,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                CommonText(
                  subtitle,
                  maxLines: null,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab
                        ? displayWidth(context) * 0.018
                        : displayWidth(context) * 0.029,
                    color: theme.textTheme.labelSmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: theme.primaryColor,
              activeTrackColor: theme.primaryColor.withOpacity(0.5),
              inactiveTrackColor: theme.brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.grey.shade200,
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Icon(Icons.check, color: Colors.white);
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}