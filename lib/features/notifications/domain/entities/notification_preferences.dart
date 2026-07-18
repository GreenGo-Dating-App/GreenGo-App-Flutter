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
    this.messages = true,
    this.events = true,
    this.communities = true,
    this.social = true,
    this.account = true,
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

  // ── Categories ───────────────────────────────────────────────────────────
  /// 1:1, group, business and event chat + support replies.
  final bool messages;

  /// Community/business events, reminders, RSVPs, broadcasts, city alerts.
  final bool events;

  /// Community announcements and new members.
  final bool communities;

  /// Profile views, business follows/ratings, boosts.
  final bool social;

  /// Verification, admin broadcasts, account status.
  final bool account;

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
    bool? messages,
    bool? events,
    bool? communities,
    bool? social,
    bool? account,
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
      messages: messages ?? this.messages,
      events: events ?? this.events,
      communities: communities ?? this.communities,
      social: social ?? this.social,
      account: account ?? this.account,
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
        messages,
        events,
        communities,
        social,
        account,
        soundEnabled,
        vibrationEnabled,
        quietHoursStart,
        quietHoursEnd,
        quietHoursEnabled,
        eventCities,
      ];
}
