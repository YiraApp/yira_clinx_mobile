import '../../features/domain/entities/login/login_entity.dart';

class SelectRoleModel {
  final List<RoleEntity> roles;
  final bool inApp;
  final List<ProfileEntity>? profiles;

  SelectRoleModel(this.roles, this.inApp, {this.profiles});
}