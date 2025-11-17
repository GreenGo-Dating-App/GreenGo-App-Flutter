import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification.dart';
import '../entities/notification_preferences.dart';

/// Notification Repository
///
/// Contract for notification data operations
abstract class NotificationRepository {
  /// Get user's notifications stream (real-time)
  Stream<Either<Failure, List<NotificationEntity>>> getNotificationsStream(
    String userId, {
    bool unreadOnly = false,
    int? limit,
  });

  /// Mark notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead(String userId);

  /// Delete notification
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Get unread count
  Future<Either<Failure, int>> getUnreadCount(String userId);

  /// Create notification
  Future<Either<Failure, NotificationEntity>> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  });

  /// Get notification preferences
  Future<Either<Failure, NotificationPreferences>> getPreferences(
      String userId);

  /// Update notification preferences
  Future<Either<Failure, void>> updatePreferences(
      NotificationPreferences preferences);

  /// Request push notification permission
  Future<Either<Failure, bool>> requestPermission();

  /// Get FCM token
  Future<Either<Failure, String?>> getFCMToken();

  /// Save FCM token to Firestore
  Future<Either<Failure, void>> saveFCMToken(String userId, String token);
}
