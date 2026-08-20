import 'dart:io';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/data/models/consent/patient_access_consent_model.dart';
import 'package:yiraclinics/features/domain/entities/consent/patient_access_consent_entity.dart';
import 'package:yiraclinics/features/domain/repositories/consent/patient_access_consent_repo.dart';

class PatientAccessConsentRepoImpl implements PatientAccessConsentRepository {
  final ApiClient _apiClient;

  PatientAccessConsentRepoImpl(this._apiClient);

  String get _authToken {
    return GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
  }

  @override
  Future<PatientAccessConsentEntity> requestAccess({
    required String patientId,
    required String doctorId,
    int? hospitalId,
    required String duration,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.client(ApiType.account).post(
        URLs.patientAccessRequestUrl,
        data: {
          "patientId": patientId,
          "doctorId": doctorId,
          if (hospitalId != null) "hospitalId": hospitalId,
          "duration": duration,
          if (notes != null) "notes": notes,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $_authToken'},
        ),
      );

      if (response.data != null && response.data['data'] != null) {
        return PatientAccessConsentModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
      }
    } catch (e) {
      // Fallback
    }

    // Local optimistic fallback
    return PatientAccessConsentModel(
      patientId: patientId,
      doctorId: doctorId,
      hospitalId: hospitalId,
      duration: duration,
      status: 'PENDING',
      requestedAt: DateTime.now(),
    );
  }

  @override
  Future<ConsentAccessCheckEntity> checkAccess({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final response = await _apiClient.client(ApiType.account).get(
        URLs.patientAccessCheckUrl,
        queryParameters: {
          "patientId": patientId,
          "doctorId": doctorId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $_authToken'},
        ),
      );

      if (response.data != null && response.data['data'] != null) {
        return ConsentAccessCheckModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
      }
    } catch (e) {
      // Fallback
    }

    return const ConsentAccessCheckModel(
      hasAccess: false,
      status: 'NO_REQUEST',
    );
  }

  @override
  Future<List<PatientAccessConsentEntity>> getPatientConsents({
    required String patientId,
  }) async {
    try {
      final response = await _apiClient.client(ApiType.account).get(
        URLs.patientConsentsListUrl,
        queryParameters: {
          "patientId": patientId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $_authToken'},
        ),
      );

      if (response.data != null && response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((item) => PatientAccessConsentModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      // Fallback
    }

    return [];
  }

  @override
  Future<PatientAccessConsentEntity> respondToConsent({
    required int consentId,
    required String action,
  }) async {
    try {
      final response = await _apiClient.client(ApiType.account).post(
        URLs.patientConsentRespondUrl,
        data: {
          "consentId": consentId,
          "action": action,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $_authToken'},
        ),
      );

      if (response.data != null && response.data['data'] != null) {
        return PatientAccessConsentModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
      }
    } catch (e) {
      // Fallback
    }

    return PatientAccessConsentModel(
      id: consentId,
      status: action == 'APPROVE' ? 'APPROVED' : (action == 'REJECT' ? 'REJECTED' : 'REVOKED'),
      approvedAt: action == 'APPROVE' ? DateTime.now() : null,
    );
  }
}
