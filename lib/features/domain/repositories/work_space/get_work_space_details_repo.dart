
import 'package:yiraclinics/features/domain/entities/work_space/get_work_space_entity.dart';

abstract class GetWorkSpaceDetailsRepo {
  Future<GetWorkSpaceDetailsEntity?> getWorkSpaceDetails({
    required String userId,
    required String roleId
  });
}
