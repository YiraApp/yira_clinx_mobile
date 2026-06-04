part of 'test_result_bloc.dart';


@immutable
abstract class TestResultsState extends Equatable {
  const TestResultsState();
  @override
  List<Object?> get props => [];
}

class TestResultsInitial extends TestResultsState {}

class TestResultsLoading extends TestResultsState {}

class TestResultsLoaded extends TestResultsState {
  final double overallPercentage;
  final int totalTests;
  final int normalTests;
  final int bloodTestsCount;
  final int urineTestsCount;
  final int abnormalCount;
  final List<Map<String, dynamic>> labResults;
  final List<Map<String, dynamic>> filteredLabResults;
  final String selectedStatus;

  const TestResultsLoaded({
    required this.overallPercentage,
    required this.totalTests,
    required this.normalTests,
    required this.bloodTestsCount,
    required this.urineTestsCount,
    required this.abnormalCount,
    required this.labResults,
    required this.filteredLabResults,
    required this.selectedStatus,
  });

  TestResultsLoaded copyWith({
    List<Map<String, dynamic>>? filteredLabResults,
    String? selectedStatus,
  }) {
    return TestResultsLoaded(
      overallPercentage: overallPercentage,
      totalTests: totalTests,
      normalTests: normalTests,
      bloodTestsCount: bloodTestsCount,
      urineTestsCount: urineTestsCount,
      abnormalCount: abnormalCount,
      labResults: labResults,
      filteredLabResults: filteredLabResults ?? this.filteredLabResults,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }

  @override
  List<Object?> get props => [
    overallPercentage,
    totalTests,
    normalTests,
    bloodTestsCount,
    urineTestsCount,
    abnormalCount,
    labResults,
    filteredLabResults,
    selectedStatus,
  ];
}

class TestResultsError extends TestResultsState {
  final String message;
  const TestResultsError(this.message);

  @override
  List<Object?> get props => [message];
}
