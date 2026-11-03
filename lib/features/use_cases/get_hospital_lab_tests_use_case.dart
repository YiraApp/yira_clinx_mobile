import '../domain/entities/prescriptions/lab_test_entity.dart';
import '../domain/repositories/prescritpions/prescriptions_repo.dart';

class GetHospitalLabTestsUseCase {
  final PrescriptionRepository repository;

  const GetHospitalLabTestsUseCase(this.repository);

  Future<List<HospitalLabTest>> call(String hospitalId) => repository.getHospitalLabTests(hospitalId);
}
