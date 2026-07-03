import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../config/app_route/app_routes.dart';
import '../../../core/constants/clinx_storage_keys.dart';
import '../../../core/local/global_session.dart';
import '../../../core/local/shared_preferences.dart';
import '../../../di/dependency_injection.dart';
import 'auth_bloc/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  late final SharedPrefsService _sharedPrefsService;
  bool _timerFinished = false;
  AuthState? _latestState;

  @override
  void initState() {
    super.initState();
    _sharedPrefsService = sl<SharedPrefsService>();
    context.read<AuthBloc>().add(AppStarted());
    _startTimer();
  }

  void _startTimer() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _timerFinished = true;
      });
    }
    _attemptNavigation();
  }

  void _attemptNavigation() {
    if (!_timerFinished) return;

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final bool isLoggedIn =
          _sharedPrefsService.getValue<bool>(ClinxStorageKeys.isUserLoggedIn) ??
          false;
      if (isLoggedIn && currentUser != null && currentUser.data != null) {
        final payload = currentUser.data!;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.userConfiguration,
              (route) => false
        );
        /*if (payload.navigationId == '2') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.docDashboard,
            (route) => false,
          );
        } else if (payload.navigationId == '1') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboardPatientDetails,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.unsupportedRole,
            (route) => false,
            arguments: currentUser,
          );
        }*/
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.signIn,
          (route) => false,
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        "CRITICAL (SplashScreen): Navigation error routing sequence: $error",
      );
      debugPrint("Stacktrace: $stackTrace");

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signIn,
        (route) => false,
      );
    }
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
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: SizedBox.shrink(),
            ),
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: SizedBox.shrink(),
            ),
            key: scaffoldKey,
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
                            width: 70,
                            height: 70,
                          ),
                        ),
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
