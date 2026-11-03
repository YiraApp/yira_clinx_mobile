import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotificationsEvent extends NotificationsEvent {
  final bool isRefresh;
  const FetchNotificationsEvent({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Loads the next page when the list is scrolled near its end.
class LoadMoreNotificationsEvent extends NotificationsEvent {
  const LoadMoreNotificationsEvent();
}

class MarkNotificationAsReadEvent extends NotificationsEvent {
  final String notificationId;
  const MarkNotificationAsReadEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsReadEvent extends NotificationsEvent {}

class ClearAllNotificationsEvent extends NotificationsEvent {}

class DeleteNotificationEvent extends NotificationsEvent {
  final String notificationId;
  const DeleteNotificationEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}
