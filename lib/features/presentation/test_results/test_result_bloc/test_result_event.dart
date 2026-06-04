part of 'test_result_bloc.dart';


@immutable
abstract class TestResultsEvent extends Equatable {
  const TestResultsEvent();
  @override
  List<Object?> get props => [];
}

class LoadTestResults extends TestResultsEvent {}

class FilterByStatus extends TestResultsEvent {
  final String status;
  const FilterByStatus(this.status);

  @override
  List<Object?> get props => [status];
}