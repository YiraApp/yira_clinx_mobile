class LoginEntity {
  final bool? status;
  final String? message;
  final DataEntity? data;

  LoginEntity({this.status, this.message, this.data});
}

class DataEntity {
  final String? accessToken;
  final String? refreshToken;
  final String? accessTokenExpiry;
  final String? refreshTokenExpiry;
  final String? id;
  final bool? isMobileVerified;
  final bool? isEmailVerified;
  final int? roleCount;
  final int? hospitalCount;
  final int? organizationCount;
  final String? userRole;
  final List<RoleEntity>? roles;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? countryCode;
  final String? gender;
  final String? dob;
  final String? height;
  final String? weight;
  final String? heightUnit;
  final String? weightUnit;

  DataEntity({
    this.accessToken,
    this.refreshToken,
    this.accessTokenExpiry,
    this.refreshTokenExpiry,
    this.id,
    this.isMobileVerified,
    this.isEmailVerified,
    this.roleCount,
    this.hospitalCount,
    this.organizationCount,
    this.roles,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.countryCode,
    this.gender,
    this.dob,
    this.height,
    this.weight,
    this.heightUnit,
    this.weightUnit, this.userRole,
  });
}

class RoleEntity {
  final String? roleId;
  final String? roleName;
  final bool? status;

  RoleEntity({this.roleId, this.roleName, this.status});
}