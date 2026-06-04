import '../../../domain/entities/prescriptions/prescription_entity.dart';
import '../../../domain/repositories/prescritpions/prescriptions_repo.dart';
import '../../models/prescriptions/prescriptions_model.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  PrescriptionRepositoryImpl();

  @override
  Future<PrescriptionEntity> getPrescriptionByPatientId(
    String patientId,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final mockJsonResponse = {
        'patient_id': patientId,
        'diagnoses': ['Hypermetropia', 'Axial hypermetropia'],
        'medications': [
          {
            'id': '1',
            'name': 'Acetaminophen-containing product',
            'dosage': '500mg',
            'frequency': 'Once daily (OD)',
            'duration': '7 Days',
            'route': 'Oral',
          },
          {
            'id': '2',
            'name': 'Acetaminophen-containing product',
            'dosage': null,
            'frequency': null,
            'duration': null,
            'route': null,
          },
        ],
        'additional_notes': '',
      };

      return PrescriptionModel.fromJson(mockJsonResponse);
    } catch (e) {
      throw Exception('Failed to load prescription infrastructure: $e');
    }
  }

  @override
  Future<void> savePrescription(PrescriptionEntity prescription) async {
    try {
      // Map domain entity downstream back into JSON payload for transportation formats
      final model = PrescriptionModel(
        patientId: prescription.patientId,
        diagnoses: prescription.diagnoses,
        medications: prescription.medications,
        additionalNotes: prescription.additionalNotes,
      );

      final payload = model.toJson();
      // await remoteDataSource.uploadPrescription(payload);

      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      throw Exception('Failed to export state parameters: $e');
    }
  }
}
