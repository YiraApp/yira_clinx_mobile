
import 'package:yiraclinics/core/package/domain/plat_form_info_entity.dart';


abstract class PlatformInfoRepo {
  Future<PlatformInfoEntity> getUnifiedMetadata();
}