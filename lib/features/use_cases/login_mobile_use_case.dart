
import 'package:equatable/equatable.dart';

import '../../core/use_case/use_case.dart';
import '../domain/entities/login/login_entity.dart';
import '../domain/repositories/login/login_repo.dart';

class LoginMobileUseCase implements UseCase<LoginEntity?, LoginWithMobileParams> {
  final LoginRepository _repository;

  const LoginMobileUseCase({required LoginRepository repository}) : _repository = repository;

  @override
  Future<LoginEntity?> call(LoginWithMobileParams params) async {
    return await _repository.loginWithMobile(
      mobileNumber: params.mobileNumber,
      otp: params.otp,
      sessionId: params.sessionId,
      countryCode: params.countryCode,
    );
  }
}

class LoginWithMobileParams extends Equatable {
  final String mobileNumber;
  final String otp;
  final String sessionId;
  final String? countryCode;

  const LoginWithMobileParams({
    required this.mobileNumber,
    required this.otp,
    required this.sessionId,
    this.countryCode,
  });

  @override
  List<Object?> get props => [mobileNumber, otp, sessionId, countryCode];
}