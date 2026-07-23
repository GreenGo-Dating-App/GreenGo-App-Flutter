import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Notification Preferences Entity.
///
/// Per-category push controls for the repositioned (non-dating) product, plus
/// sound/vibration, quiet hours, and the list of cities the user wants event
/// alerts for. Firestore stores the five categories under a `categories` map
/// (see the model); the entity keeps them flat for convenience.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    required this.userId,
    this.pushEnabled = true,
    // Granular per-channel categories. Defaults: only exchanges (1:1), groups,
    // community announcements and event chats are ON; business chat, community
    // chat and tips are OFF until the user opts in.
    this.exchanges = true,
    this.groups = true,
    this.eventsChat = true,
    this.communityChat = false,
    this.announcements = true,
    this.tips = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.quietHoursEnabled = false,
    this.eventCities = const [],
  });

  final String userId;

  /// Master switch — off silences every push (OS permission is separate).
  final bool pushEnabled;

  // ── Categories (per notification channel) ────────────────────────────────
  /// 1:1 "exchange" chats (person-to-person). Default ON.
  final bool exchanges;

  /// Group chats. Default ON.
  final bool groups;

  /// Event chats (messages inside an event). Default ON.
  final bool eventsChat;

  /// Community chats (the community chat tab). Default OFF.
  final bool communityChat;

  /// Community announcements + community events. Default ON.
  final bool announcements;

  /// Community tips. Default OFF.
  final bool tips;

  // ── Delivery ─────────────────────────────────────────────────────────────
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String quietHoursStart; // "22:00"
  final String quietHoursEnd; // "08:00"
  final bool quietHoursEnabled;

  /// Normalized city keys the user subscribed to for event alerts.
  final List<String> eventCities;

  /// Whether notifications are allowed at the current time (quiet hours).
  bool get isNotificationAllowedNow {
    if (!quietHoursEnabled) return true;
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    final start = _parseTimeOfDay(quietHoursStart);
    final end = _parseTimeOfDay(quietHoursEnd);
    if (start.hour > end.hour) {
      // Overnight window, e.g. 22:00 → 08:00.
      return currentTime.hour < start.hour && currentTime.hour >= end.hour;
    }
    return currentTime.hour < start.hour || currentTime.hour >= end.hour;
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  NotificationPreferences copyWith({
    String? userId,
    bool? pushEnabled,
    bool? exchanges,
    bool? groups,
    bool? eventsChat,
    bool? communityChat,
    bool? announcements,
    bool? tips,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? quietHoursEnabled,
    List<String>? eventCities,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      exchanges: exchanges ?? this.exchanges,
      groups: groups ?? this.groups,
      eventsChat: eventsChat ?? this.eventsChat,
      communityChat: communityChat ?? this.communityChat,
      announcements: announcements ?? this.announcements,
      tips: tips ?? this.tips,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      eventCities: eventCities ?? this.eventCities,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        pushEnabled,
        exchanges,
        groups,
        eventsChat,
        communityChat,
        announcements,
        tips,
        soundEnabled,
        vibrationEnabled,
        quietHoursStart,
        quietHoursEnd,
        quietHoursEnabled,
        eventCities,
      ];
}
