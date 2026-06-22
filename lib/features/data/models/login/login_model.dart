import '../../../domain/entities/login/login_entity.dart';

class LoginModel extends LoginEntity {
  const LoginModel({
    required super.status,
    required super.message,
    LoginDataModel? super.data,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginDataModel.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data != null ? (data as LoginDataModel).toJson() : null,
    };
  }
}

class LoginDataModel extends LoginDataEntity {
  const LoginDataModel({
    required super.accessToken,
    required super.refreshToken,
    required super.accessTokenExpiry,
    required super.refreshTokenExpiry,
    UserModel? super.user,
  });

  factory LoginDataModel.fromJson(Map<String, dynamic> json) {
    return LoginDataModel(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      accessTokenExpiry: json['accessTokenExpiry'] ?? '',
      refreshTokenExpiry: json['refreshTokenExpiry'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiry': accessTokenExpiry,
      'refreshTokenExpiry': refreshTokenExpiry,
      'user': user != null ? (user as UserModel).toJson() : null,
    };
  }
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phoneNumber,
    required super.countryCode,
    required super.isMobileVerified,
    required super.isEmailVerified,
    required List<RoleModel> super.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var rolesList = <RoleModel>[];
    if (json['Roles'] != null) {
      json['Roles'].forEach((v) {
        rolesList.add(RoleModel.fromJson(v));
      });
    }
    return UserModel(
      id: json['Id'] ?? '',
      firstName: json['FirstName'] ?? '',
      lastName: json['LastName'] ?? '',
      email: json['Email'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? '',
      countryCode: json['CountryCode'] ?? '',
      isMobileVerified: json['IsMobileVerified'] ?? false,
      isEmailVerified: json['IsEmailVerified'] ?? false,
      roles: rolesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'CountryCode': countryCode,
      'IsMobileVerified': isMobileVerified,
      'IsEmailVerified': isEmailVerified,
      'Roles': roles.map((v) => (v as RoleModel).toJson()).toList(),
    };
  }
}

class RoleModel extends RoleEntity {
  const RoleModel({
    required super.userRoleId,
    required super.roleId,
    required super.roleName,
    required super.organizationId,
    required super.organizationName,
    required super.organizationCode,
    required super.hospitalId,
    required super.hospitalName,
    required super.hospitalCode,
    required super.status,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      userRoleId: json['UserRoleId'] ?? '',
      roleId: json['RoleId'] ?? '',
      roleName: json['RoleName'] ?? '',
      organizationId: json['OrganizationId'] ?? '',
      organizationName: json['OrganizationName'] ?? '',
      organizationCode: json['OrganizationCode'] ?? '',
      hospitalId: json['HospitalId'] ?? '',
      hospitalName: json['HospitalName'] ?? '',
      hospitalCode: json['HospitalCode'] ?? '',
      status: json['Status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserRoleId': userRoleId,
      'RoleId': roleId,
      'RoleName': roleName,
      'OrganizationId': organizationId,
      'OrganizationName': organizationName,
      'OrganizationCode': organizationCode,
      'HospitalId': hospitalId,
      'HospitalName': hospitalName,
      'HospitalCode': hospitalCode,
      'Status': status,
    };
  }
}
