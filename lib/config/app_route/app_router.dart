import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';
import 'package:yiraclinics/features/domain/entities/slot/slot_appointment_entity.dart';
import 'package:yiraclinics/features/presentation/appointments/add_new_appointment_screen.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/appointments/appointments_dashboard.dart';
import 'package:yiraclinics/features/presentation/auth/role_bloc/role_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/select_role_screen.dart';
import 'package:yiraclinics/features/presentation/auth/signin_bloc/signin_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/verify_otp_screen.dart';
import 'package:yiraclinics/features/presentation/auth/work_space/work_space_screen.dart';
import 'package:yiraclinics/features/presentation/close_account/close_account_bloc/close_account_bloc.dart';
import 'package:yiraclinics/features/presentation/close_account/close_account_screen.dart';
import 'package:yiraclinics/features/presentation/configuration/config_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_dashboard_bloc/dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/medicine/create_medicine_screen.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_details_screen.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_bloc/medical_record_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/patient_profile_bloc/patient_profile_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/patient_profile_screen.dart';
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
import '../../di/dependency_injection.dart';
import '../../features/presentation/auth/on_boarding/gender_selection_screen.dart';
import '../../features/presentation/auth/on_boarding/height_scale_screen.dart';
import '../../features/presentation/auth/on_boarding/on_boarding_bloc/on_boarding_bloc.dart';
import '../../features/presentation/auth/on_boarding/weight_scale_screen.dart';
import '../../features/presentation/auth/signin_screen.dart';
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
import '../../features/presentation/upload_documnets/uploaded_records_screen.dart';
import '../../features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import '../../features/presentation/user_prescription/prescription_details_screen.dart';
import '../../features/presentation/user_prescription/prescription_screen.dart';

class AppRouter {
  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.initial:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case AppRoutes.signIn:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<SignInBloc>(),
            child: SignInScreen(),
          ),
        );
      case AppRoutes.signup:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<SignInBloc>(),
            child: SignupScreen(),
          ),
        );
      case AppRoutes.weightScale:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<OnBoardingBloc>(),
            child: WeightScaleScreen(),
          ),
        );
      case AppRoutes.heightScale:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<OnBoardingBloc>(),
            child: HeightScaleScreen(),
          ),
        );
      case AppRoutes.genderSelection:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<OnBoardingBloc>(),
            child: GenderAgeSelectionScreen(),
          ),
        );
      case AppRoutes.userConfiguration:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<ConfigBloc>(),
            child: ConfigurationScreen(),
          ),
        );
      case AppRoutes.patientManagementScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<DashboardBloc>(),
            child: PatientManagementScreen(),
          ),
        );
      case AppRoutes.prescriptionScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<MedicationBloc>(),
            child: PrescriptionManagementScreen(),
          ),
        );
      case AppRoutes.prescriptionDetailScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<MedicationBloc>(),
            child: PrescriptionDetailScreen(prescriptionId: '1'),
          ),
        );
      case AppRoutes.languageSelectionScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<SettingsBloc>(),
            child: LanguageSettingsScreen(),
          ),
        );
      case AppRoutes.appearanceScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<SettingsBloc>(),
            child: AppearanceScreen(),
          ),
        );
      case AppRoutes.notificationSettingsScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<SettingsBloc>(),
            child: NotificationSettingsScreen(),
          ),
        );
      case AppRoutes.testResultScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<TestResultsBloc>(),
            child: TestResultsScreen(),
          ),
        );
      case AppRoutes.addAppointmentScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<AppointmentBloc>(),
            child: AddNewAppointmentScreen(),
          ),
        );
      case AppRoutes.appointmentDashboardScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<AppointmentBloc>(),
            child: AppointmentDashboardScreen(),
          ),
        );
      case AppRoutes.selectRoleScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<RoleBloc>(),
            child: SelectRoleScreen(),
          ),
        );
      case AppRoutes.workSpaceScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<WorkspaceBloc>(),
            child: WorkspaceScreen(),
          ),
        );
      case AppRoutes.docDashboard:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<NavigationDrawerBloc>(),
            child: DoctorDashboardScreen(),
          ),
        );
      case AppRoutes.settingsScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<SettingsBloc>(),
            child: SettingsScreen(),
          ),
        );
      case AppRoutes.verifyOtp:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<SignInBloc>(),
            child: VerifyOtpScreen(),
          ),
        );
      case AppRoutes.changePasswordScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<ChangePasswordBloc>(),
            child: ChangePasswordScreen(),
          ),
        );
      case AppRoutes.onSuccessChangePassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<ChangePasswordBloc>(),
            child: PasswordChangeSuccessScreen(),
          ),
        );
      case AppRoutes.doctorPatientProfileScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<PatientProfileBloc>(),
            child: DoctorPatientProfileScreen(),
          ),
        );
      case AppRoutes.addMedicalRecordScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<MedicalRecordBloc>(),
            child: CreateMedicalRecordScreen(),
          ),
        );
      case AppRoutes.medicalRecordDetailsScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<MedicalRecordBloc>(),
            child: MedicalRecordDetailsScreen(),
          ),
        );
      case AppRoutes.medicalHistoryScreen:
        return MaterialPageRoute(builder: (_) => MedicalRecordsListScreen());

      case AppRoutes.patientAppointmentListScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<AppointmentBloc>(),
            child: PatientAppointmentList(),
          ),
        );
      case AppRoutes.uploadedRecordScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<UploadedBloc>(),
            child: UploadedRecordsScreen(),
          ),
        );
      case AppRoutes.uploadRecordScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<UploadedBloc>(),
            child: UploadDocumentsScreen(patientName: 'Ch. Raja Vardan'),
          ),
        );
      case AppRoutes.smartSlotSchedulerScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<SlotBloc>(),
            child: SmartSchedulerScreen(),
          ),
        );
      case AppRoutes.singleSlotAppointmentDetails:
        return MaterialPageRoute(
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
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<SlotBloc>(),
            child: SlotDashBoardScreen(),
          ),
        );
      case AppRoutes.addPrescriptionScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<PrescriptionBloc>(),
            child: AddPrescriptionRecordScreen(),
          ),
        );
        case AppRoutes.prescriptionListScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<PrescriptionBloc>(),
            child: PrescriptionListScreen(),
          ),
        );
        case AppRoutes.prescriptionViewDetailsScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<PrescriptionBloc>(),
            child: PrescriptionViewDetailsScreen(),
          ),
        );
      case AppRoutes.closeAccountScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<CloseAccountBloc>(),
            child: CloseAccountScreen(),
          ),
        );
      //appointmentDetails
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('No route defined'))),
        );
    }
  }
}
