import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_preferences.dart';

/// Notification Preferences Events
abstract class NotificationPreferencesEvent extends Equatable {
  const NotificationPreferencesEvent();

  @override
  List<Object?> get props => [];
}

/// Load notification preferences
class NotificationPreferencesLoadRequested
    extends NotificationPreferencesEvent {

  const NotificationPreferencesLoadRequested({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Update notification preferences
class NotificationPreferencesUpdated extends NotificationPreferencesEvent {

  const NotificationPreferencesUpdated({required this.preferences});
  final NotificationPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}
