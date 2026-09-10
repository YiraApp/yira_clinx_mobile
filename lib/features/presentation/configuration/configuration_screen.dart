import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import '../../../core/services/network_services/network_listener/network_listener.dart';
import '../splash/yira_splash_screen.dart';
import 'config_bloc.dart';

class UserConfigurationScreen extends StatefulWidget {
  const UserConfigurationScreen({super.key});

  /// Centralized routing logic after configuration succeeds
  static void handleConfigSuccess(
    BuildContext context,
    GetDataSuccessState state,
  ) {
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
          arguments: routingArguments,
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
      } else if (payload != null &&
          ((payload.roles != null && payload.roles!.isNotEmpty) ||
              (payload.id != null && payload.id!.isNotEmpty))) {
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return NetworkListener(
      onOnline: () {
        context.read<ConfigBloc>().add(LoadUserConfigurationScreen());
      },
      child: BlocConsumer<ConfigBloc, ConfigState>(
        listener: (context, state) {
          if (state is GetDataSuccessState) {
            UserConfigurationScreen.handleConfigSuccess(context, state);
          } else if (state is GetDataFailureState) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.signIn,
              (route) => false,
            );
          }
        },
        listenWhen: (previous, current) =>
            current is GetDataSuccessState || current is GetDataFailureState,
        builder: (context, state) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            extendBodyBehindAppBar: true,
            extendBody: true,
            body: YiraSplashScreen(),
          );
        },
      ),
    );
  }
}
