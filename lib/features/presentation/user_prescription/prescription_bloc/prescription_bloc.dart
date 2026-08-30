import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/domain/entities/medication/medication_entity.dart';
import 'package:yiraclinics/features/use_cases/ge_prescription_use_case.dart';

part 'prescription_event.dart';
part 'prescription_state.dart';

class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final GetPrescriptionUseCase getMedicationSummary;
  final ApiClient _apiClient = ApiClient();

  MedicationBloc({required this.getMedicationSummary}) : super(const MedicationState()) {
    on<LoadMedicationData>(_onLoadMedicationData);
    on<FilterByStatus>(_onFilterByStatus);
    on<LoadPrescriptionDetails>(_onLoadPrescriptionDetails);
  }

  Future<void> _onLoadMedicationData(LoadMedicationData event, Emitter<MedicationState> emit) async {
    emit(state.copyWith(status: MedicationStatus.loading));
    try {
      final summaryData = await getMedicationSummary();

      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      final token = currentUser?.data?.accessToken ?? '';

      final List<Map<String, dynamic>> realList = [];

      if (userId.isNotEmpty) {
        final response = await _apiClient.account(showSuccessSnack: false).get(
          '${URLs.prescriptionsUrl}/patient/$userId',
          options: Options(
            headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
          ),
        );

        if (response.data != null && response.data is Map<String, dynamic>) {
          final mapData = response.data as Map<String, dynamic>;
          final items = mapData['data'] ?? mapData['result'] ?? mapData['payload'];
          if (items is List) {
            for (var p in items) {
              if (p is Map<String, dynamic>) {
                final doc = p['Doctor'];
                final docName = doc != null
                    ? 'Dr. ${doc['FirstName'] ?? ''} ${doc['LastName'] ?? ''}'.trim()
                    : 'Consulting Physician';
                final specialty = doc != null ? (doc['Specialty'] ?? 'General Medicine') : 'General Medicine';
                final diags = p['Diagnoses'] ?? p['diagnoses'];
                String condition = 'General Consultation';
                if (diags is List && diags.isNotEmpty) {
                  final first = diags.first;
                  condition = (first is Map ? (first['Diagnosis'] ?? first['name']) : first.toString()) ?? 'General Consultation';
                }

                final medsRaw = p['Medications'] ?? p['medications'] ?? [];
                final List<Map<String, dynamic>> medList = [];
                if (medsRaw is List) {
                  for (var m in medsRaw) {
                    if (m is Map<String, dynamic>) {
                      final name = (m['Medication'] ?? m['medication'] ?? m['name'] ?? '').toString();
                      final dosage = (m['Dosage'] ?? m['dosage'] ?? '').toString();
                      final freq = (m['FrequencyType'] ?? m['frequency'] ?? '').toString();
                      final inst = (m['Instructions'] ?? m['instructions'] ?? '').toString();
                      final durVal = (m['DurationValue'] ?? m['durationValue'] ?? 7).toString();
                      final durUnit = (m['DurationUnit'] ?? m['durationUnit'] ?? 'Days').toString();
                      medList.add({
                        "name": name,
                        "code": (m['ConceptId'] ?? m['conceptId'] ?? '').toString(),
                        "dosage": dosage.isNotEmpty ? "$dosage${freq.isNotEmpty ? ' - $freq' : ''}" : freq,
                        "instructions": inst.isNotEmpty ? inst : 'Take as directed by doctor',
                        "duration": "$durVal $durUnit",
                        "frequency": freq,
                        "needRefill": true,
                      });
                    }
                  }
                }

                final createdAt = p['CreatedAt'] ?? p['createdAt'];
                String dateStr = 'Recent';
                if (createdAt != null) {
                  try {
                    final dt = DateTime.parse(createdAt.toString());
                    dateStr = DateFormat('yyyy-MM-dd').format(dt);
                  } catch (_) {}
                }

                realList.add({
                  "id": (p['Id'] ?? p['id'] ?? '').toString(),
                  "title": "Prescription for $condition",
                  "condition": condition,
                  "doctor": "$docName - $specialty",
                  "specialty": specialty,
                  "date": dateStr,
                  "status": "Active",
                  "pharmacy": "Yira Clinx E-Pharmacy",
                  "notes": (p['Notes'] ?? p['notes'] ?? 'Follow-up as advised. Take medicines as prescribed.').toString(),
                  "medications": medList,
                  "needRefill": medList.isNotEmpty,
                });
              }
            }
          }
        }
      }

      final int totalPrescriptions = realList.length;
      final int activeMeds = realList.where((p) => p['status'].toString().toLowerCase() == 'active').length;
      final int totalMedications = realList.fold<int>(0, (sum, p) => sum + ((p['medications'] as List?)?.length ?? 0));
      final int needRefill = realList.where((p) => p['needRefill'] == true && p['status'].toString().toLowerCase() == 'active').length;

      final dynamicSummary = MedicationEntity(
        totalPrescriptions: totalPrescriptions > 0 ? totalPrescriptions : (summaryData.totalPrescriptions),
        activeMeds: activeMeds > 0 ? activeMeds : (summaryData.activeMeds),
        totalMedications: totalMedications > 0 ? totalMedications : (summaryData.totalMedications),
        needRefill: needRefill > 0 ? needRefill : (summaryData.needRefill),
      );

      emit(state.copyWith(
        status: MedicationStatus.success,
        summary: dynamicSummary,
        allPrescriptions: realList,
        filteredPrescriptions: realList,
        selectedStatus: "All",
      ));
    } catch (e) {
      emit(state.copyWith(status: MedicationStatus.failure, error: e.toString()));
    }
  }

  void _onFilterByStatus(FilterByStatus event, Emitter<MedicationState> emit) {
    List<Map<String, dynamic>> filtered;
    final status = event.status.trim().toLowerCase();

    if (status == "all") {
      filtered = state.allPrescriptions;
    } else if (status == "refill" || status == "need refill") {
      filtered = state.allPrescriptions.where((p) => p['needRefill'] == true && p['status'].toString().toLowerCase() == 'active').toList();
    } else {
      filtered = state.allPrescriptions.where((p) => p['status'].toString().toLowerCase() == status).toList();
    }

    emit(state.copyWith(selectedStatus: event.status, filteredPrescriptions: filtered));
  }

  Future<void> _onLoadPrescriptionDetails(LoadPrescriptionDetails event, Emitter<MedicationState> emit) async {
    emit(state.copyWith(status: MedicationStatus.loading));

    final match = state.allPrescriptions.firstWhere(
      (p) => p['id'].toString() == event.prescriptionId.toString(),
      orElse: () => state.allPrescriptions.isNotEmpty ? state.allPrescriptions.first : {},
    );

    if (match.isNotEmpty) {
      emit(state.copyWith(status: MedicationStatus.success, selectedPrescriptionDetail: match));
    } else {
      emit(state.copyWith(status: MedicationStatus.success, selectedPrescriptionDetail: null));
    }
  }
}
