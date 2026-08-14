import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_clinical_notes_entity.dart';

abstract class DashboardPatientClinicalNotesRepo {
  Future<DashBoardPatientDetailsClinicalNotesEntity?> fetchPatientClinicalData({
    required String appointmentId,
    required String patientId,
    required String orgId,
    required String hospitalId,
  });
  Future<DashBoardPatientDetailsClinicalNotesEntity?> fetchPatientClinicalDataDirectFromKey(String cacheKey);
}
