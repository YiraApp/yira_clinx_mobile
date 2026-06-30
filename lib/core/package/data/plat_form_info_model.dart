import '../domain/plat_form_info_entity.dart';

class PlatformInfoModel extends PlatformInfoEntity {
  const PlatformInfoModel({
    required super.deviceId,
    required super.platform,
    required super.version,
    required super.buildNumber,
    required super.appName,
  });
}