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

  /// The last page fetched from the server.
  final int page;
  final bool isLoadingMore;

  const NotificationsLoadedState({
    required this.notifications,
    required this.unreadCount,
    required this.total,
    this.page = 1,
    this.isLoadingMore = false,
  });

  /// More notifications exist on the server than are loaded.
  bool get hasMore => notifications.length < total;

  NotificationsLoadedState copyWith({
    List<AppNotificationEntity>? notifications,
    int? unreadCount,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) {
    return NotificationsLoadedState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, total, page, isLoadingMore];
}

class NotificationsErrorState extends NotificationsState {
  final String message;
  const NotificationsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
