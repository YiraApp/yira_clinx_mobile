import '../../features/domain/entities/login/login_entity.dart';

class SelectRoleModel {
  final List<RoleEntity> roles;
  final bool inApp;

  SelectRoleModel(this.roles, this.inApp);
}