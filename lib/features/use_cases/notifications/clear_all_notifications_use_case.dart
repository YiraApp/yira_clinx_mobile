import 'package:yiraclinics/features/domain/repositories/notifications/notifications_repo.dart';

class ClearAllNotificationsUseCase {
  final NotificationsRepository repository;

  const ClearAllNotificationsUseCase({required this.repository});

  Future<bool> call() {
    return repository.clearAllNotifications();
  }
}
