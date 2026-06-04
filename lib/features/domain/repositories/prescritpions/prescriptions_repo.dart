
import '../../entities/prescriptions/prescription_entity.dart';

abstract class PrescriptionRepository {
  Future<PrescriptionEntity> getPrescriptionByPatientId(String patientId);

  Future<void> savePrescription(PrescriptionEntity prescription);
}