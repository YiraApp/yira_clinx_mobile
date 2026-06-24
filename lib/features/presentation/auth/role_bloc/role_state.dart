part of 'role_bloc.dart';

@immutable

abstract class RoleState {
  const RoleState();
}

class RoleInitial extends RoleState {}
class RoleSelectedState extends RoleState {}

class RoleLoading extends RoleState {}

class RolesLoaded extends RoleState {
  final List<RoleLoginEntity> roles;
  final RoleType? selectedRole;

  const RolesLoaded({required this.roles, this.selectedRole});

  RolesLoaded copyWith({List<RoleLoginEntity>? roles, RoleType? selectedRole}) {
    return RolesLoaded(
      roles: roles ?? this.roles,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

class RoleSelectionSuccess extends RoleState {
  final RoleType roleType;
  const RoleSelectionSuccess(this.roleType);
}
