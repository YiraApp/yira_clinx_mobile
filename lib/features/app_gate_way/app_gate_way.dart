import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/config/app_route/app_router.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/config/app_theme/app_theme.dart';
import 'package:yiraclinics/core/global_scaffold_key/global_scaffold_key.dart';
import 'package:yiraclinics/core/navigation_services/navigation_services.dart';
import 'package:yiraclinics/core/services/network_services/network_bloc/network_bloc.dart';
import 'package:yiraclinics/core/widgets/internet_guard.dart';
import 'package:yiraclinics/core/widgets/notificatio_wrapper.dart';

import 'package:yiraclinics/features/presentation/auth/on_boarding/on_boarding_bloc/on_boarding_bloc.dart';
import 'package:yiraclinics/features/presentation/splash/auth_bloc/auth_bloc.dart';
import 'package:yiraclinics/features/presentation/theme/theme_bloc/theme_bloc.dart';

class AppGateway extends StatelessWidget {
  const AppGateway({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NetworkBloc>(create: (context) => sl<NetworkBloc>()),
        BlocProvider<AuthBloc>(create: (context) => sl<AuthBloc>()),
        BlocProvider<OnBoardingBloc>(create: (_) => sl<OnBoardingBloc>()),
        BlocProvider<ThemeBloc>(
          create: (_) => sl<ThemeBloc>()..add(LoadThemeEvent()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        buildWhen: (previous, current) => previous.themeMode != current.themeMode,
        builder: (context, themeState) {
          return MaterialApp(
            navigatorKey: NavigationService.navigatorKey,
            navigatorObservers: [
              _RouteLoggingObserver(),
            ],
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

class _RouteLoggingObserver extends NavigatorObserver {
  static const Map<String, String> _routeFilePaths = {
    AppRoutes.initial: 'lib/features/presentation/splash/splash_screen.dart',
    AppRoutes.signIn: 'lib/features/presentation/auth/login_screen.dart',
    AppRoutes.signup: 'lib/features/presentation/auth/signup_screen.dart',
    AppRoutes.weightScale: 'lib/features/presentation/auth/on_boarding/weight_scale_screen.dart',
    AppRoutes.heightScale: 'lib/features/presentation/auth/on_boarding/height_scale_screen.dart',
    AppRoutes.genderSelection: 'lib/features/presentation/auth/on_boarding/gender_selection_screen.dart',
    AppRoutes.userConfiguration: 'lib/features/presentation/configuration/configuration_screen.dart',
    AppRoutes.patientManagementScreen: 'lib/features/presentation/doctor/dashboard/patient_management_screen.dart',
    AppRoutes.favoritePatientsScreen: 'lib/features/presentation/doctor/dashboard/favorite_patients_screen.dart',
    AppRoutes.userPrescriptionManagement: 'lib/features/presentation/user_prescription/prescription_screen.dart',
    AppRoutes.userPrescriptionDetailScreen: 'lib/features/presentation/user_prescription/prescription_details_screen.dart',
    AppRoutes.languageSelectionScreen: 'lib/features/presentation/settings/language_setting_screen.dart',
    AppRoutes.appearanceScreen: 'lib/features/presentation/settings/appearance_screen.dart',
    AppRoutes.notificationSettingsScreen: 'lib/features/presentation/settings/notification_settings_screen.dart',
    AppRoutes.userTestResultScreen: 'lib/features/presentation/test_results/test_result_screen.dart',
    AppRoutes.addAppointmentScreen: 'lib/features/presentation/appointments/add_new_appointment_screen.dart',
    AppRoutes.appointmentDashboardScreen: 'lib/features/presentation/appointments/appointments_dashboard.dart',
    AppRoutes.selectRoleScreen: 'lib/features/presentation/auth/select_role_screen.dart',
    AppRoutes.workSpaceScreen: 'lib/features/presentation/auth/work_space/work_space_screen.dart',
    AppRoutes.doctorDashboard: 'lib/features/presentation/doctor/dashboard/doctor_dashboard_screen.dart',
    AppRoutes.settingsScreen: 'lib/features/presentation/settings/settings_screen.dart',
    AppRoutes.changePasswordScreen: 'lib/features/presentation/settings/change_password_screen.dart',
    AppRoutes.onSuccessChangePassword: 'lib/features/presentation/settings/password_changed_successfully.dart',
    AppRoutes.doctorPatientProfileScreen: 'lib/features/presentation/patient_profile/patient_profile_screen.dart',
    AppRoutes.addMedicalRecordScreen: 'lib/features/presentation/medicine/create_medicine_screen.dart',
    AppRoutes.medicalRecordDetailsScreen: 'lib/features/presentation/medicine/medical_details_screen.dart',
    AppRoutes.medicalHistoryScreen: 'lib/features/presentation/medicine/medical_record_list_screen.dart',
    AppRoutes.doctorPatientAppointmentListScreen: 'lib/features/presentation/doctor/patient_appoinment_list/patient_appoinment_list.dart',
    AppRoutes.uploadedRecordScreen: 'lib/features/presentation/upload_documnets/uploaded_records_screen.dart',
    AppRoutes.uploadRecordScreen: 'lib/features/presentation/upload_documnets/upload_records_screen.dart',
    AppRoutes.smartSlotSchedulerScreen: 'lib/features/presentation/slot/smart_scheduler_screen.dart',
    AppRoutes.singleSlotAppointmentDetails: 'lib/features/presentation/slot/slot_details_screen.dart',
    AppRoutes.slotDashboard: 'lib/features/presentation/slot/slot_dashboard_screen.dart',
    AppRoutes.addPrescriptionScreen: 'lib/features/presentation/prescriptions/add_prescription_screen.dart',
    AppRoutes.prescriptionListScreen: 'lib/features/presentation/prescriptions/prescription_list_screen.dart',
    AppRoutes.prescriptionViewDetailsScreen: 'lib/features/presentation/prescriptions/prescription_view_details_screen.dart',
    AppRoutes.closeAccountScreen: 'lib/features/presentation/close_account/close_account_screen.dart',
    AppRoutes.dashboardPatientDetails: 'lib/features/presentation/doctor/dashboard/dashboard_patient_details_screen.dart',
    AppRoutes.forgotPassword: 'lib/features/presentation/forgot_password/forgot_password_screen.dart',
    AppRoutes.permissionScreen: 'lib/features/presentation/permisions/permissions_screen.dart',
    AppRoutes.forceUpdateScreen: 'lib/features/presentation/configure_screens/force_update_screen.dart',
    AppRoutes.softUpdateScreen: 'lib/features/presentation/configure_screens/soft_update_screen.dart',
    AppRoutes.maintenanceScreen: 'lib/features/presentation/configure_screens/maintance_screen.dart',
    AppRoutes.sessionExpired: 'lib/core/session_expired/session_expired_scren.dart',
    AppRoutes.serverDown: 'lib/core/server_down/server_down_screen.dart',
    AppRoutes.unsupportedRole: 'lib/features/presentation/un_supported_role_screen/un_supported_role_screen.dart',
    AppRoutes.logOutScreen: 'lib/features/presentation/configure_screens/log_out_screen.dart',
    AppRoutes.patientDashboard: 'lib/features/presentation/patient/dashboard/patient_dashboard_screen.dart',
    AppRoutes.patientAppointments: 'lib/features/presentation/patient/appointments/patient_appointments_screen.dart',
    AppRoutes.patientDocuments: 'lib/features/presentation/patient/documents/patient_documents_screen.dart',
    AppRoutes.patientProfile: 'lib/features/presentation/patient/profile/patient_profile_passport_screen.dart',
  };

  String _getFilePath(String? routeName) {
    if (routeName == null) return 'Unknown / Anonymous Route';
    return _routeFilePaths[routeName] ?? 'No file path registered for route $routeName';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name;
    final filePath = _getFilePath(routeName);
    debugPrint("[ROUTE_NAVIGATED] Pushed Route: $routeName (args: ${route.settings.arguments}) | File: $filePath");
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final routeName = route.settings.name;
    final filePath = _getFilePath(routeName);
    debugPrint("[ROUTE_NAVIGATED] Popped Route: $routeName | File: $filePath");
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      final routeName = newRoute.settings.name;
      final filePath = _getFilePath(routeName);
      debugPrint("[ROUTE_NAVIGATED] Replaced Route to: $routeName | File: $filePath");
    }
  }
}