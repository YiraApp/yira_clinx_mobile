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
        patients: patients,
        allPatients: patients,
      ));
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
    _applyFilters(emit);
  }

  void _onSearchPatients(SearchPatients event, Emitter<DashboardState> emit) {
    _applyFilters(emit, query: event.query);
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

    _applyFilters(emit);
  }

  void _applyFilters(Emitter<DashboardState> emit, {String? query}) {
    final searchQuery = (query ?? "").trim().toLowerCase();

    final filteredList = state.allPatients.where((patient) {
      // 1. Check Search Query
      final matchesSearch = searchQuery.isEmpty ||
          patient.name.toLowerCase().contains(searchQuery) ||
          patient.id.toLowerCase().contains(searchQuery) ||
          patient.condition.toLowerCase().contains(searchQuery) ||
          patient.allergy.toLowerCase().contains(searchQuery);

      // 2. Check Status / Favorites Filter
      bool matchesStatus = true;
      if (state.selectedStatus != null &&
          state.selectedStatus!.trim().isNotEmpty &&
          state.selectedStatus != "All") {
        final selected = state.selectedStatus!.trim().toLowerCase();
        if (selected == "favorites" || selected == "favorite" || selected.contains("favorite")) {
          matchesStatus = patient.isFavorite == true;
        } else {
          final pStatus = patient.status.trim().toLowerCase();
          final pCondition = patient.condition.trim().toLowerCase();
          matchesStatus = pStatus == selected || pCondition.contains(selected);
        }
      }

      // 3. Check Gender Filter
      bool matchesGender = true;
      if (state.selectedGender != null &&
          state.selectedGender!.trim().isNotEmpty &&
          state.selectedGender != "All") {
        final selectedG = state.selectedGender!.trim().toLowerCase();
        matchesGender = patient.gender.trim().toLowerCase() == selectedG;
      }

      return matchesSearch && matchesStatus && matchesGender;
    }).toList();

    emit(state.copyWith(patients: filteredList));
  }
}