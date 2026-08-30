import '../domain/entities/login/login_entity.dart';
import '../domain/repositories/login/login_repo.dart';

class RegisterPatientParams {
  final String firstName;
  final String lastName;
  final String? email;
  final String mobileNumber;
  final String countryCode;
  final String password;
  final String otp;
  final String sessionId;

  const RegisterPatientParams({
    required this.firstName,
    required this.lastName,
    this.email,
    required this.mobileNumber,
    required this.countryCode,
    required this.password,
    required this.otp,
    required this.sessionId,
  });
}

class RegisterPatientUseCase {
  final LoginRepository _repository;

  const RegisterPatientUseCase(this._repository);

  Future<LoginEntity?> call(RegisterPatientParams params) async {
    return await _repository.registerPatient(
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      mobileNumber: params.mobileNumber,
      countryCode: params.countryCode,
      password: params.password,
      otp: params.otp,
      sessionId: params.sessionId,
    );
  }
}
