import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';
import 'package:yiraclinics/features/domain/repositories/provider_profile/provider_profile_repo.dart';

class GetProviderProfileUseCase {
  final ProviderProfileRepo repository;

  GetProviderProfileUseCase({required this.repository});

  Future<ProviderProfileEntity> call({
    required String userId,
    int? hospitalId,
    int? orgId,
  }) async {
    return await repository.getProviderProfile(
      userId: userId,
      hospitalId: hospitalId,
      orgId: orgId,
    );
  }
}
