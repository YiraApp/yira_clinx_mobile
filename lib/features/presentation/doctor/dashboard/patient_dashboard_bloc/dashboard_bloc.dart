import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/data/models/dashboard/patient_model.dart';
import '../../../../domain/entities/dashboard/patient_entity.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';


class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardState()) {
    on<GetDashboardData>(_onGetDashboardData);
    on<SearchPatients>(_onSearchPatients);
    on<FilterPatients>(_onFilterPatients);
    on<ViewPatientDetailsEvent>((event, emit) async {
      emit(ViewPatientDetailsState(
        patientId: event.patientId,
        patientName: event.patientName,
      ));
    });
  }

  Future<void> _onGetDashboardData(
      GetDashboardData event,
      Emitter<DashboardState> emit
      ) async {
    emit(state.copyWith(status: DashboardStatus.loading));

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int orgId = currentUser?.data?.latestOrgId ?? 1;
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.patientsListUrl,
        data: {
          "doctorId": doctorId,
          "orgId": orgId,
          "hospitalId": hospitalId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      List<PatientEntity> patients = [];
      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final rawList = rawData['data'];
        List<dynamic> list = [];
        if (rawList is List) {
          list = rawList;
        } else if (rawList is Map<String, dynamic> && rawList['patients'] is List) {
          list = rawList['patients'] as List;
        }

        patients = list.map((item) => PatientModel.fromJson(item as Map<String, dynamic>)).toList();
      }

      emit(state.copyWith(
        status: DashboardStatus.success,
        patients: patients,
        allPatients: patients,
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