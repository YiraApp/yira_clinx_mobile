part of 'work_space_bloc.dart';

@immutable
abstract class WorkspaceEvent {}
class LoadWorkspacesEvent extends WorkspaceEvent {}
class NavToDashBoardEvent extends WorkspaceEvent {}
class NavToSignInEvent extends WorkspaceEvent {}
class ToggleOrganizationEvent extends WorkspaceEvent {
  final String orgId;
  ToggleOrganizationEvent(this.orgId);
}
