/// Notifications Events
abstract class NotificationsEvent {
  const NotificationsEvent();
}

/// Load notifications
class NotificationsLoadRequested extends NotificationsEvent {

  const NotificationsLoadRequested({
    required this.userId,
    this.unreadOnly = false,
  });
  final String userId;
  final bool unreadOnly;
}

/// Mark notification as read
class NotificationMarkedAsRead extends NotificationsEvent {

  const NotificationMarkedAsRead(this.notificationId);
  final String notificationId;
}

/// Mark all as read
class NotificationsMarkedAllAsRead extends NotificationsEvent {

  const NotificationsMarkedAllAsRead(this.userId);
  final String userId;
}

/// Delete notification
class NotificationDeleted extends NotificationsEvent {

  const NotificationDeleted(this.notificationId);
  final String notificationId;
}

/// Notification tapped
class NotificationTapped extends NotificationsEvent {

  const NotificationTapped({
    required this.notificationId,
    this.actionUrl,
  });
  final String notificationId;
  final String? actionUrl;
}
