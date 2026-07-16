import 'package:greengo_chat/features/notifications/domain/entities/notification.dart';

/// Shared NOTIFICATIONS test fixtures (owned by the notifications suite — does
/// NOT touch mock_data.dart). Builds [NotificationEntity]s for bloc + model
/// tests, including read/unread mixes for the optimistic clear regressions.
class NotificationFixtures {
  NotificationFixtures._();

  static NotificationEntity build({
    String id = 'notif_1',
    String userId = 'user_1',
    NotificationType type = NotificationType.system,
    String title = 'Title',
    String message = 'Message',
    bool isRead = false,
    DateTime? createdAt,
    String? actionUrl,
    String? actorId,
    String? actorName,
    Map<String, dynamic>? data,
  }) {
    return NotificationEntity(
      notificationId: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      isRead: isRead,
      createdAt: createdAt ?? DateTime(2026, 7, 15, 12, 30),
      actionUrl: actionUrl,
      actorId: actorId,
      actorName: actorName,
      data: data,
    );
  }

  /// A mixed list: 2 unread + 1 read (unreadCount == 2).
  static List<NotificationEntity> mixed({String userId = 'user_1'}) => [
        build(id: 'n_unread_1', userId: userId, isRead: false),
        build(id: 'n_unread_2', userId: userId, isRead: false),
        build(id: 'n_read_1', userId: userId, isRead: true),
      ];

  /// A list where every notification is unread.
  static List<NotificationEntity> allUnread({String userId = 'user_1'}) => [
        build(id: 'n_unread_1', userId: userId, isRead: false),
        build(id: 'n_unread_2', userId: userId, isRead: false),
      ];
}
