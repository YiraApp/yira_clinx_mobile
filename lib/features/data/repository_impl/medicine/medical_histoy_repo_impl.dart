import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import '../../../domain/entities/medicine/medical_history_entity.dart';
import '../../../domain/repositories/medicine/medical_history_repo.dart';
import '../../models/medicine/medical_history_model.dart';

class MedicalHistoryRepositoryImpl implements MedicalHistoryRepository {
  final ApiClient _apiClient;

  MedicalHistoryRepositoryImpl(this._apiClient);

  @override
  Future<List<MedicalRecordBriefEntity>> fetchMedicalRecords({
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  }) async {
    try {
      if (patientId != null && patientId.trim().isNotEmpty) {
        final currentUser = GlobalSession.instance.userNotifier.value;
        final token = currentUser?.data?.accessToken ?? '';

        final queryParams = <String, dynamic>{};
        if (appointmentId != null && appointmentId.trim().isNotEmpty) {
          queryParams['appointmentId'] = appointmentId.trim();
        }
        if (hospitalId != null && hospitalId.trim().isNotEmpty) {
          queryParams['hospitalId'] = hospitalId.trim();
        }
        if (orgId != null && orgId.trim().isNotEmpty) {
          queryParams['orgId'] = orgId.trim();
        }

        final response = await _apiClient.account(showSuccessSnack: false).get(
          '${URLs.medicalRecordsUrl}/patient/$patientId',
          queryParameters: queryParams,
          options: Options(
            headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
          ),
        );

        if (response.data != null && response.data is Map<String, dynamic>) {
          final mapData = response.data as Map<String, dynamic>;
          final items = mapData['data'] ?? mapData['result'] ?? mapData['payload'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map((e) => MedicalRecordBriefModel.fromJson(e))
                .toList();
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        "Error fetching medical records from API",
        error: e,
        stackTrace: stackTrace,
        name: "MedicalHistoryRepoImpl",
      );
    }

    return [];
  }

  @override
  Future<void> createMedicalRecord(Map<String, dynamic> data) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';

      await _apiClient.account(showSuccessSnack: true).post(
        URLs.medicalRecordsUrl,
        data: data,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        "Error creating medical record",
        error: e,
        stackTrace: stackTrace,
        name: "MedicalHistoryRepoImpl",
      );
      rethrow;
    }
  }

  @override
  Future<void> updateMedicalRecord(String id, Map<String, dynamic> data) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';

      await _apiClient.account(showSuccessSnack: true).put(
        '${URLs.medicalRecordsUrl}/$id',
        data: data,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        "Error updating medical record",
        error: e,
        stackTrace: stackTrace,
        name: "MedicalHistoryRepoImpl",
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteMedicalRecord(String id) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';

      await _apiClient.account(showSuccessSnack: true).delete(
        '${URLs.medicalRecordsUrl}/$id',
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        "Error deleting medical record",
        error: e,
        stackTrace: stackTrace,
        name: "MedicalHistoryRepoImpl",
      );
    }
  }
}