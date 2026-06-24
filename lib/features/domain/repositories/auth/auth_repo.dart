
import '../../entities/login/login_entity.dart';

abstract class AuthRepository {
  bool isUserLoggedIn();
  Future<LoginEntity?> localDataCatch();
}