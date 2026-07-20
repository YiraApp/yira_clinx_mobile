part of 'permission_bloc.dart';

@immutable
abstract class PermissionsEvent {}

class LoadPermissionsEvent extends PermissionsEvent {}

class TogglePermissionEvent extends PermissionsEvent {
  final String id;
  TogglePermissionEvent(this.id);
}
