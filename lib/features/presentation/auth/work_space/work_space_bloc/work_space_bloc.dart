import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/work_space/organization_entity.dart';

part 'work_space_event.dart';
part 'work_space_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  WorkspaceBloc() : super(WorkspaceInitial()) {
    on<LoadWorkspacesEvent>(_onLoadWorkspaces);
    on<ToggleOrganizationEvent>(_onToggleOrganization);
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
  ) {
    emit(WorkspaceLoading());

    final mockData = [
      OrganizationEntity(
        id: '1',
        name: 'Ocimum dental clinic',
        isExpanded: true,
        hospitals: [
          HospitalEntity(id: '101', name: 'Ocimum Somajiguda'),
          HospitalEntity(id: '102', name: 'Ocimum Gachibowli'),
          HospitalEntity(id: '103', name: 'Ocimum Jubilee Hills'),
          HospitalEntity(id: '104', name: 'Ocimum Madhapur'),
          HospitalEntity(id: '105', name: 'Ocimum Secunderabad'),
        ],
      ),
      OrganizationEntity(
        id: '2',
        name: 'AIG Hospitals Group',
        isExpanded: true,
        hospitals: [
          HospitalEntity(id: '201', name: 'AIG Somajiguda'),
          HospitalEntity(id: '202', name: 'AIG Gachibowli'),
          HospitalEntity(id: '203', name: 'AIG Jubilee Hills'),
          HospitalEntity(id: '204', name: 'AIG Madhapur'),
          HospitalEntity(id: '205', name: 'AIG Secunderabad'),
        ],
      ),

      OrganizationEntity(
        id: '3',
        name: 'KIMS Healthcare',
        isExpanded: false,
        hospitals: [
          HospitalEntity(id: '301', name: 'KIMS Secunderabad'),
          HospitalEntity(id: '302', name: 'KIMS Kondapur'),
          HospitalEntity(id: '303', name: 'KIMS Gachibowli'),
          HospitalEntity(id: '304', name: 'KIMS Begumpet'),
          HospitalEntity(id: '305', name: 'KIMS Paradise'),
        ],
      ),
      OrganizationEntity(
        id: '4',
        name: 'Yashoda Hospitals',
        isExpanded: false,
        hospitals: [
          HospitalEntity(id: '401', name: 'Yashoda Somajiguda'),
          HospitalEntity(id: '402', name: 'Yashoda Malakpet'),
          HospitalEntity(id: '403', name: 'Yashoda Secunderabad'),
          HospitalEntity(id: '404', name: 'Yashoda Hitech City'),
          HospitalEntity(id: '405', name: 'Yashoda Clinics Begumpet'),
        ],
      ),
      OrganizationEntity(
        id: '5',
        name: 'Demo Org Group 1',
        isExpanded: false,
        hospitals: [
          HospitalEntity(id: '501', name: 'Demo Clinic Gachibowli'),
          HospitalEntity(id: '502', name: 'Demo Hospital Kukatpally'),
          HospitalEntity(id: '503', name: 'Demo Care Miyapur'),
          HospitalEntity(id: '504', name: 'Demo Wellness Banjara Hills'),
          HospitalEntity(id: '505', name: 'Demo Medical Center Manikonda'),
        ],
      ),
    ];
    emit(WorkspacesLoaded(mockData));
  }

  void _onToggleOrganization(
    ToggleOrganizationEvent event,
    Emitter<WorkspaceState> emit,
  ) {
    if (state is WorkspacesLoaded) {
      final currentOrgs = (state as WorkspacesLoaded).organizations;
      final updatedOrgs = currentOrgs.map((org) {
        if (org?.id == event.orgId) {
          return org?.copyWith(isExpanded: !org.isExpanded);
        }
        return org;
      }).toList();
      emit(WorkspacesLoaded(updatedOrgs));
    }
  }
}
