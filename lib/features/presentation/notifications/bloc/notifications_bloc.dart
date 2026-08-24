import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/use_cases/notifications/get_notifications_use_case.dart';
import 'package:yiraclinics/features/use_cases/notifications/mark_notification_read_use_case.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;

  NotificationsBloc({
    required this.getNotificationsUseCase,
    required this.markNotificationReadUseCase,
  }) : super(NotificationsInitialState()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
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
      emit(NotificationsLoadedState(
        notifications: payload.notifications,
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
      final updatedList = currentState.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final newUnread = (currentState.unreadCount - 1).clamp(0, currentState.total);
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
      emit(currentState.copyWith(
        notifications: updatedList,
        unreadCount: 0,
      ));

      await markNotificationReadUseCase.markAll();
    }
  }
}
