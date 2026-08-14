
import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_clinical_notes_entity.dart';
import 'package:yiraclinics/features/domain/repositories/dash_board/dashboard_patient_clinical_notes_repo.dart';

import 'package:yiraclinics/features/use_cases/dashboard_patient_details_use_case.dart';

class DashboardPatientClinicalNotesUseCase implements UseCase<DashBoardPatientDetailsClinicalNotesEntity?, PatientDetailsParams> {
 final DashboardPatientClinicalNotesRepo dashboardPatientClinicalNotesRepo;

  DashboardPatientClinicalNotesUseCase(this.dashboardPatientClinicalNotesRepo);

  @override
  Future<DashBoardPatientDetailsClinicalNotesEntity?> call(PatientDetailsParams params) {
    return dashboardPatientClinicalNotesRepo.fetchPatientClinicalData(
      appointmentId: params.appointmentId,
      patientId: params.patientId,
      orgId: params.orgId,
      hospitalId: params.hospitalId,
    );
  }
}