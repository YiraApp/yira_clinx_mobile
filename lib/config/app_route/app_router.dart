import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';
import 'package:yiraclinics/core/server_down/server_down_screen.dart';
import 'package:yiraclinics/core/session_expired/session_expired_scren.dart';
import 'package:yiraclinics/features/domain/entities/medicine/medical_history_entity.dart';
import 'package:yiraclinics/features/domain/entities/send_otp/send_otp_entity.dart';
import 'package:yiraclinics/features/domain/entities/slot/slot_appointment_entity.dart';
import 'package:yiraclinics/features/presentation/appointments/add_new_appointment_screen.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/appointments/appointments_dashboard.dart';
import 'package:yiraclinics/features/presentation/auth/role_bloc/role_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/select_role_screen.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/verify_otp_screen.dart';
import 'package:yiraclinics/features/presentation/auth/work_space/work_space_screen.dart';
import 'package:yiraclinics/features/presentation/close_account/close_account_bloc/close_account_bloc.dart';
import 'package:yiraclinics/features/presentation/close_account/close_account_screen.dart';
import 'package:yiraclinics/features/presentation/configuration/config_bloc.dart';
import 'package:yiraclinics/features/presentation/configure_screens/force_update_screen.dart';
import 'package:yiraclinics/features/presentation/configure_screens/log_out_screen.dart';
import 'package:yiraclinics/features/presentation/configure_screens/maintance_screen.dart';
import 'package:yiraclinics/features/presentation/configure_screens/soft_update_screen.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/dashboard_patient_details_screen.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/doctor_dashboard_bloc/doctor_dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_dashboard_bloc/dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_deatils_bloc/patient_details_bloc.dart';
import 'package:yiraclinics/features/presentation/forgot_password/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:yiraclinics/features/presentation/forgot_password/forgot_password_screen.dart';
import 'package:yiraclinics/features/presentation/medicine/create_medicine_screen.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_details_screen.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_history_bloc/medical_history_bloc.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_bloc/medical_record_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/patient_profile_bloc/patient_profile_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/patient_profile_screen.dart';
import 'package:yiraclinics/features/presentation/permisions/permission_bloc/permission_bloc.dart';
import 'package:yiraclinics/features/presentation/permisions/permissions_screen.dart';
import 'package:yiraclinics/features/presentation/prescriptions/add_prescription_screen.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_list_screen.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_view_details_screen.dart';
import 'package:yiraclinics/features/presentation/settings/appearance_screen.dart';
import 'package:yiraclinics/features/presentation/settings/change_password_bloc/change_password_bloc.dart';
import 'package:yiraclinics/features/presentation/settings/change_password_screen.dart';
import 'package:yiraclinics/features/presentation/settings/password_changed_successfully.dart';
import 'package:yiraclinics/features/presentation/settings/setting_bloc/setting_bloc.dart';
import 'package:yiraclinics/features/presentation/settings/settings_screen.dart';
import 'package:yiraclinics/features/presentation/slot/slot_bloc/slot_bloc.dart';
import 'package:yiraclinics/features/presentation/slot/smart_scheduler_screen.dart';
import 'package:yiraclinics/features/presentation/test_results/test_result_bloc/test_result_bloc.dart';
import 'package:yiraclinics/features/presentation/test_results/test_result_screen.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/upload_records_screen.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import '../../core/models/select_role_model.dart';
import '../../core/models/work_space_model.dart';
import '../../di/dependency_injection.dart';
import '../../features/domain/entities/login/login_entity.dart';
import '../../features/domain/entities/token/get_version_and_token_status_entity.dart';
import '../../features/presentation/auth/on_boarding/gender_selection_screen.dart';
import '../../features/presentation/auth/on_boarding/height_scale_screen.dart';
import '../../features/presentation/auth/on_boarding/on_boarding_bloc/on_boarding_bloc.dart';
import '../../features/presentation/auth/on_boarding/weight_scale_screen.dart';
import '../../features/presentation/auth/login_screen.dart';
import '../../features/presentation/auth/signup_screen.dart';
import '../../features/presentation/auth/work_space/work_space_bloc/work_space_bloc.dart';
import '../../features/presentation/configuration/configuration_screen.dart';
import '../../features/presentation/doctor/dashboard/doctor_dashboard_screen.dart';
import '../../features/presentation/doctor/dashboard/patient_management_screen.dart';
import '../../features/presentation/doctor/patient_appoinment_list/patient_appoinment_list.dart';
import '../../features/presentation/medicine/medical_record_list_screen.dart';
import '../../features/presentation/settings/language_setting_screen.dart';
import '../../features/presentation/settings/notification_settings_screen.dart';
import '../../features/presentation/slot/slot_dashboard_screen.dart';
import '../../features/presentation/slot/slot_details_screen.dart';
import '../../features/presentation/splash/splash_screen.dart';
import '../../features/presentation/un_supported_role_screen/un_supported_role_screen.dart';
import '../../features/presentation/upload_documnets/uploaded_records_screen.dart';
import '../../features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import '../../features/presentation/user_prescription/prescription_details_screen.dart';
import '../../features/presentation/user_prescription/prescription_screen.dart';

class AppRouter {
  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.initial:
        return MaterialPageRoute(settings: settings, builder: (_) => SplashScreen());
      case AppRoutes.signIn:
        return MaterialPageRoute(settings: settings, 
          builder: (_) =>
              BlocProvider.value(value: sl<LoginBloc>(), child: LoginScreen()),
        );
      case AppRoutes.signup:
        return MaterialPageRoute(settings: settings, 
          builder: (_) =>
              BlocProvider.value(value: sl<LoginBloc>(), child: SignupScreen()),
        );
      case AppRoutes.weightScale:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<OnBoardingBloc>(),
            child: WeightScaleScreen(),
          ),
        );
      case AppRoutes.heightScale:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<OnBoardingBloc>(),
            child: HeightScaleScreen(),
          ),
        );
      case AppRoutes.genderSelection:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<OnBoardingBloc>(),
            child: GenderAgeSelectionScreen(),
          ),
        );
      case AppRoutes.userConfiguration:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<ConfigBloc>(),
            child: UserConfigurationScreen(),
          ),
        );
      case AppRoutes.patientManagementScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<DashboardBloc>(),
            child: PatientManagementScreen(),
          ),
        );
      case AppRoutes.userPrescriptionManagement:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<MedicationBloc>(),
            child: PrescriptionManagementScreen(),
          ),
        );
      case AppRoutes.userPrescriptionDetailScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<MedicationBloc>(),
            child: PrescriptionDetailScreen(prescriptionId: '1'),
          ),
        );
      case AppRoutes.languageSelectionScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<SettingsBloc>(),
            child: LanguageSettingsScreen(),
          ),
        );
      case AppRoutes.appearanceScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<SettingsBloc>(),
            child: AppearanceScreen(),
          ),
        );
      case AppRoutes.notificationSettingsScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<SettingsBloc>(),
            child: NotificationSettingsScreen(),
          ),
        );
      case AppRoutes.userTestResultScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<TestResultsBloc>(),
            child: TestResultsScreen(),
          ),
        );
      case AppRoutes.addAppointmentScreen:
        final appointmentArgs = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<AppointmentBloc>(),
            child: AddNewAppointmentScreen(
              initialPatientName: appointmentArgs?['patientName'],
              initialPatientPhone: appointmentArgs?['patientPhone'],
            ),
          ),
        );
      case AppRoutes.appointmentDashboardScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<AppointmentBloc>(),
            child: AppointmentDashboardScreen(),
          ),
        );
      case AppRoutes.selectRoleScreen:
        final args = settings.arguments as SelectRoleModel;
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<RoleBloc>(),
            child: SelectRoleScreen(roles: args),
          ),
        );
      case AppRoutes.workSpaceScreen:
        WorkSpaceModel workSpaceModel = settings.arguments as WorkSpaceModel;
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<WorkspaceBloc>(),
            child: WorkspaceScreen(roleEntity: workSpaceModel,),
          ),
        );
      case AppRoutes.doctorDashboard:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<NavigationDrawerBloc>.value(
                value: sl<NavigationDrawerBloc>(),
              ),
              BlocProvider<DoctorDashboardBloc>.value(
                value: sl<DoctorDashboardBloc>(),
              ),
            ],
            child: const DoctorDashboardScreen(),
          ),
        );
      case AppRoutes.settingsScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<SettingsBloc>(),
            child: SettingsScreen(),
          ),
        );
      case AppRoutes.verifyOtp:
        final SendOtpEntity sendOtpData = settings.arguments as SendOtpEntity;
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<LoginBloc>(),
            child: VerifyOtpScreen(sendOtpEntity: sendOtpData,),
          ),
        );
      case AppRoutes.changePasswordScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<ChangePasswordBloc>(),
            child: ChangePasswordScreen(),
          ),
        );
      case AppRoutes.onSuccessChangePassword:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<ChangePasswordBloc>(),
            child: PasswordChangeSuccessScreen(),
          ),
        );
      case AppRoutes.doctorPatientProfileScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<PatientProfileBloc>(),
            child: DoctorPatientProfileScreen(
              patientId: args?['patientId'] as String?,
              appointmentId: args?['appointmentId'] as String?,
              hospitalId: args?['hospitalId'] as String?,
              orgId: args?['orgId'] as String?,
              patientName: args?['patientName'] as String?,
              initialTabIndex: args?['initialTabIndex'] as int? ?? 0,
            ),
          ),
        );
      case AppRoutes.addMedicalRecordScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<MedicalRecordBloc>(),
            child: CreateMedicalRecordScreen(),
          ),
        );
      case AppRoutes.medicalRecordDetailsScreen:
        final record = settings.arguments as MedicalRecordBriefEntity?;
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<MedicalRecordBloc>(),
            child: MedicalRecordDetailsScreen(record: record),
          ),
        );
      case AppRoutes.medicalHistoryScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<MedicalHistoryBloc>(),
            child: MedicalRecordsListScreen(),
          ),
        );

      case AppRoutes.doctorPatientAppointmentListScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<AppointmentBloc>(),
            child: PatientAppointmentList(),
          ),
        );
      case AppRoutes.uploadedRecordScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<UploadedBloc>(),
            child: UploadedRecordsScreen(),
          ),
        );
      case AppRoutes.uploadRecordScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<UploadedBloc>(),
            child: UploadDocumentsScreen(patientName: 'Ch. Raja Vardan'),
          ),
        );
      case AppRoutes.smartSlotSchedulerScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<SlotBloc>(),
            child: SmartSchedulerScreen(),
          ),
        );
      case AppRoutes.singleSlotAppointmentDetails:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<SlotBloc>(),
            child: SlotDetailsDialog(
              slot: SlotEntity(
                id: '1',
                startTime: '09:30 Am',
                endTime: '10:30 Am',
                label: "Booked",
              ),
            ),
          ),
        );
      case AppRoutes.slotDashboard:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<SlotBloc>(),
            child: SlotDashBoardScreen(),
          ),
        );
      case AppRoutes.addPrescriptionScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<PrescriptionBloc>(),
            child: AddPrescriptionRecordScreen(),
          ),
        );
      case AppRoutes.prescriptionListScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<PrescriptionBloc>(),
            child: PrescriptionListScreen(),
          ),
        );
      case AppRoutes.prescriptionViewDetailsScreen:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<PrescriptionBloc>(),
            child: PrescriptionViewDetailsScreen(
              patientId: args['patientId'] as String?,
              appointmentId: args['appointmentId'] as String?,
              hospitalId: args['hospitalId'] as String?,
              orgId: args['orgId'] as String?,
            ),
          ),
        );
      case AppRoutes.closeAccountScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<CloseAccountBloc>(),
            child: CloseAccountScreen(),
          ),
        );
      case AppRoutes.dashboardPatientDetails:
        final DashboardPatientDetails dashboardPatientDetails = settings.arguments as DashboardPatientDetails;

        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<PatientDetailsBloc>(),
            child: DashboardPatientDetailsScreen(dashboardPatientDetails: dashboardPatientDetails,),

          ),
        );
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<ForgotPasswordBloc>(),
            child: ForgotPasswordScreen(),
          ),
        );
        case AppRoutes.permissionScreen:
        return MaterialPageRoute(settings: settings, 
          builder: (_) => BlocProvider.value(
            value: sl<PermissionsBloc>(),
            child: PermissionsScreen(),
          ),
        );
      case AppRoutes.forceUpdateScreen:
        final GetVersionTokenStatusEntity getVersionTokenStatusData = settings.arguments as GetVersionTokenStatusEntity;
        return MaterialPageRoute(settings: settings, builder: (_) => ForceUpdateView(getVersionTokenStatusEntity: getVersionTokenStatusData,));
      case AppRoutes.softUpdateScreen:
        final GetVersionTokenStatusEntity getVersionTokenStatusData = settings.arguments as GetVersionTokenStatusEntity;
        return MaterialPageRoute(settings: settings, builder: (_) => SoftUpdateView(getVersionTokenStatusEntity: getVersionTokenStatusData,));
      case AppRoutes.maintenanceScreen:
        return MaterialPageRoute(settings: settings, builder: (_) => MaintenanceView());
      case AppRoutes.sessionExpired:
        return MaterialPageRoute(settings: settings, builder: (_) => SessionExpiredScreen());
      case AppRoutes.serverDown:
        return MaterialPageRoute(settings: settings, builder: (_) => ServerDownScreen());
      case AppRoutes.unsupportedRole:
        final LoginEntity loginData = settings.arguments as LoginEntity;
        return MaterialPageRoute(settings: settings, 
          builder: (context) => UnsupportedRoleScreen(loginEntity: loginData),
        );
      case AppRoutes.logOutScreen:
        return MaterialPageRoute(settings: settings, builder: (_) => LogoutScreen());
      //appointmentDetails
      default:
        return MaterialPageRoute(settings: settings, 
          builder: (_) =>
              const Scaffold(body: Center(child: Text('No route defined'))),
        );
    }
  }
}
