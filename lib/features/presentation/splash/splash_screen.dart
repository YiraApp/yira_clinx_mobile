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
import '../configuration/config_bloc.dart';
import '../configuration/configuration_screen.dart';
import 'auth_bloc/auth_bloc.dart';
import 'yira_splash_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  late final SharedPrefsService _sharedPrefsService;
  bool _animationFinished = false;
  bool _hasNavigated = false;
  GetDataSuccessState? _pendingSuccessState;
  bool _configFailed = false;

  @override
  void initState() {
    super.initState();
    _sharedPrefsService = sl<SharedPrefsService>();
    context.read<AuthBloc>().add(AppStarted());
    _initializeFlow();
  }

  void _initializeFlow() async {
    final bool isLoggedIn =
        _sharedPrefsService.getValue<bool>(ClinxStorageKeys.isUserLoggedIn) ??
        false;
    final currentUser = GlobalSession.instance.userNotifier.value;

    if (isLoggedIn && currentUser != null && currentUser.data != null) {
      final payload = currentUser.data!;

      // Start loading preferences in the background immediately
      context.read<ConfigBloc>().add(LoadUserConfigurationScreen());

      // Warm up side menu in parallel
      GlobalMenuSession.instance.initFromLocalCache(
        repository: sl<SideMenuRepo>(),
        userId: payload.id ?? '',
        latestRoleId: payload.latestRoleId ?? '',
        latestOrgId: payload.latestOrgId ?? 0,
        latestHospitalId: payload.latestHospitalId ?? 0,
        sideMenuKeyPrefix: sideMenuKey,
        baseUrl: URLs.sideMenuUrl,
      ).catchError((cacheError) {
        debugPrint(
          "Splash Screen: Optional local side menu warm-up skipped: $cacheError",
        );
      });
    }

    // Fallback safety timeout (10 seconds) in case animation callback is interrupted
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_animationFinished) {
        setState(() {
          _animationFinished = true;
        });
        _attemptNavigation();
      }
    });
  }

  void _attemptNavigation() {
    // Strictly wait until the full "Health in Your Hands" animation sequence completes
    if (_hasNavigated || !mounted || !_animationFinished) return;

    final bool isLoggedIn =
        _sharedPrefsService.getValue<bool>(ClinxStorageKeys.isUserLoggedIn) ??
        false;
    final currentUser = GlobalSession.instance.userNotifier.value;

    if (!isLoggedIn || currentUser == null || currentUser.data == null) {
      _hasNavigated = true;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signIn,
        (route) => false,
      );
      return;
    }

    // If user is logged in, navigate once configuration data has also loaded
    if (_pendingSuccessState != null) {
      _hasNavigated = true;
      UserConfigurationScreen.handleConfigSuccess(
        context,
        _pendingSuccessState!,
      );
    } else if (_configFailed) {
      _hasNavigated = true;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signIn,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Crisp dark status bar icons for clean light mode
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return BlocListener<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is GetDataSuccessState) {
          _pendingSuccessState = state;
          _attemptNavigation();
        } else if (state is GetDataFailureState) {
          _configFailed = true;
          _attemptNavigation();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: YiraSplashScreen(
          onAnimationComplete: () {
            if (mounted && !_animationFinished) {
              setState(() {
                _animationFinished = true;
              });
              _attemptNavigation();
            }
          },
        ),
      ),
    );
  }
}
