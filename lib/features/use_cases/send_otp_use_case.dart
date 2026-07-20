
import '../domain/entities/send_otp/send_otp_entity.dart';
import '../domain/repositories/send_otp/send_otp_repo.dart';
class SendOtpUseCase {
  final SendOtpRepo _repository;

  const SendOtpUseCase({required SendOtpRepo repository})
      : _repository = repository;
  Future<SendOtpEntity?> call({
    required String mobileNumber,
    required String countryCode,
    required bool isReSend
  }) async {
    if (mobileNumber.trim().isEmpty || countryCode.trim().isEmpty) {
      return null;
    }

    return await _repository.sendOtp(
      mobileNumber: mobileNumber.trim(),
      countryCode: countryCode.trim(), isReSend: isReSend,
    );
  }
}