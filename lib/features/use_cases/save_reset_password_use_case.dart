import 'package:yiraclinics/core/use_case/use_case.dart';
import 'package:yiraclinics/features/domain/entities/common/common_entity.dart';
import 'package:yiraclinics/features/domain/repositories/foget_password/save_reset_password_repo.dart';

class SaveResetPasswordUseCase
    implements UseCase<CommonEntity?, SaveResetPasswordParams> {
  final SaveResetPasswordRepo saveResetPasswordRepo;

  SaveResetPasswordUseCase(this.saveResetPasswordRepo);

  @override
  Future<CommonEntity?> call(SaveResetPasswordParams params) {
    return saveResetPasswordRepo.savePassword(
      identity: params.identity ?? '',
      contactType: params.contactType ?? '',
      countryCode: params.countryCode ?? '',
      newPassword: params.newPassword ?? '',
      confirmPassword: params.confirmPassword ?? '',
    );
  }
}

class SaveResetPasswordParams {
  String? identity;
  String? contactType;
  String? countryCode;
  String? newPassword;
  String? confirmPassword;

  SaveResetPasswordParams({
    this.identity,
    this.contactType,
    this.countryCode,
    this.newPassword,
    this.confirmPassword,
  });
}
