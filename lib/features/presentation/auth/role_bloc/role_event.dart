part of 'role_bloc.dart';

@immutable
abstract class RoleEvent {
  const RoleEvent();
}

class LoadRolesEvent extends RoleEvent {}
class RoleSelected extends RoleEvent {}
class ChooseRoleEvent extends RoleEvent {
  final RoleType selectedRole;
  const ChooseRoleEvent(this.selectedRole);
}
