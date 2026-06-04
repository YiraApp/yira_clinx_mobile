
import 'package:yiraclinics/features/domain/entities/medication/medication_entity.dart';

import '../domain/repositories/medication/medication_repository.dart';


class GetPrescriptionUseCase {
  final MedicationRepository repository;

  GetPrescriptionUseCase(this.repository);

  Future<MedicationEntity> call() async {
    return await repository.getMedicationSummary();
  }
}