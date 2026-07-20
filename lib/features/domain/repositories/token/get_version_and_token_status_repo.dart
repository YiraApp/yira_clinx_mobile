
import 'package:yiraclinics/features/domain/entities/token/get_version_and_token_status_entity.dart';

abstract class GetVersionAndTokenStatusRepo {
  Future<VersionTokenStatusEntity?> getVersionAndTokenStatus();
}