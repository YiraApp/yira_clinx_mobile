part of 'doctor_dashboard_bloc.dart';

@immutable
abstract class DoctorDashboardState extends Equatable {
  const DoctorDashboardState();

  @override
  List<Object?> get props => [];
}

class DoctorDashboardInitial extends DoctorDashboardState {
  const DoctorDashboardInitial();
}

class DoctorDashboardLoading extends DoctorDashboardState {
  const DoctorDashboardLoading();
}

class DoctorDashboardLoaded extends DoctorDashboardState {
  final List<AppointmentEntity> todaysAppointments;
  final List<AppointmentEntity> recentPatients;

  const DoctorDashboardLoaded({
    required this.todaysAppointments,
    required this.recentPatients,
  });

  @override
  List<Object?> get props => [todaysAppointments, recentPatients];
}

class DoctorDashboardError extends DoctorDashboardState {
  final String message;

  const DoctorDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

class DoctorAppointmentsNav extends DoctorDashboardState {
  @override
  List<Object?> get props => [];
}

class PatientManagementNav extends DoctorDashboardState {
  @override
  List<Object?> get props => [];
}

class DocAndAppPatientDetailsNavState extends DoctorDashboardState {
  @override
  List<Object?> get props => [];
}

class PatientDetailsLoadedState extends DoctorDashboardState {
  final Map<String, dynamic> patientData;

  const PatientDetailsLoadedState({required this.patientData});

  @override
  List<Object?> get props => [patientData];
}