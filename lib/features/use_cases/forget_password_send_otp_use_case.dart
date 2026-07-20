import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/forget_password/forget_password_send_otp_entity.dart';
import 'package:yiraclinics/features/domain/repositories/foget_password/forget_password_send_otp_repo.dart';

class ForgetPasswordSendOtpUseCase
    implements
        UseCase<ForgetPasswordSendOtpEntity?, ForgetPasswordSendOtpParams> {
  final ForgetPasswordSendOtpRepo forgetPasswordSendOtpRepo;

  ForgetPasswordSendOtpUseCase(this.forgetPasswordSendOtpRepo);

  @override
  Future<ForgetPasswordSendOtpEntity?> call(
    ForgetPasswordSendOtpParams params,
  ) {
    return forgetPasswordSendOtpRepo.sendOtp(
      identity: params.identity ?? '',
      contactType: params.contactType ?? '',
      countryCode: params.countryCode ?? '',
      isResend: params.isResend ?? false,
    );
  }
}

class ForgetPasswordSendOtpParams {
  String? identity;
  String? contactType;
  String? countryCode;
  bool? isResend;

  ForgetPasswordSendOtpParams({
    this.identity,
    this.contactType,
    this.countryCode,
    this.isResend,
  });
}
