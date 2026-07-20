import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/over_view/over_view_entity.dart';
import 'package:yiraclinics/features/domain/repositories/patient_over_view_repo/patient_over_view_repo.dart';

class PatientOverViewUseCase
    implements UseCase<PatientOverViewEntity?, String> {
  final PatientOverViewRepo patientOverViewRepo;

  PatientOverViewUseCase(this.patientOverViewRepo);
  @override
  Future<PatientOverViewEntity?> call(String userId) {
    return patientOverViewRepo.fetchOverViewData(userId: userId);
  }
}
