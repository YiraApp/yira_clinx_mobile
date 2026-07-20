part of 'doctor_dashboard_bloc.dart';

@immutable
abstract class DoctorDashboardState extends Equatable {
  final DashBoardPatientDetailsEntity? patientData;
  final DashBoardPatientDetailsClinicalNotesEntity? clinicalNotesData;

  const DoctorDashboardState({this.patientData, this.clinicalNotesData});

  @override
  List<Object?> get props => [patientData, clinicalNotesData];
}

class DoctorDashboardInitial extends DoctorDashboardState {
  const DoctorDashboardInitial();
}

class DoctorDashboardLoading extends DoctorDashboardState {
  const DoctorDashboardLoading();
}

class DashboardPatientDetailsLoading extends DoctorDashboardState {
  const DashboardPatientDetailsLoading({super.patientData, super.clinicalNotesData});
}

class DashboardPatientClinicalLoading extends DoctorDashboardState {
  const DashboardPatientClinicalLoading({super.patientData, super.clinicalNotesData});
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

class PatientDetailsLoadedState extends DoctorDashboardState {
  final bool isDetailsLoading;

  const PatientDetailsLoadedState({
    required super.patientData,
    super.clinicalNotesData,
    this.isDetailsLoading = false,
  });

  @override
  List<Object?> get props => [patientData, clinicalNotesData, isDetailsLoading];
}

class DoctorDashboardError extends DoctorDashboardState {
  final String message;

  const DoctorDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

class DashboardPatientDetailsError extends DoctorDashboardState {
  final String message;

  const DashboardPatientDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class DashboardPatientClinicalError extends DoctorDashboardState {
  final String message;

  const DashboardPatientClinicalError({required this.message});

  @override
  List<Object?> get props => [message];
}

// PRODUCTION FIX: Added unique timestamp parameter to break Equatable identity
// loops when returning to the dashboard from alternative screens.
class DoctorDashboardSuccessState extends DoctorDashboardState {
  final DoctorDashboardEntity dashboardEntity;
  final DateTime? timestamp;

  const DoctorDashboardSuccessState({
    required this.dashboardEntity,
    this.timestamp,
    super.patientData,
    super.clinicalNotesData,
  });

  @override
  List<Object?> get props => [dashboardEntity, timestamp, patientData, clinicalNotesData];
}

class DoctorAppointmentsNav extends DoctorDashboardState {
  final DoctorDashboardEntity dashboardEntity;
  final DateTime timestamp;

  const DoctorAppointmentsNav({
    required this.dashboardEntity,
    required this.timestamp,
    super.patientData,
    super.clinicalNotesData,
  });

  @override
  List<Object?> get props => [dashboardEntity, timestamp, patientData, clinicalNotesData];
}

class PatientManagementNav extends DoctorDashboardState {
  final DoctorDashboardEntity dashboardEntity;
  final DateTime timestamp;

  const PatientManagementNav({
    required this.dashboardEntity,
    required this.timestamp,
    super.patientData,
    super.clinicalNotesData,
  });

  @override
  List<Object?> get props => [dashboardEntity, timestamp, patientData, clinicalNotesData];
}

class DocAndAppPatientDetailsNavState extends DoctorDashboardState {
  final DashboardPatientDetails patientDetails;
  final DateTime timestamp;

  const DocAndAppPatientDetailsNavState({
    required this.patientDetails,
    required this.timestamp,
    super.patientData,
    super.clinicalNotesData,
  });

  @override
  List<Object?> get props => [patientDetails, timestamp, patientData, clinicalNotesData];
}

class PatientClinicalLoadedState extends DoctorDashboardState {
  const PatientClinicalLoadedState({
    required DashBoardPatientDetailsClinicalNotesEntity clinicalData,
    super.patientData,
  }) : super(clinicalNotesData: clinicalData);

  @override
  List<Object?> get props => [patientData, clinicalNotesData];
}