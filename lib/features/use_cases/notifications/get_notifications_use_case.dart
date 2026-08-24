import 'package:yiraclinics/features/domain/entities/notifications/app_notification_entity.dart';
import 'package:yiraclinics/features/domain/repositories/notifications/notifications_repo.dart';

class GetNotificationsUseCase {
  final NotificationsRepository repository;

  const GetNotificationsUseCase({required this.repository});

  Future<NotificationsPayloadEntity?> call({int page = 1, int limit = 30}) {
    return repository.getNotifications(page: page, limit: limit);
  }
}
