
import 'package:yiraclinics/core/widgets/ios_icons.dart';
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
        icon: IosIcons.lock_open_outlined,
      ),
      const RoleLoginEntity(
        type: RoleType.provider,
        title: 'Provider',
        subtitle: 'Authorized Access',
        icon: IosIcons.verified_user_outlined,
      ),
    ];
  }
}