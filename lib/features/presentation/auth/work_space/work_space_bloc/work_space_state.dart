part of 'work_space_bloc.dart';

@immutable
abstract class WorkspaceState {}
class WorkspaceInitial extends WorkspaceState {}
class WorkspaceLoading extends WorkspaceState {}
class NavToDashBoard extends WorkspaceState {}
class NavToSignin extends WorkspaceState {}
class WorkspacesLoaded extends WorkspaceState {
  final List<DataEntity> organizations;
  final Set<int> expandedOrganizationIds;

  WorkspacesLoaded({
    required this.organizations,
    this.expandedOrganizationIds = const {},
  });

  WorkspacesLoaded copyWith({
    List<DataEntity>? organizations,
    Set<int>? expandedOrganizationIds,
  }) {
    return WorkspacesLoaded(
      organizations: organizations ?? this.organizations,
      expandedOrganizationIds: expandedOrganizationIds ?? this.expandedOrganizationIds,
    );
  }
}

class WorkspaceError extends WorkspaceState {
  final String errorMessage;

   WorkspaceError(this.errorMessage);
}
