import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_notification_read.dart';
import '../../domain/usecases/mark_all_notifications_read.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

/// Notifications BLoC
///
/// Manages notifications state and real-time updates
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotifications getNotifications;
  final MarkNotificationRead markNotificationRead;
  final MarkAllNotificationsRead markAllNotificationsRead;

  String? _userId;

  NotificationsBloc({
    required this.getNotifications,
    required this.markNotificationRead,
    required this.markAllNotificationsRead,
  }) : super(const NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationMarkedAsRead>(_onMarkedAsRead);
    on<NotificationsMarkedAllAsRead>(_onMarkedAllAsRead);
    on<NotificationDeleted>(_onDeleted);
    on<NotificationTapped>(_onTapped);
  }

  Future<void> _onLoadRequested(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());

    _userId = event.userId;

    try {
      // Add timeout to prevent endless loading
      final stream = getNotifications(
        GetNotificationsParams(
          userId: event.userId,
          unreadOnly: event.unreadOnly,
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: (sink) {
          debugPrint('[NotificationsBloc] Stream timeout - closing sink');
          sink.close();
        },
      );

      // Use emit.forEach to properly handle stream emissions within bloc
      await emit.forEach(
        stream,
        onData: (notificationsResult) {
          return notificationsResult.fold(
            (failure) => NotificationsError(
                'Failed to load notifications: ${failure.toString()}'),
            (notifications) {
              if (notifications.isEmpty) {
                return const NotificationsEmpty();
              } else {
                return NotificationsLoaded(
                  notifications: notifications,
                  unreadCount: notifications.where((n) => !n.isRead).length,
                );
              }
            },
          );
        },
      );
    } on TimeoutException {
      debugPrint('[NotificationsBloc] Timeout loading notifications');
      emit(const NotificationsError('Loading notifications timed out. Please try again.'));
    } catch (e) {
      debugPrint('[NotificationsBloc] Error loading notifications: $e');
      emit(NotificationsError('Failed to load notifications: ${e.toString()}'));
    }
  }

  Future<void> _onMarkedAsRead(
    NotificationMarkedAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    await markNotificationRead(event.notificationId);
    // State will be updated via stream
  }

  Future<void> _onMarkedAllAsRead(
    NotificationsMarkedAllAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    await markAllNotificationsRead(event.userId);
    // State will be updated via stream
  }

  Future<void> _onDeleted(
    NotificationDeleted event,
    Emitter<NotificationsState> emit,
  ) async {
    // TODO: Implement delete functionality
    // For now, just mark as read
    await markNotificationRead(event.notificationId);
  }

  Future<void> _onTapped(
    NotificationTapped event,
    Emitter<NotificationsState> emit,
  ) async {
    // Mark as read when tapped
    await markNotificationRead(event.notificationId);

    // Navigation will be handled by UI layer using actionUrl
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
