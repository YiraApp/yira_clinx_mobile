import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/settings/setting_bloc/setting_bloc.dart';
import 'package:yiraclinics/features/presentation/settings/widgets/custom_setting_tile.dart';
import 'package:yiraclinics/features/presentation/settings/widgets/setting_group_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = displayWidth(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          'User Settings',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: width * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        builder: (context, state) {
          String activeThemeModeString = "Light Mode";
          if (state.themeMode == ThemeMode.dark) {
            activeThemeModeString = "Dark Mode";
          } else if (state.themeMode == ThemeMode.system) {
            activeThemeModeString = isDark
                ? "Dark Mode (System)"
                : "Light Mode (System)";
          }

          String activeLanguageString = state.selectedLanguageCode == 'en'
              ? 'English (US)'
              : state.selectedLanguageCode.toUpperCase();

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: screenHorizontalSpacePadding,
              vertical: 16.0,
            ),
            children: [
              _buildSectionHeader(context, "ACCOUNT SECURITY"),
              const SizedBox(height: 10),
              SettingsGroupCard(
                children: [
                  CustomSettingTile(
                    icon: Icons.lock_outline_rounded,
                    title: "Password and security",
                    subtitle: "Manage passwords",
                    onTap: () {
                      context.read<SettingsBloc>().add(
                        PasswordAndSecurityNavEvent(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionHeader(context, "COMMUNICATIONS"),
              const SizedBox(height: 10),
              SettingsGroupCard(
                children: [
                  CustomSettingTile(
                    icon: Icons.notifications_none_rounded,
                    title: "Notification settings",
                    subtitle: "Push, email, and alert triggers",
                    onTap: () {
                      context.read<SettingsBloc>().add(NotificationNavEvent());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionHeader(context, "APP PREFERENCES"),
              const SizedBox(height: 10),
              SettingsGroupCard(
                children: [
                  CustomSettingTile(
                    icon: Icons.language_rounded,
                    title: "Language settings",
                    subtitle: activeLanguageString,
                    showDivider: true,
                    onTap: () {
                      context.read<SettingsBloc>().add(LanguageNavEvent());
                    },
                  ),
                  CustomSettingTile(
                    icon: Icons.palette_outlined,
                    title: "Theme settings",
                    subtitle: activeThemeModeString,
                    onTap: () {
                      context.read<SettingsBloc>().add(ThemeNavEvent());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionHeader(context, "TERMINATE ACCOUNT"),
              const SizedBox(height: 10),
              SettingsGroupCard(
                children: [
                  CustomSettingTile(
                    icon: Icons.delete_forever_rounded,
                    title: "Delete Account",
                    subtitle: "Permanently erase your data",
                    onTap: () {
                      context.read<SettingsBloc>().add(DeleteAccountNavEvent());
                    },
                  ),
                ],
              ),
            ],
          );
        },
        buildWhen: (previous, current) =>
            current is! PasswordAndSecurityNavState &&
            current is! NotificationNavState &&
            current is! LanguageNavState &&
            current is! ThemeNavState &&
            current is! DeleteAccountNavState,
        listener: (BuildContext context, SettingsState state) {
          switch (state) {
            case PasswordAndSecurityNavState():
              Navigator.pushNamed(context, AppRoutes.changePasswordScreen);
              break;
            case NotificationNavState():
              Navigator.pushNamed(
                context,
                AppRoutes.notificationSettingsScreen,
              );

              break;
            case LanguageNavState():
              Navigator.pushNamed(context, AppRoutes.languageSelectionScreen);

              break;
            case ThemeNavState():
              Navigator.pushNamed(context, AppRoutes.appearanceScreen);

              break;
            case DeleteAccountNavState():
              Navigator.pushNamed(context, AppRoutes.closeAccountScreen);

              break;

            default:
              Navigator.pushNamed(context, AppRoutes.changePasswordScreen);
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = displayWidth(context);
    return Text(
      title,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: width * 0.031,
        fontWeight: FontWeight.w600,
        color: (isDark ? textLightDarkColor : scoreSubTextColor),
        letterSpacing: 1.1,
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account?"),
          content: const Text(
            "This action is permanent and cannot be undone. All clinical data, profile records, and configurations will be permanently deleted.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                // Dispatch your delete account event here
                // context.read<SettingsBloc>().add(DeleteAccountRequestedEvent());
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
