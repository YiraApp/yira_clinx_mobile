

import '../package/domain/plat_form_info_entity.dart';
import '../package/domain/plat_form_info_repo.dart';

class GetPlatformInfoUseCase {
  final PlatformInfoRepo repository;

  GetPlatformInfoUseCase(this.repository);

  Future<PlatformInfoEntity> call() async {
    return await repository.getUnifiedMetadata();
  }
}