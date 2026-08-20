import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';
import 'package:yiraclinics/features/domain/repositories/provider_profile/provider_profile_repo.dart';

class UpdateProviderProfileUseCase {
  final ProviderProfileRepo repository;

  UpdateProviderProfileUseCase({required this.repository});

  Future<ProviderProfileEntity> call({
    required ProviderProfileEntity profile,
  }) async {
    return await repository.updateProviderProfile(profile: profile);
  }
}
