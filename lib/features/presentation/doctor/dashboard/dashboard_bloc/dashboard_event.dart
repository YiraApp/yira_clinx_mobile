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
