part of 'dashboard_bloc.dart';

@immutable

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class GetDashboardData extends DashboardEvent {
  const GetDashboardData();
}

class SearchPatients extends DashboardEvent {
  final String query;
  const SearchPatients(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterPatients extends DashboardEvent {
  final String? status;
  final String? gender;

  const FilterPatients({this.status, this.gender});

  @override
  List<Object?> get props => [status, gender];
}
class ViewPatientDetailsEvent extends DashboardEvent {
  final String patientId;
  final String? patientName;

  const ViewPatientDetailsEvent({required this.patientId, this.patientName});

  @override
  List<Object?> get props => [patientId, patientName];
}

class ToggleFavoritePatientEvent extends DashboardEvent {
  final String patientId;
  final String? alternateId;
  const ToggleFavoritePatientEvent({required this.patientId, this.alternateId});

  @override
  List<Object?> get props => [patientId, alternateId];
}

class LoadMorePatients extends DashboardEvent {
  const LoadMorePatients();
}

class ClearFilters extends DashboardEvent {
  const ClearFilters();
}


