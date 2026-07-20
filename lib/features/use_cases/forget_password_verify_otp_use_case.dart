import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/forget_password/forget_password_verify_otp_enity.dart';
import 'package:yiraclinics/features/domain/repositories/foget_password/forget_password_verify_otp_repo.dart';

class ForgetPasswordVerifyOtpUseCase
    implements
        UseCase<ForgetPasswordVerifyOtpEntity?, ForgetPasswordVerifyOtpParams> {
  final ForgetPasswordVerifyOtpRepo forgetPasswordVerifyOtpRepo;

  ForgetPasswordVerifyOtpUseCase(this.forgetPasswordVerifyOtpRepo);

  @override
  Future<ForgetPasswordVerifyOtpEntity?> call(
    ForgetPasswordVerifyOtpParams params,
  ) {
    return forgetPasswordVerifyOtpRepo.verifyOtp(
      identity: params.identity ?? '',
      contactType: params.contactType ?? '',
      countryCode: params.countryCode ?? '',
      sessionId: params.sessionId ?? '',
      otp: params.otp ?? '',
    );
  }
}

class ForgetPasswordVerifyOtpParams {
  String? identity;
  String? contactType;
  String? countryCode;
  String? sessionId;
  String? otp;

  ForgetPasswordVerifyOtpParams({
    this.identity,
    this.contactType,
    this.countryCode,
    this.sessionId,
    this.otp,
  });
}
