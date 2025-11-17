import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Notification Preferences Entity
///
/// User's notification settings
class NotificationPreferences extends Equatable {
  final String userId;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool newMatchNotifications;
  final bool newMessageNotifications;
  final bool newLikeNotifications;
  final bool profileViewNotifications;
  final bool superLikeNotifications;
  final bool matchExpiringNotifications;
  final bool promotionalNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String quietHoursStart; // Format: "22:00"
  final String quietHoursEnd; // Format: "08:00"
  final bool quietHoursEnabled;

  const NotificationPreferences({
    required this.userId,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.newMatchNotifications = true,
    this.newMessageNotifications = true,
    this.newLikeNotifications = true,
    this.profileViewNotifications = false,
    this.superLikeNotifications = true,
    this.matchExpiringNotifications = true,
    this.promotionalNotifications = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.quietHoursEnabled = false,
  });

  /// Check if notifications are allowed at current time
  bool get isNotificationAllowedNow {
    if (!quietHoursEnabled) return true;

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    final start = _parseTimeOfDay(quietHoursStart);
    final end = _parseTimeOfDay(quietHoursEnd);

    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (start.hour > end.hour) {
      return currentTime.hour < start.hour && currentTime.hour >= end.hour;
    }

    // Handle same-day quiet hours (e.g., 12:00 to 14:00)
    return currentTime.hour < start.hour || currentTime.hour >= end.hour;
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Copy with updated fields
  NotificationPreferences copyWith({
    String? userId,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? newMatchNotifications,
    bool? newMessageNotifications,
    bool? newLikeNotifications,
    bool? profileViewNotifications,
    bool? superLikeNotifications,
    bool? matchExpiringNotifications,
    bool? promotionalNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? quietHoursEnabled,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      newMatchNotifications:
          newMatchNotifications ?? this.newMatchNotifications,
      newMessageNotifications:
          newMessageNotifications ?? this.newMessageNotifications,
      newLikeNotifications: newLikeNotifications ?? this.newLikeNotifications,
      profileViewNotifications:
          profileViewNotifications ?? this.profileViewNotifications,
      superLikeNotifications:
          superLikeNotifications ?? this.superLikeNotifications,
      matchExpiringNotifications:
          matchExpiringNotifications ?? this.matchExpiringNotifications,
      promotionalNotifications:
          promotionalNotifications ?? this.promotionalNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        pushNotificationsEnabled,
        emailNotificationsEnabled,
        newMatchNotifications,
        newMessageNotifications,
        newLikeNotifications,
        profileViewNotifications,
        superLikeNotifications,
        matchExpiringNotifications,
        promotionalNotifications,
        soundEnabled,
        vibrationEnabled,
        quietHoursStart,
        quietHoursEnd,
        quietHoursEnabled,
      ];
}
