import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/services/notification_services/notification_services.dart';
import 'package:yiraclinics/features/presentation/settings/setting_bloc/setting_bloc.dart';

import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/constants/constants.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(
        titleText: "Notification Preferences",
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.status == SettingsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? "An error occurred")),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: screenHorizontalSpacePadding,
                vertical: screenTopPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardGroup(
                  isTab: isTab,
                  context,
                  theme: theme,
                  title: "Test System Notifications",
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Tap below to trigger an immediate heads-up popup banner test on this device.",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 13 : 11.5,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          "Send Test Notification (3s)",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          NotificationService.instance.sendTestNotification(delaySeconds: 3);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Test notification will pop up in 3 seconds! You can stay here or minimize the app."),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: fieldSpace),
                _buildCardGroup(
                  isTab: isTab,
                  context,
                  theme: theme,
                  title: "Notification Channels",
                  children: [
                    _NotificationTile(
                      isTab: isTab,
                      title: "Email Notifications",
                      subtitle: "Receive updates via email",
                      value: state.emailEnabled,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('email', val)),
                    ),
                    _NotificationTile(
                      isTab: isTab,
                      title: "SMS Notifications",
                      subtitle: "Receive updates via SMS",
                      value: state.smsEnabled,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('sms', val)),
                    ),
                    _NotificationTile(
                      isTab: isTab,
                      title: "Push Notifications",
                      subtitle: "Receive in-app push notifications",
                      value: state.pushEnabled,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('push', val)),
                    ),
                  ],
                ),
                const SizedBox(height: fieldSpace),
                _buildCardGroup(
                  isTab: isTab,
                  context,
                  theme: theme,
                  title: "Notification Types",
                  children: [
                    _NotificationTile(
                      isTab: isTab,
                      title: "Appointment Reminders",
                      subtitle: "Get reminded about upcoming appointments",
                      value: state.appointmentReminders,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('appointment', val)),
                    ),
                    _NotificationTile(
                      isTab: isTab,
                      title: "Lab Results",
                      subtitle: "Get notified when lab results are ready",
                      value: state.labResultsNotif,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('lab', val)),
                    ),
                    _NotificationTile(
                      isTab: isTab,
                      title: "Prescription Refills",
                      subtitle: "Reminders for medication refills",
                      value: state.prescriptionReminders,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('user_prescription', val)),
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

  Widget _buildCardGroup(BuildContext context, {required ThemeData theme, required String title, required List<Widget> children, required bool isTab}) {
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
              fontSize:isTab?displayWidth(context) * 0.022: displayWidth(context) * 0.036,
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
    required this.onChanged, required this.isTab,
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
                    fontSize: isTab?displayWidth(context) * 0.02: displayWidth(context) * 0.038,
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
                    fontSize:isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.029,
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
              activeTrackColor: theme.primaryColor.withValues(alpha: 0.5),
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