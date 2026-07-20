
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:yiraclinics/features/domain/entities/side_menu/side_menu_entity.dart';
import 'package:yiraclinics/features/domain/repositories/side_menu/side_menu_repo.dart';

class GlobalMenuSession {
  GlobalMenuSession._internal();
  static final GlobalMenuSession instance = GlobalMenuSession._internal();

  SideMenuEntity? _sideMenu;

  SideMenuEntity? get sideMenu => _sideMenu;

  final ValueNotifier<SideMenuEntity?> menuNotifier =
      ValueNotifier<SideMenuEntity?>(null);

  void updateMenu(SideMenuEntity? newMenu) {
    _sideMenu = newMenu;
    menuNotifier.value = newMenu;
    developer.log(
      "GlobalMenuSession cache updated cleanly.",
      name: "GlobalMenuSession",
    );
  }

  Future<void> initFromLocalCache({
    required SideMenuRepo repository,
    required String userId,
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId,
    required String sideMenuKeyPrefix,
    required String baseUrl,
  }) async {
    try {
      final params = {
        "userId": userId.trim(),
        "latestRoleId": latestRoleId.trim(),
        "latestOrgId": latestOrgId,
        "latestHospitalId": latestHospitalId,
      };

      final List<String> sortedKeys = params.keys.toList()..sort();
      final String queryString = sortedKeys
          .map((key) => "$key=${Uri.encodeComponent(params[key].toString())}")
          .join('&');

      final String fullCacheKey =
          "${sideMenuKeyPrefix.trim()}#$baseUrl?$queryString";

      developer.log(
        "Evaluating boot hydration with key: $fullCacheKey",
        name: "GlobalMenuSession",
      );

      final cachedData = await repository.fetchDirectFromKey(fullCacheKey);

      if (cachedData != null) {
        updateMenu(cachedData);
        developer.log(
          "Pre-hydration from secure local database successful.",
          name: "GlobalMenuSession",
        );
      } else {
        developer.log(
          "No valid side menu fallback record found for current session variables.",
          name: "GlobalMenuSession",
        );
      }
    } catch (cacheError, stackTrace) {
      developer.log(
        "Critical non-blocking exception handled inside pre-hydration sequence.",
        error: cacheError,
        stackTrace: stackTrace,
        name: "GlobalMenuSession",
      );
    }
  }

  void clear() {
    _sideMenu = null;
    menuNotifier.value = null;
    developer.log(
      "GlobalMenuSession data wiped successfully.",
      name: "GlobalMenuSession",
    );
  }
}
