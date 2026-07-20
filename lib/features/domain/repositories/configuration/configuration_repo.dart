

import '../../entities/login/login_entity.dart';

abstract class ConfigurationRepo {
  Future<LoginEntity?> getUserData();
}