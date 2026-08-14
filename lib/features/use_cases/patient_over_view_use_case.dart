import 'package:yiraclinics/features/domain/entities/over_view/over_view_entity.dart';
import 'package:yiraclinics/features/domain/repositories/patient_over_view_repo/patient_over_view_repo.dart';

class PatientOverViewUseCase {
  final PatientOverViewRepo patientOverViewRepo;

  PatientOverViewUseCase(this.patientOverViewRepo);

  Future<PatientOverViewEntity?> call(
    String userId, {
    String? orgId,
    String? hospitalId,
  }) {
    return patientOverViewRepo.fetchOverViewData(
      userId: userId,
      orgId: orgId,
      hospitalId: hospitalId,
    );
  }
}
