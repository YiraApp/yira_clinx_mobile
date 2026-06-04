import '../domain/entities/prescriptions/prescription_entity.dart';
import '../domain/repositories/prescritpions/prescriptions_repo.dart';

class SavePrescriptionUseCase {
  final PrescriptionRepository repository;

  const SavePrescriptionUseCase(this.repository);

  Future<PrescriptionEntity> call(PrescriptionEntity prescription) async {
    try {
      if (prescription.patientId.trim().isEmpty) {
        throw Exception(
          'Cannot process a prescription without a valid Patient ID.',
        );
      }

      await repository.savePrescription(prescription);

      final updatedEntity = await repository.getPrescriptionByPatientId(
        prescription.patientId,
      );

      return updatedEntity;
    } catch (e) {
      rethrow;
    }
  }
}
