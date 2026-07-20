part of 'permission_bloc.dart';

@immutable
abstract class PermissionsState {}

class PermissionsLoading extends PermissionsState {}

class PermissionsLoaded extends PermissionsState {
  final List<PermissionItemEntity> permissions;
  PermissionsLoaded(this.permissions);
}