import 'package:yiraclinics/features/domain/repositories/work_space/update_latest_org_details_repo.dart';

import '../../core/use_case/use_case.dart';
import '../domain/entities/work_space/update_latest_org_details_entity.dart';

class UpdateLatestOrgDetailsUseCase
    implements
        UseCase<
          UpdateLatestOrgDetailsEntity?,
          UpdateLatestOrgDetailsModelParams
        > {
  final UpdateLatestOrgDetailsRepo updateLatestOrgDetailsRepo;

  UpdateLatestOrgDetailsUseCase(this.updateLatestOrgDetailsRepo);
  @override
  Future<UpdateLatestOrgDetailsEntity?> call(
    UpdateLatestOrgDetailsModelParams params,
  ) {
    return updateLatestOrgDetailsRepo.updateLatestOrgDetails(
      userId: params.userId,
      latestRoleId: params.latestRoleId,
      latestOrgId: params.latestOrgId,
      latestHospitalId: params.latestHospitalId,
    );
  }
}

class UpdateLatestOrgDetailsModelParams {
  String? userId;
  String latestRoleId;
  int latestOrgId;
  int latestHospitalId;
  UpdateLatestOrgDetailsModelParams({
    this.userId,
    required this.latestRoleId,
    required this.latestOrgId,
    required this.latestHospitalId,
  });
}
