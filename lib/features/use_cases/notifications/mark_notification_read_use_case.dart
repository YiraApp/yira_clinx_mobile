import 'package:yiraclinics/features/domain/repositories/notifications/notifications_repo.dart';

class MarkNotificationReadUseCase {
  final NotificationsRepository repository;

  const MarkNotificationReadUseCase({required this.repository});

  Future<bool> call(String notificationId) {
    return repository.markAsRead(notificationId);
  }

  Future<bool> markAll() {
    return repository.markAllAsRead();
  }
}
