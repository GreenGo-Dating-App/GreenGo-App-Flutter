import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_preferences.dart';

/// Notification Preferences States
abstract class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class NotificationPreferencesInitial extends NotificationPreferencesState {
  const NotificationPreferencesInitial();
}

/// Loading state
class NotificationPreferencesLoading extends NotificationPreferencesState {
  const NotificationPreferencesLoading();
}

/// Loaded state
class NotificationPreferencesLoaded extends NotificationPreferencesState {

  const NotificationPreferencesLoaded({required this.preferences});
  final NotificationPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}

/// Error state
class NotificationPreferencesError extends NotificationPreferencesState {

  const NotificationPreferencesError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
