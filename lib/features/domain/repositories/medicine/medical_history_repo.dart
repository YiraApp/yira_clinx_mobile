import '../../entities/medicine/medical_history_entity.dart';

abstract class MedicalHistoryRepository {
  Future<List<MedicalRecordBriefEntity>> fetchMedicalRecords({
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  });
  /// Saves a new record and returns its id (null when the server didn't send one).
  Future<String?> createMedicalRecord(Map<String, dynamic> data);
  Future<void> updateMedicalRecord(String id, Map<String, dynamic> data);
  Future<void> deleteMedicalRecord(String id);
}