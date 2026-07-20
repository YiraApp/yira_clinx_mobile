import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/auth/role_bloc/role_bloc.dart';
import '../../features/domain/entities/side_menu/side_menu_entity.dart';
import '../../features/presentation/auth/select_role_screen.dart';
import '../colors/colors.dart';
import '../common_size_helpers/common_size_helpers.dart';
import '../custom_dialogue/custom_dialogue.dart';
import '../custom_dialogue/sign_out_alert.dart';
import '../global_session/global_menu_session.dart';
import '../local/global_session.dart';
import '../models/select_role_model.dart';
import 'navigation_drawer-bloc/navigation_drawer_bloc.dart';
import 'widgets/drawer_header_profile.dart';
import 'widgets/drawer_navigation_list.dart';
import 'widgets/drawer_footer_version.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key});

  void _navigateToCleanRoot(BuildContext context, String routeName) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name != routeName) {
      Navigator.pushNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final containerBgColor = isDark ? darkModeBgColor : lightModeBgColor;

    return LayoutBuilder(
      builder: (context, parentConstraints) {
        final double targetWidth = isTab ? 360.0 : displayWidth(context) * 0.82;

        return Container(
          width: targetWidth,
          height: displayHeight(context),
          decoration: BoxDecoration(
            color: containerBgColor,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black54 : Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: BlocConsumer<NavigationDrawerBloc, NavigationDrawerState>(
            buildWhen: (previous, current) => previous.selectedIndex != current.selectedIndex,
            listenWhen: (previous, current) => previous != current,
            listener: (BuildContext context, NavigationDrawerState state) async {
              switch (state) {
                case DashboardNavState():
                  _navigateToCleanRoot(context, AppRoutes.doctorDashboard);
                  break;
                case OrgSwitchNavState():
                  SelectRoleModel data = SelectRoleModel(currentUser?.data?.roles ?? [], true);
                  Navigator.pushNamed(context, AppRoutes.selectRoleScreen, arguments: data);
                  break;
                case AppointmentsNavState():
                  _navigateToCleanRoot(context, AppRoutes.appointmentDashboardScreen);
                  break;
                case PatientsNavState():
                  _navigateToCleanRoot(context, AppRoutes.patientManagementScreen);
                  break;
                case DoctorSlotNavState():
                  _navigateToCleanRoot(context, AppRoutes.slotDashboard);
                  break;
                case SettingsNavState():
                  _navigateToCleanRoot(context, AppRoutes.settingsScreen);
                  break;
                case ReadAboutUsNavState():
                  Navigator.pop(context);
                  CustomUrlDialog.customLauncherDialogue(
                    context,
                    'Read About Us',
                    'Yira Clinx (ClinicX) is a next-generation, AI-powered clinic management platform designed to automate and optimize medical practice workflows...',
                    primaryColor,
                    'https://yira.ai/yira-clinx/',
                    'More',
                    'assets/images/ic_read_abt_us.png',
                  );
                  break;
                case ContactNavState():
                  Navigator.pop(context);
                  CustomUrlDialog.customContactLauncherDialogue(
                    context,
                    'Contact Us',
                    'We\'re here to help! If you\'re experiencing any system downtime...',
                    primaryColor,
                    'https://yira.ai/clinx-support',
                    'More',
                    'assets/images/ic_contact_img.png',
                    isContactUs: true,
                  );
                  break;
                case PrivacyNavState():
                  Navigator.pop(context);
                  CustomUrlDialog.customLauncherDialogue(
                    context,
                    'Privacy Policy',
                    'We at Yira Clinx recognize that as a healthcare professional...',
                    primaryColor,
                    'https://yira.ai/clinx-privacy',
                    'More',
                    'assets/images/ic_privacy_plc.png',
                  );
                  break;
                case LogoutNavState():
                  Navigator.pop(context);
                  await SignOutAlert.showSignCustomDialog(context, primaryColor);
                  break;
                default:
                  break;
              }
            },
            builder: (context, state) {
              return SafeArea(
                right: false,
                child: ValueListenableBuilder<SideMenuEntity?>(
                  valueListenable: GlobalMenuSession.instance.menuNotifier,
                  builder: (context, menuEntity, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DrawerHeaderProfile(currentDrawerWidth: targetWidth, isTab: isTab, profileImageUrl: state.profileImageUrl),
                        SizedBox(height: targetWidth * 0.05),
                        Expanded(
                          child: DrawerNavigationList(
                            state: state,
                            dynamicMenuItems: menuEntity?.data ?? [],
                            targetWidth: targetWidth,
                          ),
                        ),
                        DrawerFooterVersion(targetWidth: targetWidth, isTab: isTab),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}