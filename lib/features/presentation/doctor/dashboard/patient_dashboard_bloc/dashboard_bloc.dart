import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/favorite_patients_service.dart';
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
    on<LoadMorePatients>(_onLoadMorePatients);
    on<ClearFilters>(_onClearFilters);
    on<ToggleFavoritePatientEvent>(_onToggleFavoritePatient);
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

      final favIds = await FavoritePatientsService().loadFavorites(doctorId);

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

        patients = list.map((item) {
          final model = PatientModel.fromJson(item as Map<String, dynamic>);
          final isFav = favIds.contains(model.userId) || favIds.contains(model.id);
          return model.copyWith(isFavorite: isFav);
        }).toList();
      }

      emit(state.copyWith(
        status: DashboardStatus.success,
        allPatients: patients,
      ));

      _applyFilters(emit, query: state.searchQuery, resetPage: true);
    } catch (e) {
      emit(state.copyWith(status: DashboardStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleFavoritePatient(
    ToggleFavoritePatientEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
        ? currentUser.data!.id!.trim()
        : '1';

    final isNowFav = await FavoritePatientsService().toggleFavorite(
      patientId: event.patientId,
      alternateId: event.alternateId,
      doctorId: doctorId,
    );

    final updatedAll = state.allPatients.map((p) {
      final matchesPatientId = p.userId == event.patientId || p.id == event.patientId;
      final matchesAltId = event.alternateId != null && (p.userId == event.alternateId || p.id == event.alternateId);
      if (matchesPatientId || matchesAltId) {
        return p.copyWith(isFavorite: isNowFav);
      }
      return p;
    }).toList();

    emit(state.copyWith(allPatients: updatedAll));
    _applyFilters(emit, query: state.searchQuery, resetPage: false);
  }

  void _onSearchPatients(SearchPatients event, Emitter<DashboardState> emit) {
    emit(state.copyWith(searchQuery: event.query));
    _applyFilters(emit, query: event.query, resetPage: true);
  }

  void _onFilterPatients(FilterPatients event, Emitter<DashboardState> emit) {
    final String? statusToSet = (event.status == null || event.status == "All" || event.status!.trim().isEmpty)
        ? null
        : event.status!.trim();

    final String? genderToSet = (event.gender == null || event.gender == "All" || event.gender!.trim().isEmpty)
        ? null
        : event.gender!.trim();

    emit(state.copyWith(
      selectedStatus: () => statusToSet,
      selectedGender: () => genderToSet,
    ));

    _applyFilters(emit, query: state.searchQuery, resetPage: true);
  }

  void _onClearFilters(ClearFilters event, Emitter<DashboardState> emit) {
    emit(state.copyWith(
      searchQuery: '',
      selectedStatus: () => null,
      selectedGender: () => null,
    ));
    _applyFilters(emit, query: '', resetPage: true);
  }

  void _onLoadMorePatients(LoadMorePatients event, Emitter<DashboardState> emit) {
    if (!state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.currentPage + 1;
    final totalToShow = nextPage * state.pageSize;
    final paginatedList = state.allFilteredPatients.take(totalToShow).toList();
    final hasMoreNow = state.allFilteredPatients.length > paginatedList.length;

    emit(state.copyWith(
      currentPage: nextPage,
      patients: paginatedList,
      hasMore: hasMoreNow,
      isLoadingMore: false,
    ));
  }

  void _applyFilters(Emitter<DashboardState> emit, {String? query, bool resetPage = true}) {
    final searchQuery = (query ?? state.searchQuery).trim().toLowerCase();

    List<PatientEntity> filteredList = state.allPatients.where((patient) {
      // 1. Search Query Match
      final matchesSearch = searchQuery.isEmpty ||
          patient.name.toLowerCase().contains(searchQuery) ||
          patient.id.toLowerCase().contains(searchQuery) ||
          patient.userId.toLowerCase().contains(searchQuery) ||
          patient.condition.toLowerCase().contains(searchQuery) ||
          patient.allergy.toLowerCase().contains(searchQuery);

      // 2. Status / Tab Filter Match
      bool matchesStatus = true;
      if (state.selectedStatus != null &&
          state.selectedStatus!.trim().isNotEmpty &&
          state.selectedStatus != "All") {
        final selected = state.selectedStatus!.trim().toLowerCase();
        if (selected == "favorites" || selected == "favorite") {
          matchesStatus = patient.isFavorite == true;
        } else if (selected == "recent") {
          matchesStatus = patient.lastVisit.trim().isNotEmpty || patient.visits > 0;
        } else if (selected == "male" || selected == "m") {
          matchesStatus = patient.gender.trim().toLowerCase().startsWith('m');
        } else if (selected == "female" || selected == "f") {
          matchesStatus = patient.gender.trim().toLowerCase().startsWith('f');
        } else {
          final pStatus = patient.status.trim().toLowerCase();
          final pCondition = patient.condition.trim().toLowerCase();
          matchesStatus = pStatus == selected || pCondition.contains(selected);
        }
      }

      // 3. Gender Filter Match
      bool matchesGender = true;
      if (state.selectedGender != null &&
          state.selectedGender!.trim().isNotEmpty &&
          state.selectedGender != "All") {
        final selectedG = state.selectedGender!.trim().toLowerCase();
        matchesGender = patient.gender.trim().toLowerCase().startsWith(selectedG.substring(0, 1));
      }

      return matchesSearch && matchesStatus && matchesGender;
    }).toList();

    // Sort: Favorites or Recent first if selected
    if (state.selectedStatus?.toLowerCase() == 'recent') {
      filteredList.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
    }

    final page = resetPage ? 1 : state.currentPage;
    final totalToShow = page * state.pageSize;
    final paginatedList = filteredList.take(totalToShow).toList();
    final hasMoreNow = filteredList.length > paginatedList.length;

    emit(state.copyWith(
      allFilteredPatients: filteredList,
      patients: paginatedList,
      currentPage: page,
      hasMore: hasMoreNow,
      isLoadingMore: false,
    ));
  }
}