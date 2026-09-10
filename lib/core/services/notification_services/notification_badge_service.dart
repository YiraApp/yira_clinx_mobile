import 'package:flutter/foundation.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/data/repository_impl/notifications/notifications_repo_impl.dart';
import 'package:yiraclinics/features/use_cases/notifications/get_notifications_use_case.dart';

/// Centralized reactive manager for notification unread counts and badges.
/// Synchronizes across Patient Dashboard, Doctor Dashboard, and Notification Center.
class NotificationBadgeService {
  NotificationBadgeService._internal();
  static final NotificationBadgeService instance = NotificationBadgeService._internal();

  /// Reactive unread count listenable for UI widgets
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  int get unreadCount => unreadCountNotifier.value;

  /// Updates the count directly
  void setUnreadCount(int count) {
    unreadCountNotifier.value = count < 0 ? 0 : count;
  }

  /// Decrements the count (e.g. after marking a notification as read or deleting it)
  void decrement([int count = 1]) {
    final current = unreadCountNotifier.value;
    unreadCountNotifier.value = (current - count).clamp(0, 99999);
  }

  /// Increments the count (e.g. when an in-app FCM notification arrives)
  void increment([int count = 1]) {
    unreadCountNotifier.value = (unreadCountNotifier.value + count).clamp(0, 99999);
  }

  /// Clears the count completely (e.g. mark all read or clear all)
  void clear() {
    unreadCountNotifier.value = 0;
  }

  /// Fetches the latest accurate unread count from the backend
  Future<void> syncUnreadCount() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      if (currentUser == null || (currentUser.data?.id ?? '').isEmpty) {
        setUnreadCount(0);
        return;
      }

      GetNotificationsUseCase useCase;
      if (sl.isRegistered<GetNotificationsUseCase>()) {
        useCase = sl<GetNotificationsUseCase>();
      } else {
        useCase = GetNotificationsUseCase(
          repository: NotificationsRepositoryImpl(apiClient: sl<ApiClient>()),
        );
      }

      final payload = await useCase.call(page: 1, limit: 1);
      if (payload != null) {
        setUnreadCount(payload.unreadCount);
      }
    } catch (e) {
      debugPrint("[NotificationBadgeService] Error syncing unread count: $e");
    }
  }
}
