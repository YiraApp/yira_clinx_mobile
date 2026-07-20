
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/package/data/plat_form_info_model.dart';

import '../domain/plat_form_info_entity.dart';
import '../domain/plat_form_info_repo.dart';



class PlatformInfoRepoImpl implements PlatformInfoRepo {
  const PlatformInfoRepoImpl();

  @override
  Future<PlatformInfoEntity> getUnifiedMetadata() async {
    String targetDeviceId = 'unknown_id';
    String targetPlatform = 'Unknown';
    String targetVersion = '1.0.0';
    String targetBuildNum = '1';
    String targetAppName = projectTitle;

    try {
      final operations = await Future.wait([
        PackageInfo.fromPlatform(),
        _extractDeviceMetadata(),
      ]);

      final PackageInfo packageInfo = operations[0] as PackageInfo;
      final Map<String, String> deviceMeta = operations[1] as Map<String, String>;

      targetVersion = packageInfo.version;
      targetBuildNum = packageInfo.buildNumber;
      targetAppName = packageInfo.appName;
      targetDeviceId = deviceMeta['id'] ?? 'unknown_id';
      targetPlatform = deviceMeta['platform'] ?? 'Unknown';

    } on PlatformException catch (e, stack) {
      debugPrint("PlatformInfoRepoImpl - Channel Exception: $e\n$stack");
    } catch (e, stack) {
      debugPrint("PlatformInfoRepoImpl - Unexpected Parsing Error: $e\n$stack");
    }

    return PlatformInfoModel(
      deviceId: targetDeviceId,
      platform: targetPlatform,
      version: targetVersion,
      buildNumber: targetBuildNum,
      appName: targetAppName,
    );
  }

  Future<Map<String, String>> _extractDeviceMetadata() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    if (kIsWeb) {
      final webInfo = await deviceInfoPlugin.webBrowserInfo;
      return {
        'id': '${webInfo.vendor ?? 'web'}-${webInfo.productSub ?? 'browser'}',
        'platform': 'Web',
      };
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return {
        'id': androidInfo.id.isNotEmpty ? androidInfo.id : 'unknown_android_id',
        'platform': 'Android',
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return {
        'id': iosInfo.identifierForVendor ?? 'unknown_ios_id',
        'platform': 'iOS',
      };
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfoPlugin.macOsInfo;
      return {
        'id': macInfo.systemGUID ?? 'unknown_mac_id',
        'platform': 'macOS',
      };
    }

    return {'id': 'unknown_id', 'platform': 'Unknown'};
  }
}