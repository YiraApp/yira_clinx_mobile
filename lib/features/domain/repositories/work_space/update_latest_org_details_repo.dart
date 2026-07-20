

import '../../entities/work_space/update_latest_org_details_entity.dart';

abstract class UpdateLatestOrgDetailsRepo {
  Future<UpdateLatestOrgDetailsEntity?> updateLatestOrgDetails({
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId
  });
}
