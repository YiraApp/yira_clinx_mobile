import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../core/constants/constants.dart';
import 'config_bloc.dart';

class UserConfigurationScreen extends StatefulWidget {
  const UserConfigurationScreen({super.key});

  @override
  State<UserConfigurationScreen> createState() =>
      _UserConfigurationScreenState();
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
          if (state.versionData?.data?.versionStatus == false) {
            final updateType =
                state.versionData?.data?.updateType.toLowerCase() ?? '';

            final updateRoutes = const {
              'force': AppRoutes.forceUpdateScreen,
              'soft': AppRoutes.softUpdateScreen,
              'maintenance': AppRoutes.maintenanceScreen,
              'logout': AppRoutes.forceUpdateScreen,
            };

            final targetRoute = updateRoutes[updateType];
            if (targetRoute != null) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                targetRoute,
                (route) => false,
              );
              return;
            }
          } else {
            final payload = state.coreData.data;
            final navigationId = payload?.navigationId;
            final navigationRoutes = const {
              '1': AppRoutes.dashboardPatientDetails,
              '2': AppRoutes.docDashboard,
            };

            final coreRoute = navigationRoutes[navigationId];
            if (coreRoute != null) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                coreRoute,
                (route) => false,
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.unsupportedRole,
                (route) => false,
                arguments: state.coreData,
              );
            }
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
