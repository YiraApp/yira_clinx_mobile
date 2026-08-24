import 'package:equatable/equatable.dart';
import 'package:yiraclinics/features/domain/entities/notifications/app_notification_entity.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitialState extends NotificationsState {}

class NotificationsLoadingState extends NotificationsState {}

class NotificationsLoadedState extends NotificationsState {
  final List<AppNotificationEntity> notifications;
  final int unreadCount;
  final int total;

  const NotificationsLoadedState({
    required this.notifications,
    required this.unreadCount,
    required this.total,
  });

  NotificationsLoadedState copyWith({
    List<AppNotificationEntity>? notifications,
    int? unreadCount,
    int? total,
  }) {
    return NotificationsLoadedState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, total];
}

class NotificationsErrorState extends NotificationsState {
  final String message;
  const NotificationsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
