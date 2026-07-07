import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/side_menu/side_menu_entity.dart';
import 'package:yiraclinics/features/domain/repositories/side_menu/side_menu_repo.dart';

class SideMenuRequestParams {
  final String userId;
  final String latestRoleId;
  final int latestOrgId;
  final int latestHospitalId;

  const SideMenuRequestParams({
    required this.userId,
    required this.latestRoleId,
    required this.latestOrgId,
    required this.latestHospitalId,
  });
}

class SideMenuUseCase
    implements UseCase<SideMenuEntity?, SideMenuRequestParams> {
  final SideMenuRepo sideMenuRepo;

  SideMenuUseCase(this.sideMenuRepo);
  @override
  Future<SideMenuEntity?> call(SideMenuRequestParams params) {
    return sideMenuRepo.fetchData(
      userId: params.userId,
      latestRoleId: params.latestRoleId,
      latestOrgId: params.latestOrgId,
      latestHospitalId: params.latestHospitalId,
    );
  }
}
