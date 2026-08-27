import '../domain/entities/login/login_entity.dart';
import '../domain/entities/send_otp/send_otp_entity.dart';
import '../domain/repositories/login/login_repo.dart';

class SendSignupOtpUseCase {
  final LoginRepository repository;

  SendSignupOtpUseCase({required this.repository});

  Future<SendOtpEntity?> call({
    required String mobileNumber,
    String? countryCode,
  }) async {
    return await repository.sendSignupOtp(
      mobileNumber: mobileNumber,
      countryCode: countryCode,
    );
  }
}

class RegisterPatientUseCase {
  final LoginRepository repository;

  RegisterPatientUseCase({required this.repository});

  Future<LoginEntity?> call({
    required String mobileNumber,
    required String firstName,
    required String lastName,
    String? email,
    required String password,
    required String otp,
    required String sessionId,
    String? countryCode,
    String? profileImagePath,
  }) async {
    return await repository.registerPatient(
      mobileNumber: mobileNumber,
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      otp: otp,
      sessionId: sessionId,
      countryCode: countryCode,
      profileImagePath: profileImagePath,
    );
  }
}
