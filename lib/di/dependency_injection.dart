import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core & Services Imports
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/flutter_secure_storage.dart';
import 'package:yiraclinics/core/local/shared_preferences.dart';
import 'package:yiraclinics/core/services/network_services/data/network_repo_impl/network_repo_impl.dart';
import 'package:yiraclinics/core/services/network_services/domain/neetwork_repo/network_repo.dart';
import 'package:yiraclinics/core/services/network_services/network_bloc/network_bloc.dart';
import 'package:yiraclinics/core/services/network_services/network_remote_data_source/network_remote_data_source.dart';
import 'package:yiraclinics/core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';

// Data Sources & Repositories Imports
import 'package:yiraclinics/features/data/data_sources/theme_local_data_source.dart';
import 'package:yiraclinics/features/data/repository_impl/auth/auth_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/fcm_token/update_fcm_token_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/login/login_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/app_theme/theme_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/medicine/medical_histoy_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/patient_profile_repo_impl/patient_profile_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/prescriptions/prescriptions_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/send_otp_repo/send_otp_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/slot_impl/slot_scheduler_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/slot_repo_impl/slot_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/token/get_version_and_token_status_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/upload_record_repo_impl/upload_record_impl_repo.dart';
import 'package:yiraclinics/features/data/repository_impl/medication/medication_repo_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/work_space/get_work_space_details_impl.dart';
import 'package:yiraclinics/features/data/repository_impl/work_space/update_latest_org_details_repo_impl.dart';

// Domain Layer (Repositories & Entities) Imports
import 'package:yiraclinics/features/domain/repositories/app_theme/theme_repos.dart';
import 'package:yiraclinics/features/domain/repositories/auth/auth_repo.dart';
import 'package:yiraclinics/features/domain/repositories/configuration/configuration_repo.dart';
import 'package:yiraclinics/features/domain/repositories/fcm_token/update_fcm_token_repo.dart';
import 'package:yiraclinics/features/domain/repositories/foget_password/forget_password_send_otp_repo.dart';
import 'package:yiraclinics/features/domain/repositories/foget_password/save_reset_password_repo.dart';
import 'package:yiraclinics/features/domain/repositories/login/login_repo.dart';
import 'package:yiraclinics/features/domain/repositories/medicine/medical_history_repo.dart';
import 'package:yiraclinics/features/domain/repositories/patient_profile/patient_profile_repo.dart';
import 'package:yiraclinics/features/domain/repositories/prescritpions/prescriptions_repo.dart';
import 'package:yiraclinics/features/domain/repositories/send_otp/send_otp_repo.dart';
import 'package:yiraclinics/features/domain/repositories/slot/scheduler_repo.dart';
import 'package:yiraclinics/features/domain/repositories/slot/slot_repo.dart';
import 'package:yiraclinics/features/domain/repositories/token/get_version_and_token_status_repo.dart';
import 'package:yiraclinics/features/domain/repositories/uploaded_record/uploaded_record_repo.dart';
import 'package:yiraclinics/features/domain/repositories/medication/medication_repository.dart';
import 'package:yiraclinics/features/domain/repositories/work_space/get_work_space_details_repo.dart';
import 'package:yiraclinics/features/domain/repositories/work_space/update_latest_org_details_repo.dart';
import 'package:yiraclinics/features/presentation/splash/auth_bloc/auth_bloc.dart';
import 'package:yiraclinics/features/use_cases/auth_use_case.dart';

// Use Cases Imports
import 'package:yiraclinics/features/use_cases/cached_theme_use_case.dart';
import 'package:yiraclinics/features/use_cases/config_use_case.dart';
import 'package:yiraclinics/features/use_cases/forget_password_send_otp_use_case.dart';
import 'package:yiraclinics/features/use_cases/get_theme_use_case.dart';
import 'package:yiraclinics/features/use_cases/get_work_space_details_use_case.dart';
import 'package:yiraclinics/features/use_cases/login_email_use_case.dart';
import 'package:yiraclinics/features/use_cases/medical_history_use_case.dart';
import 'package:yiraclinics/features/use_cases/save_prescription_use_case.dart';
import 'package:yiraclinics/features/use_cases/ge_prescription_use_case.dart';
import 'package:yiraclinics/features/use_cases/login_mobile_use_case.dart';
import 'package:yiraclinics/features/presentation/auth/use_case/role_use_case.dart';

// Blocs & Presentation Imports
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/role_bloc/role_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';
import 'package:yiraclinics/features/presentation/close_account/close_account_bloc/close_account_bloc.dart';
import 'package:yiraclinics/features/presentation/forgot_password/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_bloc/medical_record_bloc.dart';
import 'package:yiraclinics/features/presentation/settings/change_password_bloc/change_password_bloc.dart';
import 'package:yiraclinics/features/presentation/settings/setting_bloc/setting_bloc.dart';
import 'package:yiraclinics/features/presentation/test_results/test_result_bloc/test_result_bloc.dart';
import 'package:yiraclinics/features/presentation/configuration/config_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_dashboard_bloc/dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/on_boarding/on_boarding_bloc/on_boarding_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/work_space/work_space_bloc/work_space_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/doctor_dashboard_bloc/doctor_dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_history_bloc/medical_history_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/patient_profile_bloc/patient_profile_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/slot/slot_bloc/slot_bloc.dart';
import 'package:yiraclinics/features/presentation/theme/theme_bloc/theme_bloc.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart'
    as user_presc;
import 'package:yiraclinics/features/use_cases/save_reset_password_use_case.dart';
import 'package:yiraclinics/features/use_cases/send_otp_use_case.dart';
import 'package:yiraclinics/features/use_cases/update_fcm_token_use_case.dart';
import 'package:yiraclinics/features/use_cases/update_latest_org_details_use_case.dart';

import '../core/local/global_session.dart';
import '../core/package/data/platform_info_impl.dart';
import '../core/package/domain/plat_form_info_repo.dart';
import '../core/use_cases/get_plat_form_info_usecase.dart';
import '../features/data/repository_impl/configuration/configuration_repo_impl.dart';
import '../features/data/repository_impl/forget_password/forget_password_send_otp_repo_impl.dart';
import '../features/data/repository_impl/forget_password/forget_password_verify_otp_repo_impl.dart';
import '../features/data/repository_impl/forget_password/save_reset_password_repo_impl.dart';
import '../features/domain/repositories/foget_password/forget_password_verify_otp_repo.dart';
import '../features/use_cases/forget_password_verify_otp_use_case.dart';
import '../features/use_cases/get_version_and_token_status_use_case.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final apiClient = ApiClient();

  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => InternetConnection());
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => apiClient);
  sl.registerLazySingleton(() => SharedPrefsService(sl<SharedPreferences>()));
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  final globalSession = GlobalSession.instance;
  await globalSession.initialize(sl<SecureStorageService>());
  sl.registerSingleton<GlobalSession>(globalSession);
  // ==========================================
  // 1. Data Sources & Repositories
  // ==========================================
  sl.registerLazySingleton<ThemeLocalDataSource>(
    () => ThemeLocalDataSourceImpl(sl<SharedPrefsService>()),
  );
  sl.registerLazySingleton<ThemeRepository>(
    () => ThemeRepositoryImpl(sl<ThemeLocalDataSource>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<SharedPrefsService>(),
      sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<NetworkRemoteDataSource>(
    () => NetworkRemoteDataSourceImpl(sl<InternetConnection>()),
  );
  sl.registerLazySingleton<NetworkRepository>(
    () =>
        NetworkRepositoryImpl(remoteDataSource: sl<NetworkRemoteDataSource>()),
  );
  sl.registerLazySingleton<PlatformInfoRepo>(
    () => const PlatformInfoRepoImpl(),
  );
  sl.registerLazySingleton<LoginRepository>(
    () => LoginRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<PatientRepository>(() => PatientRepositoryImpl());
  sl.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(),
  );
  sl.registerLazySingleton<MedicalHistoryRepository>(
    () => MedicalHistoryRepositoryImpl(),
  );

  sl.registerLazySingleton<RecordsRepository>(() => RecordsRepositoryImpl());
  sl.registerLazySingleton<SlotRepository>(() => const SlotRepositoryImpl());
  sl.registerLazySingleton<SchedulerRepository>(
    () => SchedulerRepositoryImpl(),
  );
  sl.registerLazySingleton<PrescriptionRepository>(
    () => PrescriptionRepositoryImpl(),
  );
  sl.registerLazySingleton<SendOtpRepo>(
    () => SendOtpRepositoryImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<GetWorkSpaceDetailsRepo>(
    () => GetWorkSpaceDetailsImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<ConfigurationRepo>(
    () => ConfigurationRepoImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<UpdateFcmRepository>(
    () => UpdateFcmRepoImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<UpdateLatestOrgDetailsRepo>(
    () => UpdateLatestOrgDetailsRepoImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<GetVersionAndTokenStatusRepo>(
    () => GetVersionAndTokenStatusRepoImpl(sl<ApiClient>()),
  );


  sl.registerLazySingleton<ForgetPasswordSendOtpRepo>(
        () => ForgetPasswordSendOtpRepoImpl(sl<ApiClient>()),
  );


  sl.registerLazySingleton<ForgetPasswordVerifyOtpRepo>(
        () => ForgetPasswordVerifyOtpRepoImpl(sl<ApiClient>()),
  );



  sl.registerLazySingleton<SaveResetPasswordRepo>(
        () => SaveResetPasswordRepoImpl(sl<ApiClient>()),
  );
  // ==========================================
  // 2. Use Cases
  // ==========================================
  sl.registerLazySingleton<AuthUseCase>(
    () => AuthUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetPlatformInfoUseCase>(
    () => GetPlatformInfoUseCase(sl<PlatformInfoRepo>()),
  );
  sl.registerLazySingleton(
    () => GetPrescriptionUseCase(sl<MedicationRepository>()),
  );
  sl.registerLazySingleton(() => GetThemeUseCase(sl<ThemeRepository>()));
  sl.registerLazySingleton(() => CacheThemeUseCase(sl<ThemeRepository>()));
  sl.registerLazySingleton(() => SelectRoleUseCase());
  sl.registerLazySingleton(
    () => GetMedicalRecordsUseCase(sl<MedicalHistoryRepository>()),
  );
  sl.registerLazySingleton(
    () => SavePrescriptionUseCase(sl<PrescriptionRepository>()),
  );
  sl.registerLazySingleton(
    () => LoginMobileUseCase(repository: sl<LoginRepository>()),
  );
  sl.registerLazySingleton(
    () => LoginEmailUseCase(repository: sl<LoginRepository>()),
  );
  sl.registerLazySingleton(() => SendOtpUseCase(repository: sl<SendOtpRepo>()));
  sl.registerLazySingleton(
    () => GetWorkSpaceDetailsUseCase(sl<GetWorkSpaceDetailsRepo>()),
  );
  sl.registerLazySingleton<ConfigUseCase>(
    () => ConfigUseCase(repository: sl<ConfigurationRepo>()),
  );
  sl.registerLazySingleton<UpdateFcmTokenUseCase>(
    () => UpdateFcmTokenUseCase(repository: sl<UpdateFcmRepository>()),
  );
  sl.registerLazySingleton<UpdateLatestOrgDetailsUseCase>(
    () => UpdateLatestOrgDetailsUseCase(sl<UpdateLatestOrgDetailsRepo>()),
  );
  sl.registerLazySingleton<GetVersionAndTokenStatusUseCase>(
    () => GetVersionAndTokenStatusUseCase(
      repository: sl<GetVersionAndTokenStatusRepo>(),
    ),
  );

  sl.registerLazySingleton<ForgetPasswordSendOtpUseCase>(
    () => ForgetPasswordSendOtpUseCase(
       sl<ForgetPasswordSendOtpRepo>(),
    ),
  );
  sl.registerLazySingleton<ForgetPasswordVerifyOtpUseCase>(
        () => ForgetPasswordVerifyOtpUseCase(
      sl<ForgetPasswordVerifyOtpRepo>(),
    ),
  );

  sl.registerLazySingleton<SaveResetPasswordUseCase>(
        () => SaveResetPasswordUseCase(
      sl<SaveResetPasswordRepo>(),
    ),
  );


  // ==========================================
  // 3. Blocs / Cubits
  // ==========================================
  sl.registerLazySingleton(
    () => ThemeBloc(
      getThemeUseCase: sl<GetThemeUseCase>(),
      cacheThemeUseCase: sl<CacheThemeUseCase>(),
    ),
  );
  sl.registerLazySingleton(
    () => NetworkBloc( networkRepository: sl<NetworkRepository>(),),
  );
  sl.registerLazySingleton(() => AuthBloc(sl<AuthUseCase>()));
  sl.registerFactory(
    () => user_presc.MedicationBloc(
      getMedicationSummary: sl<GetPrescriptionUseCase>(),
    ),
  );
  sl.registerLazySingleton(
    () => LoginBloc(
      loginMobileUseCase: sl<LoginMobileUseCase>(),
      loginEmailUseCase: sl<LoginEmailUseCase>(),
      sharedPrefsService: sl<SharedPrefsService>(),
      sendOtpUseCase: sl<SendOtpUseCase>(),
      updateFcmTokenUseCase: sl<UpdateFcmTokenUseCase>(),
    ),
  );

  sl.registerLazySingleton(() => OnBoardingBloc());
  sl.registerLazySingleton(
    () => ConfigBloc(
      configUseCase: sl<ConfigUseCase>(),
      getVersionAndTokenStatusUseCase: sl<GetVersionAndTokenStatusUseCase>(),
    ),
  );
  sl.registerLazySingleton(() => DashboardBloc());
  sl.registerLazySingleton(() => SettingsBloc());
  sl.registerLazySingleton(() => TestResultsBloc());
  sl.registerLazySingleton(
    () => WorkspaceBloc(
      getWorkSpaceDetailsUseCase: sl<GetWorkSpaceDetailsUseCase>(),
      updateLatestOrgDetailsUseCase: sl<UpdateLatestOrgDetailsUseCase>(),
    ),
  );
  sl.registerFactory(() => AppointmentBloc());
  sl.registerLazySingleton(() => ChangePasswordBloc());
  sl.registerLazySingleton<NavigationDrawerBloc>(
    () => NavigationDrawerBloc(sl<SecureStorageService>()),
  );
  sl.registerLazySingleton(() => MedicalRecordBloc());
  sl.registerFactory(() => DoctorDashboardBloc());
  sl.registerLazySingleton(() => PatientProfileBloc(repository: sl()));
  sl.registerFactory(
    () => MedicalHistoryBloc(
      getMedicalRecordsUseCase: sl<GetMedicalRecordsUseCase>(),
      repository: sl<MedicalHistoryRepository>(),
    ),
  );
  sl.registerFactory(() => UploadedBloc(repository: sl<RecordsRepository>()));
  sl.registerLazySingleton(
    () => RoleBloc(selectRoleUseCase: sl<SelectRoleUseCase>()),
  );
  sl.registerLazySingleton(() => CloseAccountBloc());
  sl.registerLazySingleton(
    () => ForgotPasswordBloc(
      forgetPasswordSendOtpUseCase: sl<ForgetPasswordSendOtpUseCase>(),
      forgetPasswordVerifyOtpUseCase: sl<ForgetPasswordVerifyOtpUseCase>(),
      saveResetPasswordUseCase: sl<SaveResetPasswordUseCase>(),
    ),
  );
  sl.registerLazySingleton(
    () => SlotBloc(schedulerRepository: sl<SchedulerRepository>()),
  );
  sl.registerFactory(
    () => PrescriptionBloc(
      savePrescriptionUseCase: sl<SavePrescriptionUseCase>(),
    ),
  );
}
