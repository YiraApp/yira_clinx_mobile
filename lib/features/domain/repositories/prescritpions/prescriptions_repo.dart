import '../../entities/prescriptions/prescription_entity.dart';

abstract class PrescriptionRepository {
  Future<PrescriptionEntity> getPrescriptionByPatientId(
    String patientId, {
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  });

  Future<PrescriptionEntity> savePrescription(PrescriptionEntity prescription);
}