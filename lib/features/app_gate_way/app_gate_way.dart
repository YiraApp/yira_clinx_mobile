import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import '../../config/app_route/app_router.dart';
import '../../config/app_route/app_routes.dart';
import '../../config/app_theme/app_theme.dart';
import '../../core/global_scaffold_key/global_scaffold_key.dart';
import '../../core/navigation_services/navigation_services.dart';
import '../../core/services/network_services/network_bloc/network_bloc.dart';
import '../../core/widgets/internet_guard.dart';
import '../../core/widgets/notificatio_wrapper.dart';
import '../presentation/auth/on_boarding/on_boarding_bloc/on_boarding_bloc.dart';
import '../presentation/theme/theme_bloc/theme_bloc.dart';

class AppGateway extends StatelessWidget {
  const AppGateway({super.key});

  // static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NetworkBloc>(create: (context) => sl<NetworkBloc>()),
        BlocProvider<OnBoardingBloc>(create: (_) => sl<OnBoardingBloc>()),
        BlocProvider<ThemeBloc>(
          create: (_) => sl<ThemeBloc>()..add(LoadThemeEvent()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        buildWhen: (previous, current) => previous.themeMode != current.themeMode,
        builder: (context, themeState) {
          return MaterialApp(
            navigatorKey: NavigationService.navigatorKey, // 2. Assign the key here
            supportedLocales: const [Locale("en")],
            localizationsDelegates: const [CountryLocalizations.delegate],
            scaffoldMessengerKey: Globals.scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            initialRoute: AppRoutes.initial,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, navigationTree) {
              if (navigationTree == null) return const SizedBox.shrink();

              return NotificationListenerWrapper(
                onNotificationPayload: (payloadString) {
                  try {
                    final Map<String, dynamic> payload = jsonDecode(payloadString);
                    final String? targetRoute = payload['route'];
                    final String? itemId = payload['id'];

                    if (targetRoute != null) {
                      NavigationService.navigatorKey.currentState?.pushNamed(
                        targetRoute,
                        arguments: itemId,
                      );
                    }
                  } catch (e) {
                    debugPrint("Notification routing error: $e");
                  }
                },
                child: InternetGuard(child: navigationTree),
              );
            },
          );
        },
      ),
    );
  }
}