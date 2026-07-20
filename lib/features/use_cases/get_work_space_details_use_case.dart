import 'package:yiraclinics/features/domain/entities/work_space/get_work_space_entity.dart';
import 'package:yiraclinics/features/domain/repositories/work_space/get_work_space_details_repo.dart';

import '../../core/use_case/use_case.dart';

class WorkSpaceParameters {
  String? userId;
  String? roleId;
  WorkSpaceParameters(this.userId,this.roleId);
}

class GetWorkSpaceDetailsUseCase implements UseCase<GetWorkSpaceDetailsEntity?, WorkSpaceParameters> {
  final GetWorkSpaceDetailsRepo getWorkSpaceDetailsRepo;

  GetWorkSpaceDetailsUseCase(this.getWorkSpaceDetailsRepo);

  @override
  Future<GetWorkSpaceDetailsEntity?> call(WorkSpaceParameters params) async {
    return await getWorkSpaceDetailsRepo.getWorkSpaceDetails(
      userId: params.userId ?? '',
      roleId: params.roleId ?? '',
    );
  }
}