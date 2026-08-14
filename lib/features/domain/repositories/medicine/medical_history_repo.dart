import '../../entities/medicine/medical_history_entity.dart';

abstract class MedicalHistoryRepository {
  Future<List<MedicalRecordBriefEntity>> fetchMedicalRecords({
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  });
  Future<void> createMedicalRecord(Map<String, dynamic> data);
  Future<void> updateMedicalRecord(String id, Map<String, dynamic> data);
  Future<void> deleteMedicalRecord(String id);
}