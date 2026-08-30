import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'test_result_event.dart';
part 'test_result_state.dart';

class TestResultsBloc extends Bloc<TestResultsEvent, TestResultsState> {
  TestResultsBloc() : super(TestResultsInitial()) {
    on<LoadTestResults>(_onLoadResults);
    on<FilterByStatus>(_onFilterByStatus);
  }

  Future<void> _onLoadResults(LoadTestResults event, Emitter<TestResultsState> emit) async {
    emit(TestResultsLoading());

    // Clean initial state for new users (connects to dynamic diagnostic lab services)
    final results = <Map<String, dynamic>>[];

    emit(TestResultsLoaded(
      overallPercentage: 1.0,
      totalTests: 0,
      normalTests: 0,
      bloodTestsCount: 0,
      urineTestsCount: 0,
      abnormalCount: 0,
      labResults: results,
      filteredLabResults: results,
      selectedStatus: "All",
    ));
  }

  void _onFilterByStatus(FilterByStatus event, Emitter<TestResultsState> emit) {
    if (state is TestResultsLoaded) {
      final currentState = state as TestResultsLoaded;

      List<Map<String, dynamic>> filtered;

      if (event.status == "All") {
        filtered = currentState.labResults;
      } else {
        // Logic: Filter based on whether the status contains the filter string
        // Note: Check your Map's 'status' values match your dropdown options
        filtered = currentState.labResults.where((item) {
          final itemStatus = item['status'].toString().toLowerCase();
          final filterQuery = event.status.toLowerCase();
          return itemStatus.contains(filterQuery);
        }).toList();
      }

      emit(currentState.copyWith(
        filteredLabResults: filtered,
        selectedStatus: event.status,
      ));
    }
  }
}
