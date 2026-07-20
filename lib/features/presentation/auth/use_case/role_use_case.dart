
import 'package:flutter/material.dart';
import 'package:yiraclinics/features/domain/entities/role/role_entity.dart';

class SelectRoleUseCase {

  const SelectRoleUseCase();

  Future<List<RoleLoginEntity>> getAvailableRoles() async {
    return [
      RoleLoginEntity(
        type: RoleType.patient,
        title: 'Patient',
        subtitle: 'Authorized Access',
        icon: Icons.lock_open_outlined,
      ),
      const RoleLoginEntity(
        type: RoleType.provider,
        title: 'Provider',
        subtitle: 'Authorized Access',
        icon: Icons.verified_user_outlined,
      ),
    ];
  }
}