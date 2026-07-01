
import 'package:equatable/equatable.dart';

class FcmTokenEntity extends Equatable {
  final bool status;
  final String message;
  final FcmTokenDataEntity? data;

  const FcmTokenEntity({
    required this.status,
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [status, message, data];
}

class FcmTokenDataEntity extends Equatable {
  final int id;
  final String userId;
  final String fcmToken;
  final String platform;
  final String physicalDeviceId;
  final String currentVersion;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const FcmTokenDataEntity({
    required this.id,
    required this.userId,
    required this.fcmToken,
    required this.platform,
    required this.physicalDeviceId,
    required this.currentVersion,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    fcmToken,
    platform,
    physicalDeviceId,
    currentVersion,
    isActive,
    createdAt,
    updatedAt,
  ];
}