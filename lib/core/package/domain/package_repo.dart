

import 'package:yiraclinics/core/package/domain/package_entity.dart';

abstract class PackageRepo {
  Future<PackageEntity> getAppVersionInfo();
}