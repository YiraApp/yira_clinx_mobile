import 'package:yiraclinics/features/domain/entities/notifications/app_notification_entity.dart';

abstract class NotificationsRepository {
  Future<NotificationsPayloadEntity?> getNotifications({int page = 1, int limit = 30});
  Future<bool> markAsRead(String notificationId);
  Future<bool> markAllAsRead();
}
