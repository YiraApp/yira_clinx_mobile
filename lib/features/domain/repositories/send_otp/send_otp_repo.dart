

import '../../entities/send_otp/send_otp_entity.dart';

abstract class SendOtpRepo {
  Future<SendOtpEntity?> sendOtp({
    required String mobileNumber,
    required String countryCode,
    required bool isReSend,
  });

  Future<SendOtpEntity?> sendSignupOtp({
    required String mobileNumber,
    required String countryCode,
    String? email,
  });
}