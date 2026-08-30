import '../../entities/uploaded_record/uploaded_record_entity.dart';

abstract class RecordsRepository {
  Future<List<UploadedRecord>> getUploadedRecords({
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
    int? limit,
    int? page,
  });

  Future<UploadedRecord?> uploadDocument({
    required String filePath,
    required String fileName,
    required String category,
    String? description,
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  });

  Future<void> deleteUploadedRecord(String id);
}