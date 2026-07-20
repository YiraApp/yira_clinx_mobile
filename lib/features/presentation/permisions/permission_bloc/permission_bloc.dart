import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/permissions/permision_entity.dart';

part 'permission_event.dart';
part 'permission_state.dart';


class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  PermissionsBloc() : super(PermissionsLoading()) {
    on<LoadPermissionsEvent>((event, emit) {
      // Mocking initial load data
      final initialData = [
        PermissionItemEntity(id: 'notifications', title: 'Notifications', description: 'Clinical alerts & lab reports', icon: Icons.notifications_none_outlined, isRequired: true, isGranted: true),
        PermissionItemEntity(id: 'camera', title: 'Camera & Scanning', description: 'ID verification & telehealth', icon: Icons.camera_alt_outlined, isRequired: true, isGranted: true),
        PermissionItemEntity(id: 'photos', title: 'Photos & Media', description: 'Document storage & uploads', icon: Icons.image_outlined, isRequired: true, isGranted: true),
        PermissionItemEntity(id: 'location', title: 'Location Services', description: 'Find nearest care center', icon: Icons.location_on_outlined, isRequired: false, isGranted: false),
      ];
      emit(PermissionsLoaded(initialData));
    });

    on<TogglePermissionEvent>((event, emit) {
      if (state is PermissionsLoaded) {
        final currentList = (state as PermissionsLoaded).permissions;
        final updatedList = currentList.map((item) {
          if (item.id == event.id) {
            return item.copyWith(isGranted: !item.isGranted);
          }
          return item;
        }).toList();
        emit(PermissionsLoaded(updatedList));
      }
    });
  }
}