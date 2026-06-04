part of 'doctor_dashboard_bloc.dart';

@immutable

abstract class DoctorDashboardEvent extends Equatable {}
class FetchDoctorDashboardData extends DoctorDashboardEvent {
  @override
  List<Object?> get props => [];
}
class ViewCalendarEvent extends DoctorDashboardEvent{

  @override
  List<Object?> get props => [];
}
class ViewPatientsEvent extends DoctorDashboardEvent{

  @override
  List<Object?> get props => [];
}