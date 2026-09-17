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

      final savedEntity = await repository.savePrescription(prescription);

      if (savedEntity.pdfUrl != null && savedEntity.pdfUrl!.isNotEmpty) {
        return savedEntity;
      }

      final updatedEntity = await repository.getPrescriptionByPatientId(
        prescription.patientId,
        appointmentId: prescription.appointmentId,
        hospitalId: prescription.hospitalId,
        orgId: prescription.orgId,
      );

      return updatedEntity.copyWith(
        pdfUrl: updatedEntity.pdfUrl ?? savedEntity.pdfUrl,
        id: updatedEntity.id ?? savedEntity.id,
      );
    } catch (e) {
      rethrow;
    }
  }
}
