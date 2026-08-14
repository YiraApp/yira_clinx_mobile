import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import '../../../domain/entities/prescriptions/prescription_entity.dart';
import '../../../domain/repositories/prescritpions/prescriptions_repo.dart';
import '../../models/prescriptions/prescriptions_model.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final ApiClient _apiClient;

  PrescriptionRepositoryImpl(this._apiClient);

  @override
  Future<PrescriptionEntity> getPrescriptionByPatientId(
    String patientId, {
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

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

      final url = '${URLs.prescriptionsUrl}/patient/$patientId';

      final response = await _apiClient.account(showSuccessSnack: false).get(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final mapData = response.data as Map<String, dynamic>;
        final items = mapData['data'] ?? mapData['result'] ?? mapData['payload'];

        if (items is List && items.isNotEmpty) {
          return PrescriptionModel.fromJson(items.first as Map<String, dynamic>);
        } else if (items is Map<String, dynamic>) {
          return PrescriptionModel.fromJson(items);
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        "Prescription fetch API call error",
        error: e,
        stackTrace: stackTrace,
        name: "PrescriptionRepositoryImpl",
      );
    }

    return const PrescriptionEntity(
      patientId: '',
      diagnoses: [],
      medications: [],
      additionalNotes: '',
    );
  }

  @override
  Future<void> savePrescription(PrescriptionEntity prescription) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      final Map<String, dynamic> payload = {
        'patientId': prescription.patientId,
        'doctorId': currentUser?.data?.id ?? '',
        if (prescription.appointmentId != null && prescription.appointmentId!.trim().isNotEmpty)
          'appointmentId': prescription.appointmentId!.trim(),
        if (prescription.hospitalId != null && prescription.hospitalId!.trim().isNotEmpty) ...{
          'hospitalId': prescription.hospitalId!.trim(),
          'HospitalId': prescription.hospitalId!.trim(),
        },
        if (prescription.orgId != null && prescription.orgId!.trim().isNotEmpty) ...{
          'orgId': prescription.orgId!.trim(),
          'organizationId': prescription.orgId!.trim(),
          'OrganizationId': prescription.orgId!.trim(),
        },
        'notes': prescription.additionalNotes,
        'diagnoses': prescription.diagnoses,
        'medications': prescription.medications.map((m) {
          int durationVal = 7;
          if (m.duration != null && m.duration!.isNotEmpty) {
            final match = RegExp(r'(\d+)').firstMatch(m.duration!);
            if (match != null) {
              durationVal = int.tryParse(match.group(1)!) ?? 7;
            }
          }
          return {
            'medication': m.name,
            'dosage': m.dosage ?? '',
            'frequency': m.frequency ?? '',
            'durationValue': durationVal,
            'durationUnit': 'Days',
            'route': m.route ?? '',
          };
        }).toList(),
      };

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.prescriptionsUrl,
        data: payload,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Server returned status code ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      developer.log(
        "Prescription save API call error",
        error: e,
        stackTrace: stackTrace,
        name: "PrescriptionRepositoryImpl",
      );
      rethrow;
    }
  }
}
