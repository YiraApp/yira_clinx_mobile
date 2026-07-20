import 'package:yiraclinics/features/domain/entities/dashboard/doctor_dashboard_entity.dart';

abstract class DoctorDashboardRepo {
  Future<DoctorDashboardEntity?> fetchData({
    required String userId,
    required String latestRoleId,
    required int latestOrgId,
    required int latestHospitalId,
  });

  Future<DoctorDashboardEntity?> fetchDirectFromKey(String cacheKey);
}