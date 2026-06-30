import 'package:flutter/foundation.dart' show immutable;

@immutable
class PlatformInfoEntity {
  final String deviceId;
  final String platform;
  final String version;
  final String buildNumber;
  final String appName;

  const PlatformInfoEntity({
    required this.deviceId,
    required this.platform,
    required this.version,
    required this.buildNumber,
    required this.appName,
  });

  String get displayVersion => 'V:$version ($buildNumber) on $platform';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlatformInfoEntity &&
        other.deviceId == deviceId &&
        other.platform == platform &&
        other.version == version &&
        other.buildNumber == buildNumber &&
        other.appName == appName;
  }

  @override
  int get hashCode => Object.hash(deviceId, platform, version, buildNumber, appName);
}