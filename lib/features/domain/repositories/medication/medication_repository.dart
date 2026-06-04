

import 'package:yiraclinics/features/domain/entities/medication/medication_entity.dart';

abstract class MedicationRepository {
  Future<MedicationEntity> getMedicationSummary();
}