
import 'package:yiraclinics/features/domain/entities/side_menu/side_menu_entity.dart';

abstract class SideMenuRepo {
  Future<SideMenuEntity?> fetchData({
    required String userId,
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId,
  });

  Future<SideMenuEntity?> fetchDirectFromKey(String cacheKey);
}