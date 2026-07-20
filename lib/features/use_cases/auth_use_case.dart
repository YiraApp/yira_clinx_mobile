

import '../domain/entities/login/login_entity.dart';
import '../domain/repositories/auth/auth_repo.dart';

class AuthUseCase {
  final AuthRepository repository;
  AuthUseCase(this.repository);

  bool execute() => repository.isUserLoggedIn();
  Future<LoginEntity?> localData()=> repository.localDataCatch();
}