import 'package:yiraclinics/features/domain/repositories/configuration/configuration_repo.dart';

import '../../core/use_case/use_case.dart';
import '../domain/entities/login/login_entity.dart';

class ConfigUseCase implements UseCase<LoginEntity?, void> {
  final ConfigurationRepo configurationRepo;

  const ConfigUseCase({required ConfigurationRepo repository})
    : configurationRepo = repository;

  @override
  Future<LoginEntity?> call(void _) {
    return configurationRepo.getUserData();
  }
}
