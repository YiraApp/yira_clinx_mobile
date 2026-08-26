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
    List<ProfileModel>? profiles,
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
    super.navigationId,
  }) : super(roles: roles, profiles: profiles);

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
      profiles: json['profiles'] != null
          ? (json['profiles'] as List).map((v) => ProfileModel.fromJson(v)).toList()
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
      latestUserRole: json['latestUserRole'],
      latestHospitalId: json['latestHospitalId'],
      latestOrgId: json['latestOrgId'],
      latestRoleId: json['latestRoleId'],
      navigationId: json['navigationId'],
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
      profiles: entity.profiles?.map((v) => ProfileModel.fromEntity(v)).toList(),
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
      navigationId: entity.navigationId,
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
      'profiles': profiles?.map((v) => (v is ProfileModel ? v.toJson() : ProfileModel.fromEntity(v).toJson())).toList(),
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
      'latestUserRole': latestUserRole,
      'latestHospitalId': latestHospitalId,
      'latestOrgId': latestOrgId,
      'latestRoleId': latestRoleId,
      'navigationId': navigationId,
    };
  }
}

class ProfileModel extends ProfileEntity {
  ProfileModel({
    super.id,
    super.firstName,
    super.lastName,
    super.name,
    super.phoneNumber,
    super.relation,
    super.isPrimary,
    super.gender,
    super.dob,
    super.accountType,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      name: json['name']?.toString() ??
          "${json['firstName'] ?? ''} ${json['lastName'] ?? ''}".trim(),
      phoneNumber: json['phoneNumber']?.toString(),
      relation: json['relation']?.toString() ??
          (json['isPrimary'] == true ? "Self" : "Dependent"),
      isPrimary: json['isPrimary'] == true,
      gender: json['gender']?.toString(),
      dob: json['dob']?.toString(),
      accountType: json['accountType']?.toString() ??
          (json['isPrimary'] == true ? "Independent" : "Dependent"),
    );
  }

  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      id: entity.id,
      firstName: entity.firstName,
      lastName: entity.lastName,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      relation: entity.relation,
      isPrimary: entity.isPrimary,
      gender: entity.gender,
      dob: entity.dob,
      accountType: entity.accountType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'name': name,
      'phoneNumber': phoneNumber,
      'relation': relation,
      'isPrimary': isPrimary,
      'gender': gender,
      'dob': dob,
      'accountType': accountType,
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