import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../config/app_route/app_routes.dart';
import '../../../core/constants/clinx_storage_keys.dart';
import '../../../core/global_session/global_menu_session.dart';
import '../../../core/local/global_session.dart';
import '../../../core/local/shared_preferences.dart';
import '../../../core/urls/urls.dart';
import '../../../di/dependency_injection.dart';
import '../../domain/repositories/side_menu/side_menu_repo.dart';
import 'auth_bloc/auth_bloc.dart';
import 'yira_splash_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  late final SharedPrefsService _sharedPrefsService;
  bool _timerFinished = false;

  @override
  void initState() {
    super.initState();
    _sharedPrefsService = sl<SharedPrefsService>();
    context.read<AuthBloc>().add(AppStarted());
     _startTimer();
  }

  void _startTimer() async {
    await Future.delayed(const Duration(seconds: 7));
    if (mounted) {
      setState(() {
        _timerFinished = true;
      });
    }
     _attemptNavigation();
  }

  void _attemptNavigation() async {
    if (!_timerFinished) return;

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final bool isLoggedIn =
          _sharedPrefsService.getValue<bool>(ClinxStorageKeys.isUserLoggedIn) ??
          false;

      if (isLoggedIn && currentUser != null && currentUser.data != null) {
        final payload = currentUser.data!;

        try {
          await GlobalMenuSession.instance.initFromLocalCache(
            repository: sl<SideMenuRepo>(),
            userId: payload.id ?? '',
            latestRoleId: payload.latestRoleId ?? '',
            latestOrgId: payload.latestOrgId ?? 0,
            latestHospitalId: payload.latestHospitalId ?? 0,
            sideMenuKeyPrefix: sideMenuKey,
            baseUrl: URLs.sideMenuUrl,
          );
          developer.log(
            "Splash Screen: Global model warm-up completed.",
            name: "SplashScreen",
          );
        } catch (cacheError) {
          debugPrint(
            "Splash Screen: Optional local side menu warm-up skipped: $cacheError",
          );
        }

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.userConfiguration,
          (route) => false,
        );
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

      if (!mounted) return;
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
    // Crisp dark status bar icons for clean light mode
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: const YiraSplashScreen(),
    );
  }
}

