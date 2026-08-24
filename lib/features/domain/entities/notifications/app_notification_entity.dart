import 'package:equatable/equatable.dart';

class AppNotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String? senderId;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  final String? route;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationEntity({
    required this.id,
    required this.userId,
    this.senderId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.route,
    required this.isRead,
    required this.createdAt,
  });

  AppNotificationEntity copyWith({
    String? id,
    String? userId,
    String? senderId,
    String? title,
    String? body,
    String? type,
    String? referenceId,
    String? route,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      route: route ?? this.route,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        senderId,
        title,
        body,
        type,
        referenceId,
        route,
        isRead,
        createdAt,
      ];
}

class NotificationsPayloadEntity extends Equatable {
  final List<AppNotificationEntity> notifications;
  final int total;
  final int unreadCount;

  const NotificationsPayloadEntity({
    required this.notifications,
    required this.total,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, total, unreadCount];
}
