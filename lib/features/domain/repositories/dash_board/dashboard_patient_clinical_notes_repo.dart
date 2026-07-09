import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_clinical_notes_entity.dart';

abstract class DashboardPatientClinicalNotesRepo {
  Future<DashBoardPatientDetailsClinicalNotesEntity?> fetchPatientClinicalData({
    required String appointmentId,
  });
  Future<DashBoardPatientDetailsClinicalNotesEntity?> fetchPatientClinicalDataDirectFromKey(String cacheKey);
}
