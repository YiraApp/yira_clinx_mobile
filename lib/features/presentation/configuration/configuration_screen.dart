import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/network_services/network_listener/network_listener.dart';
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

    return NetworkListener(
      onOnline: (){
        context.read<ConfigBloc>().add(LoadUserConfigurationScreen());
      },
      child: BlocConsumer<ConfigBloc, ConfigState>(
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
                dynamic routingArguments;
                if (updateType == 'force' || updateType == 'soft') {
                   routingArguments = state.versionData?.data;
                }
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  targetRoute,
                  (route) => false,
                  arguments: routingArguments
                );
                return;
              }
            } else {
              final payload = state.coreData.data;
              final navigationId = payload?.navigationId?.toString().trim();
              final roleName = (payload?.latestUserRole ?? '').toLowerCase().trim();

              final isPatient = roleName.contains('patient') ||
                  roleName == 'user' ||
                  roleName.contains('consumer') ||
                  roleName.contains('client') ||
                  navigationId == '1';

              final isDoctor = roleName.contains('doctor') ||
                  roleName.contains('provider') ||
                  roleName.contains('physician') ||
                  navigationId == '2';

              if (isPatient && !isDoctor) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.patientDashboard,
                  (route) => false,
                );
                return;
              }

              final navigationRoutes = const {
                '1': AppRoutes.patientDashboard,
                '2': AppRoutes.doctorDashboard,
                '3': AppRoutes.doctorDashboard,
                '4': AppRoutes.doctorDashboard,
                '5': AppRoutes.doctorDashboard,
                '6': AppRoutes.doctorDashboard,
              };

              final coreRoute = navigationRoutes[navigationId];
              if (coreRoute != null) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  coreRoute,
                  (route) => false,
                );
              } else if (isPatient) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.patientDashboard,
                  (route) => false,
                );
              } else if (payload != null && ((payload.roles != null && payload.roles!.isNotEmpty) || (payload.id != null && payload.id!.isNotEmpty))) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  isDoctor ? AppRoutes.doctorDashboard : AppRoutes.patientDashboard,
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
      ),
    );
  }
}
