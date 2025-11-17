import 'dart:async';
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

  StreamSubscription? _notificationsSubscription;
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

    // Cancel existing subscription
    await _notificationsSubscription?.cancel();

    // Start listening to notifications
    _notificationsSubscription = getNotifications(
      GetNotificationsParams(
        userId: event.userId,
        unreadOnly: event.unreadOnly,
      ),
    ).listen((notificationsResult) {
      notificationsResult.fold(
        (failure) {
          emit(NotificationsError(
              'Failed to load notifications: ${failure.toString()}'));
        },
        (notifications) {
          if (notifications.isEmpty) {
            emit(const NotificationsEmpty());
          } else {
            emit(NotificationsLoaded(
              notifications: notifications,
              unreadCount: notifications.where((n) => !n.isRead).length,
            ));
          }
        },
      );
    });
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
    _notificationsSubscription?.cancel();
    return super.close();
  }
}
