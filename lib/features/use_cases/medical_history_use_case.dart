

import '../domain/entities/medicine/medical_history_entity.dart';
import '../domain/repositories/medicine/medical_history_repo.dart';

class GetMedicalRecordsUseCase {
  final MedicalHistoryRepository repository;

  GetMedicalRecordsUseCase(this.repository);

  Future<List<MedicalRecordBriefEntity>> call() async {
    return await repository.fetchMedicalRecords();
  }
}