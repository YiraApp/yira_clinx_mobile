
import '../../../domain/entities/fcm_token/update_fcm_token_entity.dart';


class UpdateFcmTokenModel extends FcmTokenEntity {
  const UpdateFcmTokenModel({
    required super.status,
    required super.message,
    super.data,
  });

  factory UpdateFcmTokenModel.fromJson(Map<String, dynamic> json) {
    return UpdateFcmTokenModel(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? FcmTokenDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data != null ? (data as FcmTokenDataModel).toJson() : null,
    };
  }
}


class FcmTokenDataModel extends FcmTokenDataEntity {
  const FcmTokenDataModel({
    required super.id,
    required super.userId,
    required super.fcmToken,
    required super.platform,
    required super.physicalDeviceId,
    required super.currentVersion,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FcmTokenDataModel.fromJson(Map<String, dynamic> json) {
    return FcmTokenDataModel(
      id: json['Id'] as int? ?? 0,
      userId: json['UserId'] as String? ?? '',
      fcmToken: json['FCMToken'] as String? ?? '',
      platform: json['Platform'] as String? ?? '',
      physicalDeviceId: json['PhysicalDeviceId'] as String? ?? '',
      currentVersion: json['CurrentVersion'] as String? ?? '',
      isActive: json['IsActive'] as bool? ?? false,
      createdAt: json['CreatedAt'] as String? ?? '',
      updatedAt: json['UpdatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'UserId': userId,
      'FCMToken': fcmToken,
      'Platform': platform,
      'PhysicalDeviceId': physicalDeviceId,
      'CurrentVersion': currentVersion,
      'IsActive': isActive,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
    };
  }
}