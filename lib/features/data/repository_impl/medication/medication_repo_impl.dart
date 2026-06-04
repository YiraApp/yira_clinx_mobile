import 'package:yiraclinics/features/domain/entities/medication/medication_entity.dart';

import '../../../domain/repositories/medication/medication_repository.dart';
import '../../models/medicaiton/medication_model.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  @override
  Future<MedicationEntity> getMedicationSummary() async {
    // Mocking API call
    await Future.delayed(const Duration(seconds: 1));
    return const MedicationSummaryModel(
      totalPrescriptions: 4,
      activeMeds: 6,
      totalMedications: 8,
      needRefill: 2,
    );
  }
}