import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:yiraclinics/config/app_route/app_router.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../core/constants/constants.dart';
import 'config_bloc.dart';

class UserConfigurationScreen extends StatefulWidget {
  const UserConfigurationScreen({super.key});

  @override
  State<UserConfigurationScreen> createState() => _UserConfigurationScreenState();
}

class _UserConfigurationScreenState extends State<UserConfigurationScreen> {
  @override
  void initState() {
    context.read<ConfigBloc>().add(LoadUserConfigurationScreen());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is GetDataSuccessState) {
          var payload = state.loginEntity?.data;
          debugPrint('getUserData payload---$payload');
          if (payload?.navigationId == '1') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.dashboardPatientDetails,
              (route) => false,
            );
          } else if (payload?.navigationId == '2') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.docDashboard,
              (route) => false,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.unsupportedRole,
              (route) => false,
              arguments: state.loginEntity,
            );
          }
        }
      },
      listenWhen: (previous, current) => current is GetDataSuccessState,

      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: displayHeight(context) / 5),
                SizedBox(
                  height: displayHeight(context) * 0.35,
                  child: Lottie.asset(
                    'assets/json/ic_loader.json',
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  "Setting up your experience",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: appPoppinFont,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please wait while we sync your preferences",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontFamily: appPoppinFont,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
