import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_details_entity.dart';
import 'package:yiraclinics/features/domain/repositories/dash_board/dashboard_patient_details_repo.dart';

class DashboardPatientDetailsUseCase
    implements UseCase<DashBoardPatientDetailsEntity?, String> {
  final DashboardPatientDetailsRepo dashboardPatientDetailsRepo;

  DashboardPatientDetailsUseCase(this.dashboardPatientDetailsRepo);
  @override
  Future<DashBoardPatientDetailsEntity?> call(String appointmentId) {
    return dashboardPatientDetailsRepo.fetchPatientData(
      appointmentId: appointmentId,
    );
  }
}
