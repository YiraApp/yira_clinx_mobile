import '../../../domain/entities/login/login_entity.dart';

class LoginModel extends LoginEntity {
  LoginModel({
    super.status,
    super.message,
    DataModel? data,
  }) : super(data: data);

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? DataModel.fromJson(json['data']) : null,
    );
  }

  factory LoginModel.fromEntity(LoginEntity entity) {
    return LoginModel(
      status: entity.status,
      message: entity.message,
      data: entity.data != null ? DataModel.fromEntity(entity.data!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': (data as DataModel?)?.toJson(),
    };
  }
}

class DataModel extends DataEntity {
  DataModel({
    super.accessToken,
    super.refreshToken,
    super.accessTokenExpiry,
    super.refreshTokenExpiry,
    super.id,
    super.isMobileVerified,
    super.isEmailVerified,
    super.roleCount,
    super.hospitalCount,
    super.organizationCount,
    List<RoleModel>? roles,
    super.firstName,
    super.lastName,
    super.email,
    super.phoneNumber,
    super.countryCode,
    super.gender,
    super.dob,
    super.height,
    super.weight,
    super.heightUnit,
    super.weightUnit,
    super.latestUserRole,
    super.latestHospitalId,
    super.latestOrgId,
    super.latestRoleId,
    super.navigationId
  }) : super(roles: roles);

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      accessTokenExpiry: json['accessTokenExpiry'],
      refreshTokenExpiry: json['refreshTokenExpiry'],
      id: json['id'],
      isMobileVerified: json['isMobileVerified'],
      isEmailVerified: json['isEmailVerified'],
      roleCount: json['roleCount'],
      hospitalCount: json['hospitalCount'],
      organizationCount: json['organizationCount'],
      roles: json['roles'] != null
          ? (json['roles'] as List).map((v) => RoleModel.fromJson(v)).toList()
          : null,
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      countryCode: json['countryCode'],
      gender: json['gender'],
      dob: json['dob'],
      height: json['height'],
      weight: json['weight'],
      heightUnit: json['heightUnit'],
      weightUnit: json['weightUnit'],
      latestUserRole: json['latestUserRole'] ,
      latestHospitalId: json['latestHospitalId'],
      latestOrgId: json['latestOrgId'],
      latestRoleId: json['latestRoleId'],
        navigationId: json['navigationId']
    );
  }

  factory DataModel.fromEntity(DataEntity entity) {
    return DataModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      accessTokenExpiry: entity.accessTokenExpiry,
      refreshTokenExpiry: entity.refreshTokenExpiry,
      id: entity.id,
      isMobileVerified: entity.isMobileVerified,
      isEmailVerified: entity.isEmailVerified,
      roleCount: entity.roleCount,
      hospitalCount: entity.hospitalCount,
      organizationCount: entity.organizationCount,
      roles: entity.roles?.map((v) => RoleModel.fromEntity(v)).toList(),
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      countryCode: entity.countryCode,
      gender: entity.gender,
      dob: entity.dob,
      height: entity.height,
      weight: entity.weight,
      heightUnit: entity.heightUnit,
      weightUnit: entity.weightUnit,
      latestUserRole: entity.latestUserRole,
        latestRoleId: entity.latestRoleId,
        latestHospitalId: entity.latestHospitalId,
        latestOrgId: entity.latestOrgId,
        navigationId: entity.navigationId
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiry': accessTokenExpiry,
      'refreshTokenExpiry': refreshTokenExpiry,
      'id': id,
      'isMobileVerified': isMobileVerified,
      'isEmailVerified': isEmailVerified,
      'roleCount': roleCount,
      'hospitalCount': hospitalCount,
      'organizationCount': organizationCount,
      'roles': roles?.map((v) => (v as RoleModel).toJson()).toList(),
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'gender': gender,
      'dob': dob,
      'height': height,
      'weight': weight,
      'heightUnit': heightUnit,
      'weightUnit': weightUnit,
      'latestUserRole':latestUserRole,
      'latestHospitalId':latestHospitalId,
      'latestOrgId':latestOrgId,
      'latestRoleId':latestRoleId,
      'navigationId':navigationId
    };
  }
}

class RoleModel extends RoleEntity {
  RoleModel({
    super.roleId,
    super.roleName,
    super.status,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      roleId: json['roleId'],
      roleName: json['roleName'],
      status: json['status'],
    );
  }

  factory RoleModel.fromEntity(RoleEntity entity) {
    return RoleModel(
      roleId: entity.roleId,
      roleName: entity.roleName,
      status: entity.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleId': roleId,
      'roleName': roleName,
      'status': status,
    };
  }
}