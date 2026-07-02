import 'package:yiraclinics/features/domain/entities/forget_password/forget_password_send_otp_entity.dart';

abstract class ForgetPasswordSendOtpRepo {
  Future<ForgetPasswordSendOtpEntity?> sendOtp({
    required String identity,
    required String contactType,
    required String countryCode,
    required bool isResend,
  });
}
