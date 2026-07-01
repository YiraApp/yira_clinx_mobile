part of 'work_space_bloc.dart';

@immutable
abstract class WorkspaceEvent {}
class LoadWorkspacesEvent extends WorkspaceEvent {
  final WorkSpaceParameters  parameters;

  LoadWorkspacesEvent(this.parameters);
}
class NavToDashBoardEvent extends WorkspaceEvent {}
class NavToSignInEvent extends WorkspaceEvent {}
class ToggleOrganizationEvent extends WorkspaceEvent {
  final int orgId;
  ToggleOrganizationEvent(this.orgId);
}

class OnSaveLatestOrgDetailsEvent extends WorkspaceEvent {
  final UpdateLatestOrgDetailsModelParams updateLatestOrgDetailsModelParams;
  OnSaveLatestOrgDetailsEvent(this.updateLatestOrgDetailsModelParams);
}

