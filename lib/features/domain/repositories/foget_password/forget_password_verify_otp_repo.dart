

import '../../entities/forget_password/forget_password_verify_otp_enity.dart';

abstract class ForgetPasswordVerifyOtpRepo {
  Future<ForgetPasswordVerifyOtpEntity?> verifyOtp({
    required String identity,
    required String contactType,
    required String countryCode,
    required String sessionId,
    required String otp,
  });
}
