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

    // Simulated Repository Call / Mock Data
    final results = [
      {
        "title": "Complete Blood Count (CBC)",
        "doctor": "Dr. Priya Sharma",
        "date": "2024-01-15",
        "params": ["Hemoglobin", "WBC Count", "RBC Count", "+2 more"],
        "status": "Normal",
        "isAbnormal": false
      },
      {
        "title": "Lipid Profile",
        "doctor": "Dr. Rajesh Kumar",
        "date": "2024-01-12",
        "params": ["Total Cholesterol", "LDL Cholesterol", "HDL Cholesterol"],
        "status": "1 Abnormal",
        "isAbnormal": true
      }
    ];

    emit(TestResultsLoaded(
      overallPercentage: 0.94,
      totalTests: 4,
      normalTests: 3,
      bloodTestsCount: 3,
      urineTestsCount: 1,
      abnormalCount: 1,
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
