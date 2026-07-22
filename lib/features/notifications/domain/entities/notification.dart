import 'package:equatable/equatable.dart';

import 'notification_preferences.dart';

/// Notification Entity
///
/// Represents a user notification
class NotificationEntity extends Equatable {

  const NotificationEntity({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt, this.data,
    this.isRead = false,
    this.actionUrl,
    this.imageUrl,
    this.actorId,
    this.actorName,
  });
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

  /// The user who triggered this notification (for the left avatar + the
  /// tappable bold name in the tile). Null for system/no-actor notifications.
  final String? actorId;
  final String? actorName;

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
      case NotificationType.newChat:
        return 'forum';
      case NotificationType.coinsPurchased:
        return 'monetization_on';
      case NotificationType.progressAchieved:
        return 'emoji_events';
      case NotificationType.gameInvite:
        return 'sports_esports';
      case NotificationType.newEvent:
      case NotificationType.communityEvent:
      case NotificationType.communityEventChanged:
      case NotificationType.eventJoin:
      case NotificationType.eventReminder:
        return 'event';
      case NotificationType.groupMessage:
      case NotificationType.groupAdd:
      case NotificationType.groupJoin:
        return 'groups';
      case NotificationType.communityJoin:
      case NotificationType.communityAnnouncement:
        return 'campaign';
      case NotificationType.eventLike:
        return 'thumb_up';
      case NotificationType.eventAnnouncement:
        return 'campaign';
      case NotificationType.qrScanned:
        return 'qr_code';
      case NotificationType.businessFollow:
        return 'person_add';
      case NotificationType.businessRating:
        return 'star';
      case NotificationType.boostStarted:
      case NotificationType.boostEnded:
        return 'rocket_launch';
    }
  }

  /// The notification-preferences CATEGORY this belongs to — kept IN SYNC with
  /// the server's `categoryForType` (substring match on the raw type string) so
  /// the in-app bell list hides exactly the categories the user disabled in
  /// Notification Settings. One of: messages, events, communities, account,
  /// social.
  String get category {
    final t = type.value.toLowerCase();
    if (t.contains('message') || t.contains('chat') || t.contains('support')) {
      return 'messages';
    }
    if (t.contains('event') ||
        t.contains('rsvp') ||
        t.contains('attend') ||
        t.contains('reminder')) {
      return 'events';
    }
    if (t.contains('announce') ||
        t.contains('member') ||
        t.contains('communit')) {
      return 'communities';
    }
    if (t.contains('approv') ||
        t.contains('verif') ||
        t.contains('account') ||
        t.contains('admin') ||
        t.contains('broadcast')) {
      return 'account';
    }
    return 'social';
  }

  /// Whether this notification should be SHOWN given the user's category
  /// preferences (the bell list mirrors Notification Settings).
  bool allowedBy(NotificationPreferences prefs) {
    switch (category) {
      case 'messages':
        return prefs.messages;
      case 'events':
        return prefs.events;
      case 'communities':
        return prefs.communities;
      case 'account':
        return prefs.account;
      case 'social':
        return prefs.social;
      default:
        return true;
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
    String? actorId,
    String? actorName,
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
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
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
        actorId,
        actorName,
      ];
}

/// Notification Types
enum NotificationType {
  newMatch,
  newMessage,
  newLike,           // someone liked your profile
  profileView,       // someone viewed your profile
  superLike,
  matchExpiring,
  promotional,
  system,
  newChat,           // First message in a conversation
  coinsPurchased,    // Coins purchased successfully
  progressAchieved,  // Achievement unlocked
  gameInvite,        // Game invite received
  // ── Notifications overhaul (event / community / business) ──
  newEvent,          // a business you follow published an event
  groupMessage,      // a group you're in has a new message
  groupAdd,          // someone added you to a group
  groupJoin,         // someone joined your group
  communityJoin,     // someone joined your community
  communityAnnouncement,
  communityEvent,        // a community event was published
  communityEventChanged, // a community event changed (time/venue)
  eventJoin,         // someone joined your event
  eventLike,         // someone liked your event
  eventReminder,     // an event you joined is coming up / started
  eventAnnouncement, // an announcement for an event you joined
  qrScanned,         // your ticket QR is being scanned
  businessFollow,    // someone follows your business
  businessRating,    // someone rated your business
  boostStarted,      // your profile/event boost started
  boostEnded,        // your profile/event boost ended
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
      case NotificationType.newChat:
        return 'new_chat';
      case NotificationType.coinsPurchased:
        return 'coins_purchased';
      case NotificationType.progressAchieved:
        return 'progress_achieved';
      case NotificationType.gameInvite:
        return 'game_invite';
      case NotificationType.newEvent:
        return 'new_event';
      case NotificationType.groupMessage:
        return 'group_message';
      case NotificationType.groupAdd:
        return 'group_add';
      case NotificationType.groupJoin:
        return 'group_join';
      case NotificationType.communityJoin:
        return 'community_join';
      case NotificationType.communityAnnouncement:
        return 'community_announcement';
      case NotificationType.communityEvent:
        return 'community_event';
      case NotificationType.communityEventChanged:
        return 'community_event_changed';
      case NotificationType.eventJoin:
        return 'event_join';
      case NotificationType.eventLike:
        return 'event_like';
      case NotificationType.eventReminder:
        return 'event_reminder';
      case NotificationType.eventAnnouncement:
        return 'event_announcement';
      case NotificationType.qrScanned:
        return 'qr_scanned';
      case NotificationType.businessFollow:
        return 'business_follow';
      case NotificationType.businessRating:
        return 'business_rating';
      case NotificationType.boostStarted:
        return 'boost_started';
      case NotificationType.boostEnded:
        return 'boost_ended';
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
      case 'new_chat':
        return NotificationType.newChat;
      case 'coins_purchased':
        return NotificationType.coinsPurchased;
      case 'progress_achieved':
        return NotificationType.progressAchieved;
      case 'game_invite':
        return NotificationType.gameInvite;
      case 'new_event':
        return NotificationType.newEvent;
      case 'group_message':
        return NotificationType.groupMessage;
      case 'group_add':
        return NotificationType.groupAdd;
      case 'group_join':
        return NotificationType.groupJoin;
      case 'community_join':
        return NotificationType.communityJoin;
      case 'community_announcement':
        return NotificationType.communityAnnouncement;
      case 'community_event':
        return NotificationType.communityEvent;
      case 'community_event_changed':
        return NotificationType.communityEventChanged;
      case 'event_join':
        return NotificationType.eventJoin;
      case 'event_like':
        return NotificationType.eventLike;
      case 'event_reminder':
        return NotificationType.eventReminder;
      case 'event_announcement':
      case 'event_broadcast':
        return NotificationType.eventAnnouncement;
      case 'qr_scanned':
        return NotificationType.qrScanned;
      case 'business_follow':
        return NotificationType.businessFollow;
      case 'business_rating':
        return NotificationType.businessRating;
      case 'boost_started':
        return NotificationType.boostStarted;
      case 'boost_ended':
        return NotificationType.boostEnded;
      default:
        return NotificationType.system;
    }
  }
}
