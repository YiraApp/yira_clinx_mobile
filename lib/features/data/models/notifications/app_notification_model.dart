import 'package:yiraclinics/features/domain/entities/notifications/app_notification_entity.dart';

class AppNotificationModel extends AppNotificationEntity {
  const AppNotificationModel({
    required super.id,
    required super.userId,
    super.senderId,
    required super.title,
    required super.body,
    required super.type,
    super.referenceId,
    super.route,
    required super.isRead,
    required super.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      senderId: json['senderId']?.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      referenceId: json['referenceId']?.toString(),
      route: json['route']?.toString(),
      isRead: json['isRead'] == true || json['isRead'] == 1,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'senderId': senderId,
      'title': title,
      'body': body,
      'type': type,
      'referenceId': referenceId,
      'route': route,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class NotificationsPayloadModel extends NotificationsPayloadEntity {
  const NotificationsPayloadModel({
    required super.notifications,
    required super.total,
    required super.unreadCount,
  });

  factory NotificationsPayloadModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['notifications'];
    List<AppNotificationModel> list = [];
    if (rawList is List) {
      list = rawList
          .map((item) => AppNotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return NotificationsPayloadModel(
      notifications: list,
      total: json['total'] is int ? json['total'] : (int.tryParse(json['total']?.toString() ?? '0') ?? list.length),
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : (int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0),
    );
  }
}
