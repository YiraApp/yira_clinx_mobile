import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../domain/entities/dashboard/patient_entity.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';


class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardState()) {
    on<GetDashboardData>(_onGetDashboardData);
    on<SearchPatients>(_onSearchPatients);
    on<FilterPatients>(_onFilterPatients);
    on<ViewPatientDetailsEvent>((event,emit)async{
      emit(ViewPatientDetailsState());
    });
  }

  Future<void> _onGetDashboardData(
      GetDashboardData event,
      Emitter<DashboardState> emit
      ) async {
    emit(state.copyWith(status: DashboardStatus.loading));

    try {
      final List<PatientEntity> mockData = [
        PatientEntity(id: "YRA0001", name: "Rajesh Kumar", condition: "Hypertension", lastVisit: "Jan 15", status: "Active", gender: "Male", visits: 8, age: 45, allergy: "Penicillin"),
        PatientEntity(id: "YRA0002", name: "Priya Sharma", condition: "Arrhythmia", lastVisit: "Jan 14", status: "Monitoring", gender: "Female", visits: 5, age: 38),
        PatientEntity(id: "YRA0003", name: "Amit Patel", condition: "Post-surgery recovery", lastVisit: "Jan 13", status: "Recovering", gender: "Male", visits: 12, age: 52, allergy: "Aspirin"),        PatientEntity(id: "YRA0004", name: "Rajesh Kumar", condition: "Hypertension", lastVisit: "Jan 15", status: "Active", gender: "Male", visits: 8, age: 45, allergy: "Penicillin"),
        PatientEntity(id: "YRA0005", name: "Priya Sharma", condition: "Arrhythmia", lastVisit: "Jan 14", status: "Monitoring", gender: "Female", visits: 5, age: 38),
        PatientEntity(id: "YRA0006", name: "Amit Patel", condition: "Post-surgery recovery", lastVisit: "Jan 13", status: "Recovering", gender: "Male", visits: 12, age: 52, allergy: "Aspirin"),
      ];

      emit(state.copyWith(
        status: DashboardStatus.success,
        patients: mockData,
        allPatients: mockData,
      ));
    } catch (e) {
      emit(state.copyWith(status: DashboardStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onSearchPatients(SearchPatients event, Emitter<DashboardState> emit) {
    _applyFilters(emit, query: event.query);
  }



  void _onFilterPatients(FilterPatients event, Emitter<DashboardState> emit) {
    // If event.status is "All", we want to set it to null.
    // If event.status is null, it means the user clicked the OTHER dropdown, so we keep the current state.
    final String? statusToSet = event.status == "All"
        ? null
        : (event.status ?? state.selectedStatus);

    final String? genderToSet = event.gender == "All"
        ? null
        : (event.gender ?? state.selectedGender);

    emit(state.copyWith(
      selectedStatus: () => statusToSet,
      selectedGender: () => genderToSet,
    ));

    _applyFilters(emit);
  }
  void _applyFilters(Emitter<DashboardState> emit, {String? query}) {
    final searchQuery = (query ?? "").toLowerCase();

    final filteredList = state.allPatients.where((patient) {
      // 1. Check Search Query
      final matchesSearch = patient.name.toLowerCase().contains(searchQuery) ||
          patient.id.toLowerCase().contains(searchQuery);

      // 2. Check Status Filter
      final matchesStatus = state.selectedStatus == null ||
          patient.status.toLowerCase() == state.selectedStatus!.toLowerCase();

      // 3. Check Gender Filter
      final matchesGender = state.selectedGender == null ||
          patient.gender.toLowerCase() == state.selectedGender!.toLowerCase();

      return matchesSearch && matchesStatus && matchesGender;
    }).toList();

    emit(state.copyWith(patients: filteredList));
  }
}