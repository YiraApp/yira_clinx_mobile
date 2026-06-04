part of 'work_space_bloc.dart';

@immutable
abstract class WorkspaceState {}
class WorkspaceInitial extends WorkspaceState {}
class WorkspaceLoading extends WorkspaceState {}
class NavToDashBoard extends WorkspaceState {}
class NavToSignin extends WorkspaceState {}
class WorkspacesLoaded extends WorkspaceState {
  final List<OrganizationEntity?> organizations;
  WorkspacesLoaded(this.organizations);
}
