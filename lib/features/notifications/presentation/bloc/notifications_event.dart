/// Notifications Events
abstract class NotificationsEvent {
  const NotificationsEvent();
}

/// Load notifications
class NotificationsLoadRequested extends NotificationsEvent {
  final String userId;
  final bool unreadOnly;

  const NotificationsLoadRequested({
    required this.userId,
    this.unreadOnly = false,
  });
}

/// Mark notification as read
class NotificationMarkedAsRead extends NotificationsEvent {
  final String notificationId;

  const NotificationMarkedAsRead(this.notificationId);
}

/// Mark all as read
class NotificationsMarkedAllAsRead extends NotificationsEvent {
  final String userId;

  const NotificationsMarkedAllAsRead(this.userId);
}

/// Delete notification
class NotificationDeleted extends NotificationsEvent {
  final String notificationId;

  const NotificationDeleted(this.notificationId);
}

/// Notification tapped
class NotificationTapped extends NotificationsEvent {
  final String notificationId;
  final String? actionUrl;

  const NotificationTapped({
    required this.notificationId,
    this.actionUrl,
  });
}
