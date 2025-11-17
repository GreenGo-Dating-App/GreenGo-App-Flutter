import '../../domain/entities/notification.dart';

/// Notifications States
abstract class NotificationsState {
  const NotificationsState();
}

/// Initial state
class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

/// Loading notifications
class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

/// Notifications loaded
class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    this.unreadCount = 0,
  });

  int get actualUnreadCount {
    return notifications.where((n) => !n.isRead).length;
  }
}

/// No notifications
class NotificationsEmpty extends NotificationsState {
  const NotificationsEmpty();
}

/// Error state
class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);
}
