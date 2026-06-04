import '../../entities/medicine/medical_history_entity.dart';

abstract class MedicalHistoryRepository {
  Future<List<MedicalRecordBriefEntity>> fetchMedicalRecords();
  Future<void> deleteMedicalRecord(String id);
}