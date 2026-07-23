import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_preferences.dart';

/// Data-layer model for [NotificationPreferences] with Firestore serialization.
///
/// Firestore shape (`notification_preferences/{uid}`):
/// ```
/// { pushEnabled, categories: {messages,events,communities,social,account},
///   soundEnabled, vibrationEnabled, quietHoursEnabled, quietHoursStart/End,
///   eventCities: [] }
/// ```
/// The Cloud Functions gate (`shouldNotify`) reads the same `categories` map.
class NotificationPreferencesModel extends NotificationPreferences {
  const NotificationPreferencesModel({
    required super.userId,
    super.pushEnabled,
    super.exchanges,
    super.groups,
    super.eventsChat,
    super.communityChat,
    super.announcements,
    super.tips,
    super.soundEnabled,
    super.vibrationEnabled,
    super.quietHoursStart,
    super.quietHoursEnd,
    super.quietHoursEnabled,
    super.eventCities,
  });

  factory NotificationPreferencesModel.fromEntity(NotificationPreferences p) {
    return NotificationPreferencesModel(
      userId: p.userId,
      pushEnabled: p.pushEnabled,
      exchanges: p.exchanges,
      groups: p.groups,
      eventsChat: p.eventsChat,
      communityChat: p.communityChat,
      announcements: p.announcements,
      tips: p.tips,
      soundEnabled: p.soundEnabled,
      vibrationEnabled: p.vibrationEnabled,
      quietHoursStart: p.quietHoursStart,
      quietHoursEnd: p.quietHoursEnd,
      quietHoursEnabled: p.quietHoursEnabled,
      eventCities: p.eventCities,
    );
  }

  factory NotificationPreferencesModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final cats = data?['categories'] as Map<String, dynamic>?;

    // Read a category flag from the nested map, defaulting to opt-in (true) so
    // users who never touched settings still get notified.
    bool cat(String key, {bool def = true}) =>
        (cats?[key] as bool?) ?? (data?[key] as bool?) ?? def;

    return NotificationPreferencesModel(
      userId: doc.id,
      // Accept the legacy `pushNotificationsEnabled` key as a fallback.
      pushEnabled: (data?['pushEnabled'] as bool?) ??
          (data?['pushNotificationsEnabled'] as bool?) ??
          true,
      // Per-category defaults (used when a user never customized settings):
      // exchanges/groups/eventsChat/announcements ON, business/communityChat/
      // tips OFF. Legacy `messages`/`communities` keys seed sensible fallbacks.
      exchanges: cat('exchanges', def: cat('messages')),
      groups: cat('groups', def: cat('messages')),
      eventsChat: cat('eventsChat', def: cat('events')),
      communityChat: cat('communityChat', def: false),
      announcements: cat('announcements', def: cat('communities')),
      tips: cat('tips', def: false),
      soundEnabled: data?['soundEnabled'] as bool? ?? true,
      vibrationEnabled: data?['vibrationEnabled'] as bool? ?? true,
      quietHoursStart: data?['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: data?['quietHoursEnd'] as String? ?? '08:00',
      quietHoursEnabled: data?['quietHoursEnabled'] as bool? ?? false,
      eventCities:
          (data?['eventCities'] as List?)?.whereType<String>().toList() ??
              const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pushEnabled': pushEnabled,
      'categories': {
        'exchanges': exchanges,
        'groups': groups,
        'eventsChat': eventsChat,
        'communityChat': communityChat,
        'announcements': announcements,
        'tips': tips,
      },
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursEnabled': quietHoursEnabled,
      'eventCities': eventCities,
      // Device UTC offset so the server can evaluate quiet hours in local time.
      'tzOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  NotificationPreferences toEntity() => NotificationPreferences(
        userId: userId,
        pushEnabled: pushEnabled,
        exchanges: exchanges,
        groups: groups,
        eventsChat: eventsChat,
        communityChat: communityChat,
        announcements: announcements,
        tips: tips,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
        quietHoursEnabled: quietHoursEnabled,
        eventCities: eventCities,
      );
}
