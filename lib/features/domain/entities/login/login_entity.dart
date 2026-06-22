
import 'package:equatable/equatable.dart';

class LoginEntity extends Equatable {
  final bool status;
  final String message;
  final LoginDataEntity? data;

  const LoginEntity({
    required this.status,
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [status, message, data];
}

class LoginDataEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String accessTokenExpiry;
  final String refreshTokenExpiry;
  final UserEntity? user;

  const LoginDataEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiry,
    required this.refreshTokenExpiry,
    this.user,
  });

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    accessTokenExpiry,
    refreshTokenExpiry,
    user,
  ];
}

class UserEntity extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final bool isMobileVerified;
  final bool isEmailVerified;
  final List<RoleEntity> roles;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.isMobileVerified,
    required this.isEmailVerified,
    required this.roles,
  });

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    phoneNumber,
    countryCode,
    isMobileVerified,
    isEmailVerified,
    roles,
  ];
}

class RoleEntity extends Equatable {
  final String userRoleId;
  final String roleId;
  final String roleName;
  final String organizationId;
  final String organizationName;
  final String organizationCode;
  final String hospitalId;
  final String hospitalName;
  final String hospitalCode;
  final bool status;

  const RoleEntity({
    required this.userRoleId,
    required this.roleId,
    required this.roleName,
    required this.organizationId,
    required this.organizationName,
    required this.organizationCode,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalCode,
    required this.status,
  });

  @override
  List<Object?> get props => [
    userRoleId,
    roleId,
    roleName,
    organizationId,
    organizationName,
    organizationCode,
    hospitalId,
    hospitalName,
    hospitalCode,
    status,
  ];
}