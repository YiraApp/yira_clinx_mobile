import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../config/app_route/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  bool _timerFinished = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _startTimer();
  }

  void _startTimer() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _timerFinished = true;
      });
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.docDashboard,
      (route) => false,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTab = isTablet(context);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isTab
        ? Scaffold(
            key: scaffoldKey,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            extendBodyBehindAppBar: true,
            extendBody: true,
            body: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          isDarkMode
                              ? 'assets/images/ic_splashs.png'
                              : 'assets/images/ic_splash_light.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: SvgPicture.asset(
                            'assets/images/svgs/ic_apps_logo.svg',
                            width: isTab ? 65 : 60,
                            height: isTab ? 65 : 60,
                          ),
                        ),
                        // SvgPicture.asset('assets/images/ic_splash_logo.svg'),
                        SizedBox(height: 10),
                        CommonText(
                          projectTitle,
                          style: TextStyle(
                            fontSize: displayWidth(context) * 0.04,
                            fontWeight: FontWeight.w600,
                            fontFamily: appPoppinFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  right: 0,
                  left: 0,
                  child: Column(
                    children: [
                      if (!_timerFinished)
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          backgroundColor: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : primaryColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.white : primaryColor,
                          ),
                        ),
                      SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 18),
                          SizedBox(width: 4),
                          CommonText(
                            'SECURE HEALTH ENVIRONMENT',
                            style: TextStyle(
                              fontSize: displayWidth(context) * 0.022,
                              fontWeight: FontWeight.w500,
                              fontFamily: appPoppinFont,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            key: scaffoldKey,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            extendBodyBehindAppBar: true,
            extendBody: true,

            body: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          isDarkMode
                              ? 'assets/images/ic_splashs.png'
                              : 'assets/images/ic_splash_light.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: SvgPicture.asset(
                            'assets/images/svgs/ic_apps_logo.svg',
                            width:  70,
                            height:  70,
                          ),
                        ),
                        // SvgPicture.asset('assets/images/ic_splash_logo.svg'),
                        SizedBox(height: 10),
                        CommonText(
                          projectTitle,
                          style: TextStyle(
                            fontSize: displayWidth(context) * 0.06,
                            fontWeight: FontWeight.w600,
                            fontFamily: appPoppinFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  right: 0,
                  left: 0,
                  child: Column(
                    children: [
                      if (!_timerFinished)
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          backgroundColor: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : primaryColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.white : primaryColor,
                          ),
                        ),
                      SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 15),
                          SizedBox(width: 4),
                          CommonText(
                            'SECURE HEALTH ENVIRONMENT',
                            style: TextStyle(
                              fontSize: displayWidth(context) * 0.028,
                              fontWeight: FontWeight.w500,
                              fontFamily: appPoppinFont,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
