import '../../entities/uploaded_record/uploaded_record_entity.dart';

abstract class RecordsRepository {
  Future<List<UploadedRecord>> getUploadedRecords();
  Future<void> deleteUploadedRecord(String id);
}