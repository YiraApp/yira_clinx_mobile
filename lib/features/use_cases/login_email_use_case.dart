
import 'package:equatable/equatable.dart';

import '../../core/use_case/use_case.dart';
import '../domain/entities/login/login_entity.dart';
import '../domain/repositories/login/login_repo.dart';

class LoginEmailUseCase implements UseCase<LoginEntity?, LoginWithEmailParams> {
  final LoginRepository _repository;

  const LoginEmailUseCase({required LoginRepository repository}) : _repository = repository;

  @override
  Future<LoginEntity?> call(LoginWithEmailParams params) async {
    return await _repository.loginWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginWithEmailParams extends Equatable {
  final String email;
  final String password;

  const LoginWithEmailParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}