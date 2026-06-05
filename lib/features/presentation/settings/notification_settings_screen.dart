import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
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
                vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               /* CommonText(
                  "Choose how you want to receive notifications",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.035,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 32),*/

                _buildCardGroup(
                  context,
                  theme: theme,
                  title: "Notification Channels",
                  children: [
                    _NotificationTile(
                      title: "Email Notifications",
                      subtitle: "Receive updates via email",
                      value: state.emailEnabled,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('email', val)),
                    ),
                    _NotificationTile(
                      title: "SMS Notifications",
                      subtitle: "Receive updates via SMS",
                      value: state.smsEnabled,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('sms', val)),
                    ),
                    _NotificationTile(
                      title: "Push Notifications",
                      subtitle: "Receive in-app push notifications",
                      value: state.pushEnabled,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('push', val)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildCardGroup(
                  context,
                  theme: theme,
                  title: "Notification Types",
                  children: [
                    _NotificationTile(
                      title: "Appointment Reminders",
                      subtitle: "Get reminded about upcoming appointments",
                      value: state.appointmentReminders,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('appointment', val)),
                    ),
                    _NotificationTile(
                      title: "Lab Results",
                      subtitle: "Get notified when lab results are ready",
                      value: state.labResultsNotif,
                      onChanged: (val) => context.read<SettingsBloc>().add(NotificationToggleChanged('lab', val)),
                    ),
                    _NotificationTile(
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

  Widget _buildCardGroup(BuildContext context, {required ThemeData theme, required String title, required List<Widget> children}) {
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
              fontSize: displayWidth(context) * 0.036,
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

  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
                    fontSize: displayWidth(context) * 0.038,
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
                    fontSize: displayWidth(context) * 0.029,
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
              activeColor: theme.primaryColor,
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