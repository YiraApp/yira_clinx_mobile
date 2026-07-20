import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/doctor_dashboard_entity.dart';
import 'package:yiraclinics/features/domain/repositories/dash_board/doctor_dashboard_repo.dart';

class UpdateLatestDetailsRequest {
  final String userId;
  final String latestRoleId;
  final int latestOrgId;
  final int latestHospitalId;

  const UpdateLatestDetailsRequest({
    required this.userId,
    required this.latestRoleId,
    required this.latestOrgId,
    required this.latestHospitalId,
  });
}

class DoctorDashboardUseCase
    implements UseCase<DoctorDashboardEntity?, UpdateLatestDetailsRequest> {
  final DoctorDashboardRepo dashBoardRepo;

  DoctorDashboardUseCase(this.dashBoardRepo);
  @override
  Future<DoctorDashboardEntity?> call(UpdateLatestDetailsRequest params) {
    return dashBoardRepo.fetchData(
      userId: params.userId,
      latestRoleId: params.latestRoleId,
      latestOrgId: params.latestOrgId,
      latestHospitalId: params.latestHospitalId,
    );
  }
}
