import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/app_navigation_drawer/widgets/custom_menu_title.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../colors/colors.dart';
import '../common_size_helpers/common_size_helpers.dart';
import '../common_widgets/common_text.dart';
import '../custom_dialogue/custom_dialogue.dart';
import '../custom_dialogue/sign_out_alert.dart';
import 'model/nav_item_model.dart';
import 'navigation_drawer-bloc/navigation_drawer_bloc.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    final containerBgColor = isDark ? darkModeBgColor : lightModeBgColor;

    final dividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.withOpacity(0.2);

    return LayoutBuilder(
      builder: (context, parentConstraints) {
        final double targetWidth = isTab ? 360 : displayWidth(context) * 0.82;

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
            buildWhen: (previous, current) =>
            previous != current &&
                current is! DashboardNavState &&
                current is! AppointmentsNavState &&
                current is! PatientsNavState &&
                current is! DoctorSlotNavState &&
                current is! SettingsNavState &&
                current is! ReadAboutUsNavState &&
                current is! ContactNavState &&
                current is! PrivacyNavState &&
                current is! LogoutNavState,
            listenWhen: (context, current) =>
            current is DashboardNavState ||
                current is AppointmentsNavState ||
                current is PatientsNavState ||
                current is DoctorSlotNavState ||
                current is SettingsNavState ||
                current is ReadAboutUsNavState ||
                current is ContactNavState ||
                current is PrivacyNavState ||
                current is LogoutNavState,
            listener: (BuildContext context, NavigationDrawerState state) async {
              switch (state) {
                case DashboardNavState():
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.docDashboard);
                  break;
                case AppointmentsNavState():
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.appointmentDashboardScreen,
                  );
                  break;
                case PatientsNavState():
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.patientManagementScreen,
                  );
                  break;
                case DoctorSlotNavState():
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.slotDashboard);
                  break;
                case SettingsNavState():
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.settingsScreen);
                  break;
                case ReadAboutUsNavState():
                  Navigator.pop(context);
                  CustomUrlDialog.customLauncherDialogue(
                    context,
                    'Read About Us',
                    'Yira Clinx (ClinicX) is a next-generation, AI-powered clinic management platform designed to automate and optimize medical practice workflows. Reversing manual administration friction, the platform natively unifies intelligent appointment scheduling, paperless digital check-ins, automated clinical documentation, and smart post-visit summaries delivered seamlessly via WhatsApp, SMS, and Email to ensure peak clinic efficiency.',
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
                    'We\'re here to help! If you\'re experiencing any system downtime, sync anomalies, or need immediate assistance managing your patient queues and configurations, please reach out to our dedicated clinic support operations. Our team is ready to ensure a smooth, reliable digital practice environment for you and your staff. Feel free to contact us anytime...',
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
                    'We at Yira Clinx recognize that as a healthcare professional or practice administrator, the privacy of your operational workflows and your patients\' medical records is paramount. We take patient data protection, secure electronic health record (EHR) storage, and compliance with healthcare digital frameworks extremely seriously. We are committed to maintaining rigorous data access control, end-to-end transport encryptions, and robust architecture protocols to safeguard all confidential clinical assets handled on our systems...',
                    primaryColor,
                    'https://yira.ai/clinx-privacy',
                    'More',
                    'assets/images/ic_privacy_plc.png',
                  );
                  break;
                case LogoutNavState():
                  Navigator.pop(context);
                  await SignOutAlert
                      .showSignCustomDialog(
                      context,
                      primaryColor,
                      );
                  break;
                default:
                  break;
              }
            },
            builder: (context, state) {
              return SafeArea(
                right: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, state, targetWidth, isTab),
                    SizedBox(height: targetWidth * 0.05),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          vertical: targetWidth * 0.025,
                        ),
                        children: [
                          ...List.generate(primaryNavItems.length, (index) {
                            final item = primaryNavItems[index];
                            return CustomMenuTile(
                              title: item.title,
                              icon: item.icon,
                              isSelected: state.selectedIndex == index,
                              onTap: () {
                                switch (index) {
                                  case 0:
                                    context.read<NavigationDrawerBloc>().add(
                                      const DashBoardNav(),
                                    );
                                    break;
                                  case 1:
                                    context.read<NavigationDrawerBloc>().add(
                                      const AppointmentsNav(),
                                    );
                                    break;
                                  case 2:
                                    context.read<NavigationDrawerBloc>().add(
                                      const PatientsNav(),
                                    );
                                    break;
                                  case 3:
                                    context.read<NavigationDrawerBloc>().add(
                                      const DoctorSlotsNav(),
                                    );
                                  case 4:
                                    context.read<NavigationDrawerBloc>().add(
                                      const ReadAboutUsNavEvent(),
                                    );
                                  case 5:
                                    context.read<NavigationDrawerBloc>().add(
                                      const ContactNavEvent(),
                                    );
                                  case 6:
                                    context.read<NavigationDrawerBloc>().add(
                                      const PrivacyNavEvent(),
                                    );
                                    break;
                                  default:
                                }
                              },
                            );
                          }),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: targetWidth * 0.08,
                              vertical: 12,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 1.2,
                              color: dividerColor,
                            ),
                          ),
                          CustomMenuTile(
                            title: "Settings",
                            icon: Icons.settings_outlined,
                            isSelected: state.selectedIndex == 7,
                            onTap: () => context
                                .read<NavigationDrawerBloc>()
                                .add(const SettingsNav()),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: targetWidth * 0.08,
                              vertical: 12,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 1.2,
                              color: dividerColor,
                            ),
                          ),
                          CustomMenuTile(
                            title: "Logout",
                            icon: Icons.logout_rounded,
                            isSelected: false,
                            customColor: Colors.red,
                            onTap: () {
                              context.read<NavigationDrawerBloc>().add(
                                const LogoutNavEvent(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: targetWidth * 0.1,
                        bottom: 20.0,
                        top: 12,
                      ),
                      child: CommonText(
                        state.appVersion,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: targetWidth * (isTab ? 0.04 : 0.034),
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context,
      NavigationDrawerState state,
      double currentDrawerWidth,
      bool isTab,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: currentDrawerWidth * 0.09,
        top: currentDrawerWidth * 0.09,
        right: currentDrawerWidth * 0.07,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: currentDrawerWidth * 0.115,
                backgroundColor: isDark
                    ? const Color(0xFF232733)
                    : const Color(0xFFE9ECEF),
                backgroundImage: state.profileImageUrl != null
                    ? NetworkImage(state.profileImageUrl!)
                    : null,
                child: state.profileImageUrl == null
                    ? Icon(
                  Icons.person_rounded,
                  size: currentDrawerWidth * 0.115,
                  color: theme.primaryColor.withOpacity(0.7),
                )
                    : null,
              ),
            ),
          ),
          SizedBox(height: currentDrawerWidth * 0.06),
          CommonText(
            state.doctorName,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: currentDrawerWidth * (isTab ? 0.052 : 0.05),
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0A2540),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          CommonText(
            state.doctorRole,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: currentDrawerWidth * (isTab ? 0.042 : 0.038),
              color: isDark ? Colors.white60 : Colors.grey.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}