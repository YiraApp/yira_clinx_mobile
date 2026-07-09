part of 'doctor_dashboard_bloc.dart';

@immutable
abstract class DoctorDashboardEvent extends Equatable {
  const DoctorDashboardEvent();

  @override
  List<Object?> get props => [];
}

class FetchDoctorDashboardData extends DoctorDashboardEvent {
  @override
  List<Object?> get props => [];
}

class ViewCalendarEvent extends DoctorDashboardEvent {
  @override
  List<Object?> get props => [];
}

class ViewPatientsEvent extends DoctorDashboardEvent {
  @override
  List<Object?> get props => [];
}

class DocAndAppPatientDetailsNavEvent extends DoctorDashboardEvent {
  @override
  List<Object?> get props => [];
}

// PRODUCTION FIX: Dispatched from the UI listener to instantly clear
// the navigation state pipeline without hitting the network layers again.
class ClearNavigationTriggerEvent extends DoctorDashboardEvent {
  @override
  List<Object?> get props => [];
}

class FetchPatientDetails extends DoctorDashboardEvent {
  final String appointmentId;

  const FetchPatientDetails({required this.appointmentId});

  @override
  List<Object?> get props => [appointmentId];
}

class FetchPatientClinicalDetails extends DoctorDashboardEvent {
  final String appointmentId;

  const FetchPatientClinicalDetails({required this.appointmentId});

  @override
  List<Object?> get props => [appointmentId];
}