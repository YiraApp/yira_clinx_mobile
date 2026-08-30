import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/domain/entities/medication/medication_entity.dart';
import '../../../domain/repositories/medication/medication_repository.dart';
import '../../models/medicaiton/medication_model.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final ApiClient _apiClient;

  MedicationRepositoryImpl(this._apiClient);

  @override
  Future<MedicationEntity> getMedicationSummary() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      final token = currentUser?.data?.accessToken ?? '';

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
            int totalPrescriptions = items.length;
            int totalMeds = 0;
            int activeMeds = 0;

            for (var p in items) {
              if (p is Map<String, dynamic>) {
                final meds = p['Medications'] ?? p['medications'];
                if (meds is List) {
                  totalMeds += meds.length;
                  activeMeds += meds.length;
                }
              }
            }

            return MedicationSummaryModel(
              totalPrescriptions: totalPrescriptions,
              activeMeds: activeMeds,
              totalMedications: totalMeds,
              needRefill: 0,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        "Error fetching medication summary: $e",
        error: e,
        stackTrace: stackTrace,
        name: "MedicationRepositoryImpl",
      );
    }

    return const MedicationSummaryModel(
      totalPrescriptions: 0,
      activeMeds: 0,
      totalMedications: 0,
      needRefill: 0,
    );
  }
}