import '../domain/entities/medicine/medical_history_entity.dart';
import '../domain/repositories/medicine/medical_history_repo.dart';

class GetMedicalRecordsUseCase {
  final MedicalHistoryRepository repository;

  GetMedicalRecordsUseCase(this.repository);

  Future<List<MedicalRecordBriefEntity>> call({
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  }) async {
    return await repository.fetchMedicalRecords(
      patientId: patientId,
      appointmentId: appointmentId,
      hospitalId: hospitalId,
      orgId: orgId,
    );
  }
}