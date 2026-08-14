import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_details_entity.dart';
import 'package:yiraclinics/features/domain/repositories/dash_board/dashboard_patient_details_repo.dart';

class PatientDetailsParams {
  final String appointmentId;
  final String patientId;
  final String orgId;
  final String hospitalId;

  PatientDetailsParams({
    required this.appointmentId,
    required this.patientId,
    required this.orgId,
    required this.hospitalId,
  });
}

class DashboardPatientDetailsUseCase
    implements UseCase<DashBoardPatientDetailsEntity?, PatientDetailsParams> {
  final DashboardPatientDetailsRepo dashboardPatientDetailsRepo;

  DashboardPatientDetailsUseCase(this.dashboardPatientDetailsRepo);
  @override
  Future<DashBoardPatientDetailsEntity?> call(PatientDetailsParams params) {
    return dashboardPatientDetailsRepo.fetchPatientData(
      appointmentId: params.appointmentId,
      patientId: params.patientId,
      orgId: params.orgId,
      hospitalId: params.hospitalId,
    );
  }
}
