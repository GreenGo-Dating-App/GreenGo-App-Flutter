import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../domain/entities/notification.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences_model.dart';

/// Notification Remote Data Source
///
/// Handles Firestore and FCM operations for notifications
abstract class NotificationRemoteDataSource {
  /// Stream of user's notifications
  Stream<List<NotificationModel>> getNotificationsStream(
    String userId, {
    bool unreadOnly = false,
    int? limit,
  });

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all as read
  Future<void> markAllAsRead(String userId);

  /// Delete notification
  Future<void> deleteNotification(String notificationId);

  /// Get unread count
  Future<int> getUnreadCount(String userId);

  /// Create notification
  Future<NotificationModel> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  });

  /// Get preferences
  Future<NotificationPreferencesModel> getPreferences(String userId);

  /// Update preferences
  Future<void> updatePreferences(NotificationPreferencesModel preferences);

  /// Request permission
  Future<bool> requestPermission();

  /// Get FCM token
  Future<String?> getFCMToken();

  /// Save FCM token
  Future<void> saveFCMToken(String userId, String token);
}

/// Implementation
class NotificationRemoteDataSourceImpl
    implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseMessaging messaging;

  NotificationRemoteDataSourceImpl({
    required this.firestore,
    required this.messaging,
  });

  @override
  Stream<List<NotificationModel>> getNotificationsStream(
    String userId, {
    bool unreadOnly = false,
    int? limit,
  }) {
    Query query = firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = firestore.batch();

      final snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Future<NotificationModel> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  }) async {
    try {
      final docRef = firestore.collection('notifications').doc();

      final notification = NotificationModel(
        notificationId: docRef.id,
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
        createdAt: DateTime.now(),
        isRead: false,
        actionUrl: actionUrl,
        imageUrl: imageUrl,
      );

      await docRef.set(notification.toFirestore());

      return notification;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  @override
  Future<NotificationPreferencesModel> getPreferences(String userId) async {
    try {
      final doc =
          await firestore.collection('notification_preferences').doc(userId).get();

      if (doc.exists) {
        return NotificationPreferencesModel.fromFirestore(doc);
      }

      // Return default preferences
      return NotificationPreferencesModel(userId: userId);
    } catch (e) {
      throw Exception('Failed to get notification preferences: $e');
    }
  }

  @override
  Future<void> updatePreferences(
      NotificationPreferencesModel preferences) async {
    try {
      await firestore
          .collection('notification_preferences')
          .doc(preferences.userId)
          .set(preferences.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      throw Exception('Failed to request permission: $e');
    }
  }

  @override
  Future<String?> getFCMToken() async {
    try {
      return await messaging.getToken();
    } catch (e) {
      throw Exception('Failed to get FCM token: $e');
    }
  }

  @override
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save FCM token: $e');
    }
  }
}
