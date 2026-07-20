
import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_clinical_notes_entity.dart';
import 'package:yiraclinics/features/domain/repositories/dash_board/dashboard_patient_clinical_notes_repo.dart';

class DashboardPatientClinicalNotesUseCase implements UseCase<DashBoardPatientDetailsClinicalNotesEntity?, String> {
 final DashboardPatientClinicalNotesRepo dashboardPatientClinicalNotesRepo;

  DashboardPatientClinicalNotesUseCase(this.dashboardPatientClinicalNotesRepo);

  @override
  Future<DashBoardPatientDetailsClinicalNotesEntity?> call(String appointmentId) {
    return dashboardPatientClinicalNotesRepo.fetchPatientClinicalData(appointmentId: appointmentId);
  }
}