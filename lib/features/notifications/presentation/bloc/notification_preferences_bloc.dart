import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_notification_preferences.dart';
import '../../domain/usecases/update_notification_preferences.dart';
import 'notification_preferences_event.dart';
import 'notification_preferences_state.dart';

/// Notification Preferences BLoC
///
/// Manages notification preferences state
class NotificationPreferencesBloc
    extends Bloc<NotificationPreferencesEvent, NotificationPreferencesState> {
  final GetNotificationPreferences getNotificationPreferences;
  final UpdateNotificationPreferences updateNotificationPreferences;

  NotificationPreferencesBloc({
    required this.getNotificationPreferences,
    required this.updateNotificationPreferences,
  }) : super(const NotificationPreferencesInitial()) {
    on<NotificationPreferencesLoadRequested>(_onLoadRequested);
    on<NotificationPreferencesUpdated>(_onUpdated);
  }

  Future<void> _onLoadRequested(
    NotificationPreferencesLoadRequested event,
    Emitter<NotificationPreferencesState> emit,
  ) async {
    emit(const NotificationPreferencesLoading());

    final result = await getNotificationPreferences(event.userId);

    result.fold(
      (failure) => emit(NotificationPreferencesError(
          'Failed to load preferences: ${failure.toString()}')),
      (preferences) => emit(NotificationPreferencesLoaded(
        preferences: preferences,
      )),
    );
  }

  Future<void> _onUpdated(
    NotificationPreferencesUpdated event,
    Emitter<NotificationPreferencesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationPreferencesLoaded) return;

    // Optimistically update UI
    emit(NotificationPreferencesLoaded(preferences: event.preferences));

    // Update in backend
    final result = await updateNotificationPreferences(event.preferences);

    result.fold(
      (failure) {
        // Revert on failure
        emit(NotificationPreferencesLoaded(
            preferences: currentState.preferences));
        emit(NotificationPreferencesError(
            'Failed to update preferences: ${failure.toString()}'));
      },
      (_) {
        // Success - keep the updated state
      },
    );
  }
}
