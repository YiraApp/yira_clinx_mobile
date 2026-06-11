
import '../package/domain/package_entity.dart';
import '../package/domain/package_repo.dart';

class GetAppVersionInfoUseCase {
  final PackageRepo _packageRepo;

  const GetAppVersionInfoUseCase(this._packageRepo);

  Future<PackageEntity> call() async {
    return await _packageRepo.getAppVersionInfo();
  }
}