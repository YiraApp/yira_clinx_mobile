import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';

import '../../../../../core/local/flutter_secure_storage.dart';
import '../../../../../core/use_cases/package_use_case.dart';
import '../../../../domain/entities/appointments/appointment_entity.dart';

part 'doctor_dashboard_event.dart';
part 'doctor_dashboard_state.dart';

class DoctorDashboardBloc
    extends Bloc<DoctorDashboardEvent, DoctorDashboardState> {
  final GetAppVersionInfoUseCase _getAppVersionInfoUseCase;
  final SecureStorageService _secureStorageService;
  DoctorDashboardBloc({required GetAppVersionInfoUseCase getAppVersionInfoUseCase, required SecureStorageService secureStorageService}) : _getAppVersionInfoUseCase = getAppVersionInfoUseCase, _secureStorageService = secureStorageService, super(const DoctorDashboardInitial()) {

    on<FetchDoctorDashboardData>((event, emit) async {
      try{
        final versionEntity = await _getAppVersionInfoUseCase();
        await _secureStorageService.writeSecureValue<String>(
          SecureCacheKey.appVersionInfo,
          versionEntity.displayVersion,
        );
        emit(const DoctorDashboardLoading());

        await Future.delayed(const Duration(milliseconds: 600));

        final List<AppointmentEntity> mockToday = [
          const AppointmentEntity(
            id: '1',
            patientName: 'Sarah Jenkins',
            type: AppointmentType.videoCall,
            reason: 'Follow-up Consultation',
            appointmentTime: '09:30 AM',
          ),
          const AppointmentEntity(
            id: '2',
            patientName: 'Michael Chen',
            type: AppointmentType.inClinic,
            reason: 'Annual Health Checkup',
            appointmentTime: '10:15 AM',
          ),
        ];

        final List<AppointmentEntity> mockRecent = [
          const AppointmentEntity(
            id: '101',
            patientName: 'Mani Jay',
            type: AppointmentType.inClinic,
            diagnosis: 'Acute Migraine headaches',
            appointmentDate: '19/5/2026',
          ),
          const AppointmentEntity(
            id: '102',
            patientName: 'Anil Kumar',
            type: AppointmentType.inClinic,
            diagnosis: 'Common Cold & Nasal Congestion',
            appointmentDate: '18/5/2026',
          ),
        ];

        emit(
          DoctorDashboardLoaded(
            todaysAppointments: mockToday,
            recentPatients: mockRecent,
          ),
        );
      }catch(e){
        emit(
          DoctorDashboardError(message: e.toString())
        );
      }

    });

    on<ViewCalendarEvent>((event, emit) {
      final cachedState = state;
      emit(DoctorAppointmentsNav());
      if (cachedState is DoctorDashboardLoaded) emit(cachedState);
    });

    on<ViewPatientsEvent>((event, emit) {
      final cachedState = state;
      emit(PatientManagementNav());
      if (cachedState is DoctorDashboardLoaded) emit(cachedState);
    });

    on<DocAndAppPatientDetailsNavEvent>((event, emit) {
      final cachedState = state;
      emit(DocAndAppPatientDetailsNavState());
      if (cachedState is DoctorDashboardLoaded) emit(cachedState);
    });

    on<FetchPatientDetails>((event, emit) async {
      emit(const DoctorDashboardLoading());
      await Future.delayed(const Duration(milliseconds: 400));

      final mockProfileDetails = {
        "name": "mani n",
        "age": 25,
        "gender": "Male",
        "last_updated": "4/6/2026",
        "phone": "9908875796",
        "email": "jmani83280@gmail.com",
        "location": null,
        "vitals": {
          "bp": null, "pulse": null, "temp": null, "spo2": null, "weight": null, "height": null
        },
        "insurance": {
          "provider": "sbi",
          "policy_number": "12345",
          "valid_till": null
        },
        "notes": [
          {"doctor": "Dr. Raja Nagalingam", "date": "Jun 05", "text": "Daily go for a walk"},
          {"doctor": "Dr. Raja Nagalingam", "date": "Jun 05", "text": "Do gym on alternative days"},
        ]
      };

      emit(PatientDetailsLoadedState(patientData: mockProfileDetails));
    });
  }
}