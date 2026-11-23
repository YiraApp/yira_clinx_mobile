import 'dart:typed_data';

import '../../entities/prescriptions/lab_test_entity.dart';
import '../../entities/prescriptions/prescription_entity.dart';

abstract class PrescriptionRepository {
  Future<PrescriptionEntity> getPrescriptionByPatientId(
    String patientId, {
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  });

  Future<PrescriptionEntity> savePrescription(PrescriptionEntity prescription);

  /// The PDF [prescription] would get, drawn by the server without saving anything.
  Future<Uint8List> previewPrescription(PrescriptionEntity prescription);

  /// The hospital's active lab tests. Throws when they cannot be loaded.
  Future<List<HospitalLabTest>> getHospitalLabTests(String hospitalId);
}