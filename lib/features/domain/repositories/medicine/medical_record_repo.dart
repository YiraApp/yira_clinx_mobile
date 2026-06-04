

import '../../entities/medicine/medical_record_entity.dart';

abstract class MedicalRecordRepository {
  Future<void> createMedicalRecord(MedicalRecordEntity record);
}