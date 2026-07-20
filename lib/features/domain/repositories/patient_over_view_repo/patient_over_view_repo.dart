
import 'package:yiraclinics/features/domain/entities/over_view/over_view_entity.dart';

abstract class PatientOverViewRepo {
  Future<PatientOverViewEntity?> fetchOverViewData({
    required String userId,
  });

  Future<PatientOverViewEntity?> fetchOverViewDirectFromKey(String cacheKey);
}