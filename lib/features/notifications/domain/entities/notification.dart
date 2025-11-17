import 'package:equatable/equatable.dart';

/// Notification Entity
///
/// Represents a user notification
class NotificationEntity extends Equatable {
  final String notificationId;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl;
  final String? imageUrl;

  const NotificationEntity({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.actionUrl,
    this.imageUrl,
  });

  /// Get time since notification
  String get timeSinceText {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
    }
  }

  /// Get icon for notification type
  String get iconName {
    switch (type) {
      case NotificationType.newMatch:
        return 'favorite';
      case NotificationType.newMessage:
        return 'chat_bubble';
      case NotificationType.newLike:
        return 'thumb_up';
      case NotificationType.profileView:
        return 'visibility';
      case NotificationType.superLike:
        return 'star';
      case NotificationType.matchExpiring:
        return 'schedule';
      case NotificationType.promotional:
        return 'local_offer';
      case NotificationType.system:
        return 'info';
    }
  }

  /// Copy with updated fields
  NotificationEntity copyWith({
    String? notificationId,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? actionUrl,
    String? imageUrl,
  }) {
    return NotificationEntity(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        notificationId,
        userId,
        type,
        title,
        message,
        data,
        createdAt,
        isRead,
        actionUrl,
        imageUrl,
      ];
}

/// Notification Types
enum NotificationType {
  newMatch,
  newMessage,
  newLike,
  profileView,
  superLike,
  matchExpiring,
  promotional,
  system,
}

/// Extension for NotificationType
extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.newMatch:
        return 'new_match';
      case NotificationType.newMessage:
        return 'new_message';
      case NotificationType.newLike:
        return 'new_like';
      case NotificationType.profileView:
        return 'profile_view';
      case NotificationType.superLike:
        return 'super_like';
      case NotificationType.matchExpiring:
        return 'match_expiring';
      case NotificationType.promotional:
        return 'promotional';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'new_match':
        return NotificationType.newMatch;
      case 'new_message':
        return NotificationType.newMessage;
      case 'new_like':
        return NotificationType.newLike;
      case 'profile_view':
        return NotificationType.profileView;
      case 'super_like':
        return NotificationType.superLike;
      case 'match_expiring':
        return NotificationType.matchExpiring;
      case 'promotional':
        return NotificationType.promotional;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}
