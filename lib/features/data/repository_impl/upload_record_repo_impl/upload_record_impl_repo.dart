


import '../../../domain/entities/uploaded_record/uploaded_record_entity.dart';
import '../../../domain/repositories/uploaded_record/uploaded_record_repo.dart';

class RecordsRepositoryImpl implements RecordsRepository {
  final List<UploadedRecord> _mockRecords = [
    UploadedRecord(id: '1', fileName: 'Health.png', category: 'Appointments', uploadDate: DateTime(2026, 5, 28), fileSizeKB: 222222),
    UploadedRecord(id: '2', fileName: 'Medication Medication Medication Medication.png', category: 'Appointments', uploadDate: DateTime(2026, 5, 28), fileSizeKB: 189),
    UploadedRecord(id: '3', fileName: 'Prescription.png', category: 'General', uploadDate: DateTime(2026, 5, 28), fileSizeKB: 617),
    UploadedRecord(id: '4', fileName: 'Food.png', category: 'General', uploadDate: DateTime(2026, 5, 28), fileSizeKB: 644),
    UploadedRecord(id: '5', fileName: 'Diet.png', category: 'Self(Patient)', uploadDate: DateTime(2026, 5, 28), fileSizeKB: 241),
  ];

  @override
  Future<List<UploadedRecord>> getUploadedRecords() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_mockRecords);
  }

  @override
  Future<void> deleteUploadedRecord(String id) async {
    _mockRecords.removeWhere((element) => element.id == id);
  }
}