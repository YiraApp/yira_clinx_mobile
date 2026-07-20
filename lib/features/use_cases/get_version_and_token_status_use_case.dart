import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/token/get_version_and_token_status_entity.dart';
import 'package:yiraclinics/features/domain/repositories/token/get_version_and_token_status_repo.dart';

class GetVersionAndTokenStatusUseCase
    implements UseCase<VersionTokenStatusEntity?, void> {
  final GetVersionAndTokenStatusRepo repository;

  GetVersionAndTokenStatusUseCase({required this.repository});

  @override
  Future<VersionTokenStatusEntity?> call(void params) async {
    return await repository.getVersionAndTokenStatus();
  }
}
