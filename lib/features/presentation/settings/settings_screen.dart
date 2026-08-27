import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/settings/setting_bloc/setting_bloc.dart';
import 'package:yiraclinics/features/presentation/settings/widgets/custom_setting_tile.dart';
import 'package:yiraclinics/features/presentation/settings/widgets/setting_group_widget.dart';
import 'package:yiraclinics/core/tour/provider_tour_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CommonAppBar(
        titleText: "User Settings",
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
              vertical: screenTopPadding,
            ),
            children: [
              _buildSectionHeader(context, "Account & Profile", isTab),
              const SizedBox(height: titleSpace),
              SettingsGroupCard(
                isTab: isTab,
                children: [
                  CustomSettingTile(
                    isTab: isTab,
                    icon: Icons.person_outline_rounded,
                    title: "Doctor Profile",
                    subtitle: "View credentials & clinic details",
                    showDivider: true,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                  ),
                  CustomSettingTile(
                    isTab: isTab,
                    icon: Icons.vpn_key_outlined,
                    title: "Medical Record Consents",
                    subtitle: "Manage doctor access requests & approvals",
                    showDivider: true,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.patientConsentsScreen);
                    },
                  ),
                  CustomSettingTile(
                    isTab: isTab,
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
              const SizedBox(height: fieldSpace),

              _buildSectionHeader(context, "Communications",isTab),
              const SizedBox(height: titleSpace),
              SettingsGroupCard(
                isTab: isTab,
                children: [
                  CustomSettingTile(
                    isTab: isTab,
                    icon: Icons.notifications_none_rounded,
                    title: "Notification settings",
                    subtitle: "Push, email, and alert triggers",
                    onTap: () {
                      context.read<SettingsBloc>().add(NotificationNavEvent());
                    },
                  ),
                ],
              ),
              const SizedBox(height: fieldSpace),

              _buildSectionHeader(context, "App Preferences",isTab),
              const SizedBox(height: titleSpace),
              SettingsGroupCard(
                isTab: isTab,
                children: [
                  CustomSettingTile(
                    isTab: isTab,
                    icon: Icons.tour_outlined,
                    title: "Interactive Product Tour",
                    subtitle: "Restart the guided walkthrough for all features",
                    showDivider: true,
                    onTap: () {
                      ProviderTourController().restartTour();
                    },
                  ),
                  CustomSettingTile(
                    isTab: isTab,
                    icon: Icons.language_rounded,
                    title: "Language settings",
                    subtitle: activeLanguageString,
                    showDivider: true,
                    onTap: () {
                      context.read<SettingsBloc>().add(LanguageNavEvent());
                    },
                  ),
                  CustomSettingTile(
                    isTab: isTab,
                    icon: Icons.palette_outlined,
                    title: "Theme settings",
                    subtitle: activeThemeModeString,
                    onTap: () {
                      context.read<SettingsBloc>().add(ThemeNavEvent());
                    },
                  ),
                ],
              ),
              const SizedBox(height: fieldSpace),

              _buildSectionHeader(context, "Terminate Account",isTab),
              const SizedBox(height: titleSpace),
              SettingsGroupCard(
                isTab: isTab,
                children: [
                  CustomSettingTile(
                    isTab: isTab,
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
        listenWhen: (previous, current) =>
        current is PasswordAndSecurityNavState ||
            current is NotificationNavState ||
            current is LanguageNavState ||
            current is ThemeNavState ||
            current is DeleteAccountNavState,
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
              break;
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,bool isTab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = displayWidth(context);
    return Text(
      title,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: isTab ? width * 0.02 : width * 0.031,
        fontWeight: FontWeight.w600,
        color: (isDark ? textLightDarkColor : scoreSubTextColor),
        letterSpacing: 1.1,
      ),
    );
  }
}
