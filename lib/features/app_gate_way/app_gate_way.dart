import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/local/shared_preferences.dart';
import 'package:yiraclinics/core/constants/clinx_storage_keys.dart';

import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yiraclinics/features/presentation/auth/on_boarding/on_boarding_bloc/on_boarding_bloc.dart';
import 'package:yiraclinics/features/presentation/splash/auth_bloc/auth_bloc.dart';
import 'package:yiraclinics/features/presentation/theme/theme_bloc/theme_bloc.dart';

class AppGateway extends StatelessWidget {
  const AppGateway({super.key});

  static final DateTime _appGatewayBootTime = DateTime.now();
  static String? _lastHandledNotificationPayload;
  static DateTime? _lastHandledNotificationTime;

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
            title: projectTitle,
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

              return NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction != ScrollDirection.idle) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                  return false;
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: NotificationListenerWrapper(
                    onNotificationPayload: (payloadString) async {
                      try {
                        debugPrint("[AppGateway] Notification payload received: $payloadString");
                        final trimmed = payloadString.trim();
                        if (trimmed.isEmpty) return;

                        final prefs = sl.isRegistered<SharedPrefsService>() ? sl<SharedPrefsService>() : null;
                        final lastTimeMs = prefs?.getValue<int>('last_handled_notification_timestamp') ?? 0;
                        final lastPayload = prefs?.getValue<String>('last_handled_notification_payload') ?? '';
                        final nowMs = DateTime.now().millisecondsSinceEpoch;

                        if ((_lastHandledNotificationPayload == trimmed &&
                             _lastHandledNotificationTime != null &&
                             DateTime.now().difference(_lastHandledNotificationTime!) < const Duration(seconds: 30)) ||
                            (lastPayload == trimmed && (nowMs - lastTimeMs) < 30000)) {
                          debugPrint("[AppGateway] Skipping duplicate notification payload within 30s window.");
                          return;
                        }
                        _lastHandledNotificationPayload = trimmed;
                        _lastHandledNotificationTime = DateTime.now();
                        await prefs?.setValue<int>('last_handled_notification_timestamp', nowMs);
                        await prefs?.setValue<String>('last_handled_notification_payload', trimmed);

                        Map<String, dynamic> payload = {};
                        String? directUrl;

                        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
                          try {
                            final decoded = jsonDecode(trimmed);
                            if (decoded is Map<String, dynamic>) {
                              payload = decoded;
                            }
                          } catch (e) {
                            debugPrint("[AppGateway] Payload JSON decode error: $e");
                          }
                        } else if (trimmed.startsWith('http://') ||
                                   trimmed.startsWith('https://') ||
                                   trimmed.startsWith('www.')) {
                          directUrl = trimmed;
                        }

                        // Check for External Website URL configuration
                        String? externalUrl = directUrl;
                        final redirectionType = (payload['redirectionType'] ??
                                payload['redirection_type'] ??
                                payload['targetType'] ??
                                payload['action'] ??
                                payload['type'] ??
                                '')
                            .toString()
                            .trim()
                            .toLowerCase();

                        final bool isBrowserType = redirectionType == 'browser' ||
                            redirectionType == 'web' ||
                            redirectionType == 'external' ||
                            redirectionType == 'url' ||
                            redirectionType == 'open_url' ||
                            redirectionType == 'website' ||
                            redirectionType == 'external_link' ||
                            redirectionType.contains('external website') ||
                            redirectionType.contains('external web link');

                        if (externalUrl == null || externalUrl.isEmpty) {
                          final possibleUrlKeys = [
                            'url',
                            'redirectionUrl',
                            'redirection_url',
                            'externalUrl',
                            'external_url',
                            'webUrl',
                            'web_url',
                            'link',
                            'website',
                            'targetUrl',
                          ];

                          for (final key in possibleUrlKeys) {
                            final val = payload[key]?.toString().trim();
                            if (val != null && val.isNotEmpty) {
                              externalUrl = val;
                              break;
                            }
                          }

                          final routeCandidate = payload['route']?.toString().trim();
                          if (externalUrl == null || externalUrl.isEmpty) {
                            if (routeCandidate != null &&
                                (routeCandidate.startsWith('http://') ||
                                 routeCandidate.startsWith('https://') ||
                                 routeCandidate.startsWith('www.'))) {
                              externalUrl = routeCandidate;
                            } else if (isBrowserType &&
                                       routeCandidate != null &&
                                       !routeCandidate.startsWith('/') &&
                                       routeCandidate.contains('.')) {
                              externalUrl = routeCandidate;
                            }
                          }
                        }

                        // If an external URL is configured:
                        if (externalUrl != null && externalUrl.trim().isNotEmpty) {
                          // Never automatically dump the user into Chrome or external browser during app boot / startup
                          if (DateTime.now().difference(_appGatewayBootTime) < const Duration(seconds: 10)) {
                            debugPrint("[AppGateway] Suppressing external website redirect during app boot. Staying on Dashboard.");
                            return;
                          }

                          debugPrint("[AppGateway] External website URL detected: $externalUrl. Launching in-app viewer...");
                          String formattedUrl = externalUrl.trim();
                          if (!formattedUrl.startsWith('http://') &&
                              !formattedUrl.startsWith('https://') &&
                              !formattedUrl.contains('://')) {
                            formattedUrl = 'https://$formattedUrl';
                          }

                          final Uri? targetUri = Uri.tryParse(formattedUrl);
                          if (targetUri != null) {
                            bool opened = false;
                            try {
                              opened = await launchUrl(
                                targetUri,
                                mode: LaunchMode.inAppBrowserView,
                              );
                            } catch (e) {
                              debugPrint("[AppGateway] launchUrl inAppBrowserView error: $e");
                            }

                            if (!opened) {
                              try {
                                opened = await launchUrl(
                                  targetUri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                debugPrint("[AppGateway] launchUrl externalApplication error: $e");
                              }
                            }

                            if (!opened) {
                              try {
                                opened = await launchUrl(
                                  targetUri,
                                  mode: LaunchMode.platformDefault,
                                );
                              } catch (e) {
                                debugPrint("[AppGateway] launchUrl platformDefault error: $e");
                              }
                            }

                            if (!opened) {
                              await Utils.launchURL(formattedUrl);
                            }
                          } else {
                            await Utils.launchURL(formattedUrl);
                          }
                          return; // User requested external link; do NOT navigate to internal app routes
                        }

                        // In-app navigation: verify user session
                        final bool isLoggedIn = sl.isRegistered<SharedPrefsService>() &&
                            (sl<SharedPrefsService>().getValue<bool>(ClinxStorageKeys.isUserLoggedIn) ?? false);
                        final currentUser = GlobalSession.instance.userNotifier.value;
                        final bool hasValidUser = currentUser != null && (currentUser.data?.id ?? '').isNotEmpty;

                        if (!isLoggedIn || !hasValidUser) {
                          debugPrint("[AppGateway] Notification tapped but user is signed out. Redirecting strictly to signIn.");
                          NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                            AppRoutes.signIn,
                            (route) => false,
                          );
                          return;
                        }

                        final String? targetRoute = payload['route']?.toString().trim();
                        final String? itemId = payload['id']?.toString().trim();
                        final String? type = payload['type']?.toString().trim();

                        final typeUpper = (type ?? '').toUpperCase();
                        if (typeUpper == 'MEDICAL_RECORD_ADDED' ||
                            targetRoute == '/userTestResultScreen' ||
                            targetRoute == AppRoutes.userTestResultScreen ||
                            targetRoute == '/patientDocuments' ||
                            targetRoute == AppRoutes.patientDocuments) {
                          final navId = currentUser.data?.navigationId?.toString().trim();
                          final roleName = (currentUser.data?.latestUserRole ?? '').toLowerCase().trim();
                          final isDoctor = roleName.contains('doctor') || roleName.contains('provider') || navId == '2';
                          final isPatient = !isDoctor && (navId == '1' || roleName.contains('patient') || roleName == 'user');

                          if (isPatient) {
                            NavigationService.navigatorKey.currentState?.pushNamed(
                              AppRoutes.patientDocuments,
                            );
                          }
                          return;
                        }

                        if (typeUpper == 'MEDICATION_REMINDER' ||
                            targetRoute == '/prescriptions' ||
                            targetRoute == AppRoutes.prescriptionListScreen) {
                          NavigationService.navigatorKey.currentState?.pushNamed(
                            AppRoutes.prescriptionListScreen,
                          );
                          return;
                        }

                        final cleanRoute = (targetRoute ?? '').toLowerCase().replaceAll('/', '').replaceAll('_', '').trim();
                        if (cleanRoute == 'patientbookappointment' ||
                            cleanRoute == 'bookappointment' ||
                            cleanRoute == 'patientselecthospitalscreen' ||
                            targetRoute == AppRoutes.patientBookAppointment) {
                          NavigationService.navigatorKey.currentState?.pushNamed(
                            AppRoutes.patientBookAppointment,
                          );
                          return;
                        }

                        if (targetRoute != null && targetRoute.isNotEmpty && targetRoute.startsWith('/')) {
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
                  ),
                ),
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
    AppRoutes.doctorPatientDetailProfileScreen: 'lib/features/presentation/patient_profile/doctor_patient_detail_profile_screen.dart',
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
    AppRoutes.patientMyDoctors: 'lib/features/presentation/patient/doctors/patient_my_doctors_screen.dart',
    AppRoutes.patientVitalsTracking: 'lib/features/presentation/patient/vitals/patient_vitals_tracking_screen.dart',
    AppRoutes.patientMyFamily: 'lib/features/presentation/patient/family/patient_my_family_screen.dart',
    AppRoutes.patientBookAppointment: 'lib/features/presentation/patient/appointments/patient_select_hospital_screen.dart',
    AppRoutes.patientSelectHospitalScreen: 'lib/features/presentation/patient/appointments/patient_select_hospital_screen.dart',
    AppRoutes.patientHospitalDoctorsScreen: 'lib/features/presentation/patient/appointments/patient_hospital_doctors_screen.dart',
    AppRoutes.patientDoctorSuggestions: 'lib/features/presentation/patient/suggestions/patient_doctor_suggestions_screen.dart',
  };

  String _getFilePath(String? routeName) {
    if (routeName == null) return 'Unknown / Anonymous Route';
    return _routeFilePaths[routeName] ?? 'No file path registered for route $routeName';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name;
    NavigationService.currentRoute = routeName;
    final filePath = _getFilePath(routeName);
    debugPrint("[ROUTE_NAVIGATED] Pushed Route: $routeName (args: ${route.settings.arguments}) | File: $filePath");
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final routeName = route.settings.name;
    if (previousRoute != null) {
      NavigationService.currentRoute = previousRoute.settings.name;
    }
    final filePath = _getFilePath(routeName);
    debugPrint("[ROUTE_NAVIGATED] Popped Route: $routeName | File: $filePath");
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      final routeName = newRoute.settings.name;
      NavigationService.currentRoute = routeName;
      final filePath = _getFilePath(routeName);
      debugPrint("[ROUTE_NAVIGATED] Replaced Route to: $routeName | File: $filePath");
    }
  }
}