import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';

import '../../../../domain/entities/appointments/appointment_entity.dart';

part 'doctor_dashboard_event.dart';
part 'doctor_dashboard_state.dart';

class DoctorDashboardBloc
    extends Bloc<DoctorDashboardEvent, DoctorDashboardState> {
  DoctorDashboardBloc() : super(const DoctorDashboardInitial()) {
    on<FetchDoctorDashboardData>((event, emit) async {
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
    });
    on<ViewCalendarEvent>((event, emit) async {
      emit(DoctorAppointmentsNav());
    });
    on<ViewPatientsEvent>((event, emit) async {
      emit(PatientManagementNav());
    });
  }
}
