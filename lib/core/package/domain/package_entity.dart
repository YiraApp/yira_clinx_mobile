import 'package:flutter/foundation.dart' show immutable;

@immutable
class PackageEntity {
  final String version;
  final String buildNumber;
  final String appName;

  const PackageEntity({
    required this.version,
    required this.buildNumber,
    required this.appName,
  });

  String get displayVersion => 'V:$version ($buildNumber)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PackageEntity &&
        other.version == version &&
        other.buildNumber == buildNumber &&
        other.appName == appName;
  }

  @override
  int get hashCode => Object.hash(version, buildNumber, appName);
}