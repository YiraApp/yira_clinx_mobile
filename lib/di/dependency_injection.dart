import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/role_bloc/role_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/signin_bloc/signin_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/use_case/role_use_case.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_bloc/medical_record_bloc.dart';
import 'package:yiraclinics/features/presentation/settings/change_password_bloc/change_password_bloc.dart';
import 'package:yiraclinics/features/presentation/settings/setting_bloc/setting_bloc.dart';
import 'package:yiraclinics/features/presentation/test_results/test_result_bloc/test_result_bloc.dart';
import 'package:yiraclinics/features/use_cases/ge_prescription_use_case.dart';
// Core
import '../core/local/shared_preferences.dart';
// Medication Feature
import 'package:yiraclinics/features/domain/repositories/medication/medication_repository.dart';
import 'package:yiraclinics/features/data/repository_impl/medication/medication_repo_impl.dart';
// Other Features
import 'package:yiraclinics/features/presentation/configuration/config_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/dashboard_bloc/dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/on_boarding/on_boarding_bloc/on_boarding_bloc.dart';

import '../features/data/data_sources/theme_local_data_source.dart';
import '../features/data/repository_impl/app_theme/theme_repo_impl.dart';
import '../features/data/repository_impl/medicine/medical_histoy_repo_impl.dart';
import '../features/data/repository_impl/patient_profile_repo_impl/patient_profile_repo_impl.dart';
import '../features/data/repository_impl/prescriptions/prescriptions_repo_impl.dart';
import '../features/data/repository_impl/slot_impl/slot_scheduler_repo_impl.dart'; // Ensure this points to SlotRepositoryImpl
import '../features/data/repository_impl/slot_repo_impl/slot_repo_impl.dart';
import '../features/data/repository_impl/upload_record_repo_impl/upload_record_impl_repo.dart';
import '../features/domain/repositories/app_theme/theme_repos.dart';
import '../features/domain/repositories/medicine/medical_history_repo.dart';
import '../features/domain/repositories/patient_profile/patient_profile_repo.dart';
import '../features/domain/repositories/prescritpions/prescriptions_repo.dart';
import '../features/domain/repositories/slot/scheduler_repo.dart';
import '../features/domain/repositories/slot/slot_repo.dart'; // 🚀 UPDATED: Pointing to the new slot_repo interface
import '../features/domain/repositories/uploaded_record/uploaded_record_repo.dart';
import '../features/presentation/auth/work_space/work_space_bloc/work_space_bloc.dart';
import '../features/presentation/medicine/medical_history_bloc/medical_history_bloc.dart';
import '../features/presentation/patient_profile/patient_profile_bloc/patient_profile_bloc.dart';
import '../features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import '../features/presentation/slot/slot_bloc/slot_bloc.dart';
import '../features/presentation/theme/theme_bloc/theme_bloc.dart';
import '../features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import '../features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import '../features/use_cases/cached_theme_use_case.dart';
import '../features/use_cases/get_theme_use_case.dart';
import '../features/use_cases/medical_history_use_case.dart';
import '../features/use_cases/save_prescription_use_case.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => SharedPrefsService(sl<SharedPreferences>()));

  // ==========================================
  // 1. Repositories
  // ==========================================
  sl.registerLazySingleton<PatientRepository>(() => PatientRepositoryImpl());
  sl.registerLazySingleton<MedicationRepository>(() => MedicationRepositoryImpl());
  sl.registerLazySingleton<MedicalHistoryRepository>(() => MedicalHistoryRepositoryImpl());
  sl.registerLazySingleton<ThemeLocalDataSource>(() => ThemeLocalDataSourceImpl(sl<SharedPrefsService>()));
  sl.registerLazySingleton<ThemeRepository>(() => ThemeRepositoryImpl(sl<ThemeLocalDataSource>()));
  sl.registerLazySingleton<RecordsRepository>(() => RecordsRepositoryImpl());

  sl.registerLazySingleton<SlotRepository>(() => const SlotRepositoryImpl());
  sl.registerLazySingleton<SchedulerRepository>(() =>  SchedulerRepositoryImpl());
  sl.registerLazySingleton<PrescriptionRepository>(() => PrescriptionRepositoryImpl());
  // ==========================================
  // 2. Use Cases
  // ==========================================
  sl.registerLazySingleton(() => GetPrescriptionUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => GetThemeUseCase(sl<ThemeRepository>()));
  sl.registerLazySingleton(() => CacheThemeUseCase(sl<ThemeRepository>()));
  sl.registerLazySingleton(() => SelectRoleUseCase());
  sl.registerLazySingleton(() => GetMedicalRecordsUseCase(sl<MedicalHistoryRepository>()));
  sl.registerLazySingleton(() => SavePrescriptionUseCase(sl<PrescriptionRepository>()));
  // ==========================================
  // 3. Blocs
  // ==========================================
  sl.registerFactory(() => MedicationBloc(getMedicationSummary: sl<GetPrescriptionUseCase>()));
  sl.registerLazySingleton(() => SignInBloc());
  sl.registerLazySingleton(
        () => ThemeBloc(
      getThemeUseCase: sl<GetThemeUseCase>(),
      cacheThemeUseCase: sl<CacheThemeUseCase>(),
    ),
  );
  sl.registerLazySingleton(() => OnBoardingBloc());
  sl.registerLazySingleton(() => ConfigBloc());
  sl.registerLazySingleton(() => DashboardBloc());
  sl.registerLazySingleton(() => SettingsBloc());
  sl.registerLazySingleton(() => TestResultsBloc());
  sl.registerLazySingleton(() => WorkspaceBloc());
  sl.registerFactory(() => AppointmentBloc());
  sl.registerLazySingleton(() => ChangePasswordBloc());
  sl.registerLazySingleton(() => NavigationDrawerBloc());
  sl.registerLazySingleton(() => MedicalRecordBloc());
  sl.registerLazySingleton(() => PatientProfileBloc(repository: sl()));
  sl.registerFactory(
        () => MedicalHistoryBloc(
      getMedicalRecordsUseCase: sl<GetMedicalRecordsUseCase>(),
      repository: sl<MedicalHistoryRepository>(),
    ),
  );
  sl.registerFactory(() => UploadedBloc(repository: sl<RecordsRepository>()));
  sl.registerLazySingleton(() => RoleBloc(selectRoleUseCase: SelectRoleUseCase()));

  sl.registerLazySingleton(
        () => SlotBloc(
      schedulerRepository: sl<SchedulerRepository>(),
    ),
  );
  sl.registerFactory(
        () => PrescriptionBloc(
      savePrescriptionUseCase: sl<SavePrescriptionUseCase>(),
    ),
  );
}