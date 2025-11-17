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
  final NotificationPreferences preferences;

  const NotificationPreferencesLoaded({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

/// Error state
class NotificationPreferencesError extends NotificationPreferencesState {
  final String message;

  const NotificationPreferencesError(this.message);

  @override
  List<Object?> get props => [message];
}
