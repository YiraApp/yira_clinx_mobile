import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../domain/package_entity.dart';
import '../domain/package_repo.dart';

class PackageRepoImpl implements PackageRepo {
  const PackageRepoImpl();

  @override
  Future<PackageEntity> getAppVersionInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();

      return PackageEntity(
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        appName: packageInfo.appName,
      );
    } on PlatformException catch (exception, stackTrace) {
      debugPrint("PackageRepoImpl - Native Platform Call Failed: $exception");
      debugPrint("StackTrace: $stackTrace");

      return const PackageEntity(
        version: "3.0.0",
        buildNumber: "1",
        appName: projectTitle,
      );
    } catch (error, stackTrace) {
      debugPrint("PackageRepoImpl - Unexpected Parsing Error: $error");
      debugPrint("StackTrace: $stackTrace");

      return const PackageEntity(
        version: "2.0.0",
        buildNumber: "1",
        appName: projectTitle,
      );
    }
  }
}