import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../core/colors/colors.dart';
import '../../../core/common_appbar/common_app_bar.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/custom_button.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isTabletDevice = isTablet(context);
    final double refWidth = displayWidth(context);
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: false,
        titleSpacing: screenHorizontalSpacePadding,
        /* leading: Padding(
          padding: const EdgeInsets.all(14.0),
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(2)),
            child: SvgPicture.asset(
              'assets/images/svgs/ic_apps_logo.svg',
              height: 40,
              width: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),*/
        title: Text(
          projectTitle,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTabletDevice
                ? displayWidth(context) * 0.022
                : displayWidth(context) * 0.046,
            fontWeight: FontWeight.w700,
            color: adaptiveTextColor,
            letterSpacing: -0.5,
          ),
        ),
        actions: [],
      ),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTabletDevice ? 460 : double.infinity,
          ),
          child: Container(
            margin: EdgeInsets.all(isTabletDevice ? 24.0 : 0.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            decoration: isTabletDevice
                ? BoxDecoration(
                    color: theme.cardColor.withOpacity(isDarkMode ? 0.6 : 0.9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(
                        isDarkMode ? 0.08 : 0.05,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDarkMode ? 0.2 : 0.04,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: isTabletDevice ? 190 : refWidth * 0.44,
                      width: isTabletDevice ? 190 : refWidth * 0.44,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      height: isTabletDevice ? 150 : refWidth * 0.35,
                      width: isTabletDevice ? 150 : refWidth * 0.35,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      height: isTabletDevice ? 110 : refWidth * 0.26,
                      width: isTabletDevice ? 110 : refWidth * 0.26,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? theme.colorScheme.surface
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(
                              isDarkMode ? 0.15 : 0.08,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.all(
                          Radius.circular(
                            isTabletDevice ? 110 / 2 : refWidth * 0.26 / 2,
                          ),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/svgs/ic_apps_logo.svg',

                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                CommonText(
                  'Securely Logging Out?',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.045,
                  ),
                ),
                const SizedBox(height: 14),

                // Body Content Copy using customized micro-line height tracking
                CommonText(
                  "Your session has timed out or a server disconnection occurred. For your security, please log out and sign back in to continue managing your clinic tasks.",
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.035,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),

                const Spacer(flex: 5),
                CustomElevatedButton(
                  noElevation: true,
                  height: 50,
                  width: double.infinity,
                  text: "Log Out",
                  onPressed: () {},
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
