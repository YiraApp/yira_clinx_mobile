import 'package:yiraclinics/features/domain/repositories/notifications/notifications_repo.dart';

class DeleteNotificationUseCase {
  final NotificationsRepository repository;

  const DeleteNotificationUseCase({required this.repository});

  Future<bool> call(String notificationId) {
    return repository.deleteNotification(notificationId);
  }
}
