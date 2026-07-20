import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/features/use_cases/get_work_space_details_use_case.dart';
import 'package:yiraclinics/features/use_cases/update_latest_org_details_use_case.dart';

import '../../../../domain/entities/work_space/get_work_space_entity.dart';
import '../../../../domain/entities/work_space/update_latest_org_details_entity.dart';

part 'work_space_event.dart';
part 'work_space_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final GetWorkSpaceDetailsUseCase getWorkSpaceDetailsUseCase;
  final UpdateLatestOrgDetailsUseCase updateLatestOrgDetailsUseCase;
  WorkspaceBloc({
    required this.getWorkSpaceDetailsUseCase,
    required this.updateLatestOrgDetailsUseCase,
  }) : super(WorkspaceInitial()) {
    on<LoadWorkspacesEvent>(_onLoadWorkspaces);
    on<ToggleOrganizationEvent>(_onToggleOrganization);
    on<OnSaveLatestOrgDetailsEvent>(_onSaveLatestOrgDetails);
    on<NavToDashBoardEvent>((event, emit) {
      emit(NavToDashBoard());
    });
    on<NavToSignInEvent>((event, emit) {
      emit(NavToSignin());
    });
  }

  void _onLoadWorkspaces(
    LoadWorkspacesEvent event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(WorkspaceLoading());
    try {
      final response = await getWorkSpaceDetailsUseCase(event.parameters);

      if (response != null &&
          response.status == true &&
          response.data != null) {
        final cleanList = response.data!.whereType<DataEntity>().toList();
        emit(WorkspacesLoaded(organizations: cleanList));
      } else {
        emit(WorkspaceError(response?.message ?? "Failed to load workspaces."));
      }
    } catch (e) {
      emit(WorkspaceError("An unexpected error occurred: $e"));
    }
  }

  Future<void> _onSaveLatestOrgDetails(
    OnSaveLatestOrgDetailsEvent event,
    Emitter<WorkspaceState> emit,
  ) async {
    if (state is WorkspacesLoaded) {
      try {
        var response = await updateLatestOrgDetailsUseCase.call(
          event.updateLatestOrgDetailsModelParams,
        );
        if (response != null &&
            response.status == true &&
            response.data != null) {
          emit(OnSuccessLatestOrgDetailsState(response));
        } else {
          emit(
            WorkspaceError(response?.message ?? "Failed to save Latest Org Details."),
          );
        }
      } catch (e) {
        emit(
          OnSaveLatestOrgDetailsStateError("An unexpected error occurred: $e"),
        );
      }
    }
  }

  void _onToggleOrganization(
    ToggleOrganizationEvent event,
    Emitter<WorkspaceState> emit,
  ) {
    if (state is WorkspacesLoaded) {
      final currentState = state as WorkspacesLoaded;

      final updatedExpandedIds = Set<int>.from(
        currentState.expandedOrganizationIds,
      );

      if (updatedExpandedIds.contains(event.orgId)) {
        updatedExpandedIds.remove(event.orgId);
      } else {
        updatedExpandedIds.add(event.orgId);
      }
      emit(currentState.copyWith(expandedOrganizationIds: updatedExpandedIds));
    }
  }
}
