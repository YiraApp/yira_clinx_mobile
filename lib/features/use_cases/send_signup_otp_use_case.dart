import '../domain/entities/send_otp/send_otp_entity.dart';
import '../domain/repositories/send_otp/send_otp_repo.dart';

class SendSignupOtpUseCase {
  final SendOtpRepo _repository;

  const SendSignupOtpUseCase({required SendOtpRepo repository})
      : _repository = repository;

  Future<SendOtpEntity?> call({
    required String mobileNumber,
    required String countryCode,
    String? email,
  }) async {
    if (mobileNumber.trim().isEmpty || countryCode.trim().isEmpty) {
      return null;
    }

    return await _repository.sendSignupOtp(
      mobileNumber: mobileNumber.trim(),
      countryCode: countryCode.trim(),
      email: email?.trim(),
    );
  }
}
