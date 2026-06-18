
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import '../../config/app_route/app_router.dart';
import '../../config/app_route/app_routes.dart';
import '../../config/app_theme/app_theme.dart';
import '../../core/global_scaffold_key/global_scaffold_key.dart';
import '../../core/services/network_services/network_bloc/network_bloc.dart';
import '../../core/widgets/internet_guard.dart';
import '../presentation/auth/on_boarding/on_boarding_bloc/on_boarding_bloc.dart';
import '../presentation/theme/theme_bloc/theme_bloc.dart';
class AppGateway extends StatelessWidget {
  const AppGateway({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NetworkBloc>(
          create: (context) => sl<NetworkBloc>(),
        ),
        BlocProvider<OnBoardingBloc>(create: (_) => sl<OnBoardingBloc>()),
        BlocProvider<ThemeBloc>(create: (_) => sl<ThemeBloc>()..add(LoadThemeEvent())),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        buildWhen: (previous, current) => previous.themeMode != current.themeMode,
        builder: (context, themeState) {
          return MaterialApp(
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
              return InternetGuard(child: navigationTree);
            },
          );
        },
      ),
    );
  }
}