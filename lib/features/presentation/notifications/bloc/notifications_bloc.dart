import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/services/notification_services/notification_badge_service.dart';
import 'package:yiraclinics/features/domain/entities/notifications/app_notification_entity.dart';
import 'package:yiraclinics/features/use_cases/notifications/clear_all_notifications_use_case.dart';
import 'package:yiraclinics/features/use_cases/notifications/delete_notification_use_case.dart';
import 'package:yiraclinics/features/use_cases/notifications/get_notifications_use_case.dart';
import 'package:yiraclinics/features/use_cases/notifications/mark_notification_read_use_case.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final ClearAllNotificationsUseCase clearAllNotificationsUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;

  NotificationsBloc({
    required this.getNotificationsUseCase,
    required this.markNotificationReadUseCase,
    required this.clearAllNotificationsUseCase,
    required this.deleteNotificationUseCase,
  }) : super(NotificationsInitialState()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
    on<ClearAllNotificationsEvent>(_onClearAllNotifications);
    on<DeleteNotificationEvent>(_onDeleteNotification);
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (!event.isRefresh && state is! NotificationsLoadedState) {
      emit(NotificationsLoadingState());
    }

    final payload = await getNotificationsUseCase.call();
    if (payload != null) {
      NotificationBadgeService.instance.setUnreadCount(payload.unreadCount);
      emit(NotificationsLoadedState(
        notifications: List<AppNotificationEntity>.from(payload.notifications),
        unreadCount: payload.unreadCount,
        total: payload.total,
      ));
    } else {
      if (state is! NotificationsLoadedState) {
        emit(const NotificationsErrorState("Unable to load notifications"));
      }
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is NotificationsLoadedState) {
      final currentState = state as NotificationsLoadedState;
      final index = currentState.notifications.indexWhere((n) => n.id == event.notificationId);
      if (index == -1) return;

      final target = currentState.notifications[index];
      if (target.isRead) return;

      final updatedList = List<AppNotificationEntity>.from(currentState.notifications);
      updatedList[index] = target.copyWith(isRead: true);

      final newUnread = (currentState.unreadCount - 1).clamp(0, currentState.total);

      NotificationBadgeService.instance.decrement();

      emit(currentState.copyWith(
        notifications: updatedList,
        unreadCount: newUnread,
      ));

      await markNotificationReadUseCase.call(event.notificationId);
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is NotificationsLoadedState) {
      final currentState = state as NotificationsLoadedState;
      final updatedList = currentState.notifications.map((n) => n.copyWith(isRead: true)).toList();
      NotificationBadgeService.instance.clear();
      emit(currentState.copyWith(
        notifications: updatedList,
        unreadCount: 0,
      ));

      await markNotificationReadUseCase.markAll();
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is NotificationsLoadedState) {
      final currentState = state as NotificationsLoadedState;
      NotificationBadgeService.instance.clear();
      emit(currentState.copyWith(
        notifications: const [],
        unreadCount: 0,
        total: 0,
      ));

      await clearAllNotificationsUseCase.call();
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is NotificationsLoadedState) {
      final currentState = state as NotificationsLoadedState;
      final index = currentState.notifications.indexWhere((n) => n.id == event.notificationId);
      if (index == -1) return;

      final target = currentState.notifications[index];
      final wasUnread = !target.isRead;

      final updatedList = currentState.notifications.where((n) => n.id != event.notificationId).toList();

      final newUnread = wasUnread
          ? (currentState.unreadCount - 1).clamp(0, updatedList.length)
          : currentState.unreadCount;

      if (wasUnread) {
        NotificationBadgeService.instance.decrement();
      }

      emit(currentState.copyWith(
        notifications: updatedList,
        unreadCount: newUnread,
        total: (currentState.total - 1).clamp(0, 999999),
      ));

      await deleteNotificationUseCase.call(event.notificationId);
    }
  }
}
