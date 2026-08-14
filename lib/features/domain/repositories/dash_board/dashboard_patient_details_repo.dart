

import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_details_entity.dart';

abstract class DashboardPatientDetailsRepo {
  Future<DashBoardPatientDetailsEntity?> fetchPatientData({
    required String appointmentId,
    required String patientId,
    required String orgId,
    required String hospitalId,
  });
  Future<DashBoardPatientDetailsEntity?> fetchPatientDataDirectFromKey(String cacheKey);
}