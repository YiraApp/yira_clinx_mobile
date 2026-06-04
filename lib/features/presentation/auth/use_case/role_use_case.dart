
import 'package:flutter/material.dart';
import 'package:yiraclinics/features/domain/entities/role/role_entity.dart';

class SelectRoleUseCase {

  const SelectRoleUseCase();

  Future<List<RoleEntity>> getAvailableRoles() async {
    return [
      RoleEntity(
        type: RoleType.frontDesk,
        title: 'Patient',
        subtitle: 'Authorized Access',
        icon: Icons.lock_open_outlined,
      ),
      const RoleEntity(
        type: RoleType.provider,
        title: 'Provider',
        subtitle: 'Authorized Access',
        icon: Icons.verified_user_outlined,
      ),
    ];
  }
}