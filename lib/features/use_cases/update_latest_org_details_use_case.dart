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
      latestRoleId: params.latestRoleId ?? '1',
      latestOrgId: params.latestOrgId ?? 1,
      latestHospitalId: params.latestHospitalId ?? 1,
    );
  }
}

class UpdateLatestOrgDetailsModelParams {
  String latestRoleId;
  int latestOrgId;
  int latestHospitalId;
  UpdateLatestOrgDetailsModelParams({
    required this.latestRoleId,
    required this.latestOrgId,
    required this.latestHospitalId,
  });
}
