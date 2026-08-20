import 'package:yiraclinics/features/domain/entities/consent/patient_access_consent_entity.dart';

abstract class PatientAccessConsentRepository {
  Future<PatientAccessConsentEntity> requestAccess({
    required String patientId,
    required String doctorId,
    int? hospitalId,
    required String duration,
    String? notes,
  });

  Future<ConsentAccessCheckEntity> checkAccess({
    required String patientId,
    required String doctorId,
  });

  Future<List<PatientAccessConsentEntity>> getPatientConsents({
    required String patientId,
  });

  Future<PatientAccessConsentEntity> respondToConsent({
    required int consentId,
    required String action, // 'APPROVE', 'REJECT', 'REVOKE'
  });
}
