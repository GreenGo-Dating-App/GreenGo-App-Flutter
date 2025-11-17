import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_preferences.dart';

/// Notification Preferences Model
///
/// Data layer model for NotificationPreferences with Firestore serialization
class NotificationPreferencesModel extends NotificationPreferences {
  const NotificationPreferencesModel({
    required super.userId,
    super.pushNotificationsEnabled,
    super.emailNotificationsEnabled,
    super.newMatchNotifications,
    super.newMessageNotifications,
    super.newLikeNotifications,
    super.profileViewNotifications,
    super.superLikeNotifications,
    super.matchExpiringNotifications,
    super.promotionalNotifications,
    super.soundEnabled,
    super.vibrationEnabled,
    super.quietHoursStart,
    super.quietHoursEnd,
    super.quietHoursEnabled,
  });

  /// Create from NotificationPreferences
  factory NotificationPreferencesModel.fromEntity(
      NotificationPreferences prefs) {
    return NotificationPreferencesModel(
      userId: prefs.userId,
      pushNotificationsEnabled: prefs.pushNotificationsEnabled,
      emailNotificationsEnabled: prefs.emailNotificationsEnabled,
      newMatchNotifications: prefs.newMatchNotifications,
      newMessageNotifications: prefs.newMessageNotifications,
      newLikeNotifications: prefs.newLikeNotifications,
      profileViewNotifications: prefs.profileViewNotifications,
      superLikeNotifications: prefs.superLikeNotifications,
      matchExpiringNotifications: prefs.matchExpiringNotifications,
      promotionalNotifications: prefs.promotionalNotifications,
      soundEnabled: prefs.soundEnabled,
      vibrationEnabled: prefs.vibrationEnabled,
      quietHoursStart: prefs.quietHoursStart,
      quietHoursEnd: prefs.quietHoursEnd,
      quietHoursEnabled: prefs.quietHoursEnabled,
    );
  }

  /// Create from Firestore document
  factory NotificationPreferencesModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    return NotificationPreferencesModel(
      userId: doc.id,
      pushNotificationsEnabled: data?['pushNotificationsEnabled'] as bool? ?? true,
      emailNotificationsEnabled: data?['emailNotificationsEnabled'] as bool? ?? true,
      newMatchNotifications: data?['newMatchNotifications'] as bool? ?? true,
      newMessageNotifications: data?['newMessageNotifications'] as bool? ?? true,
      newLikeNotifications: data?['newLikeNotifications'] as bool? ?? true,
      profileViewNotifications: data?['profileViewNotifications'] as bool? ?? false,
      superLikeNotifications: data?['superLikeNotifications'] as bool? ?? true,
      matchExpiringNotifications: data?['matchExpiringNotifications'] as bool? ?? true,
      promotionalNotifications: data?['promotionalNotifications'] as bool? ?? false,
      soundEnabled: data?['soundEnabled'] as bool? ?? true,
      vibrationEnabled: data?['vibrationEnabled'] as bool? ?? true,
      quietHoursStart: data?['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: data?['quietHoursEnd'] as String? ?? '08:00',
      quietHoursEnabled: data?['quietHoursEnabled'] as bool? ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'newMatchNotifications': newMatchNotifications,
      'newMessageNotifications': newMessageNotifications,
      'newLikeNotifications': newLikeNotifications,
      'profileViewNotifications': profileViewNotifications,
      'superLikeNotifications': superLikeNotifications,
      'matchExpiringNotifications': matchExpiringNotifications,
      'promotionalNotifications': promotionalNotifications,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursEnabled': quietHoursEnabled,
    };
  }

  /// Convert to NotificationPreferences entity
  NotificationPreferences toEntity() {
    return NotificationPreferences(
      userId: userId,
      pushNotificationsEnabled: pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled,
      newMatchNotifications: newMatchNotifications,
      newMessageNotifications: newMessageNotifications,
      newLikeNotifications: newLikeNotifications,
      profileViewNotifications: profileViewNotifications,
      superLikeNotifications: superLikeNotifications,
      matchExpiringNotifications: matchExpiringNotifications,
      promotionalNotifications: promotionalNotifications,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled,
    );
  }
}
