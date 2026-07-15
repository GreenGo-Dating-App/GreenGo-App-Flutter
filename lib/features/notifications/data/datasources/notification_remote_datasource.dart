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

  /// Permanently delete ALL unread notifications for the user.
  Future<void> deleteAllUnread(String userId);

  /// Permanently delete ALL notifications (read + unread) for the user.
  Future<void> deleteAll(String userId);

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

  NotificationRemoteDataSourceImpl({
    required this.firestore,
    required this.messaging,
  });
  final FirebaseFirestore firestore;
  final FirebaseMessaging messaging;

  @override
  Stream<List<NotificationModel>> getNotificationsStream(
    String userId, {
    bool unreadOnly = false,
    int? limit,
  }) {
    // Index-light query: filter by `userId` equality only (served by
    // Firestore's automatic single-field index — no composite index needed).
    // Ordering by `createdAt` + this `where` would require a composite index
    // that, when absent, makes `snapshots()` error out and the page hang.
    // We therefore sort (newest first) and cap the list client-side instead.
    final cap = limit ?? 100;

    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        // Bounded reads (G0): cap the SERVER query so it bills at most `cap`
        // docs, not every notification the user ever had. Order within the cap
        // is arbitrary (no composite index) — the client re-sorts newest-first
        // below, which is fine for a notifications badge/list.
        .limit(cap)
        .snapshots()
        .map((snapshot) {
      // Parse each doc defensively: a single unparseable doc must not error the
      // whole stream (which surfaced to the user as "server failure"). Skip any
      // that still throw despite the tolerant [NotificationModel.fromFirestore].
      var items = <NotificationModel>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(NotificationModel.fromFirestore(doc));
        } catch (_) {
          // Ignore this malformed notification doc and keep the rest.
        }
      }

      if (unreadOnly) {
        items = items.where((n) => !n.isRead).toList();
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (items.length > cap) {
        items = items.sublist(0, cap);
      }

      return items;
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
          .limit(500)
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
  Future<void> deleteAllUnread(String userId) async {
    try {
      // Page + batch-delete so large inboxes stay within the 500-op batch cap.
      while (true) {
        final snapshot = await firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .limit(400)
            .get();
        if (snapshot.docs.isEmpty) break;

        final batch = firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (snapshot.docs.length < 400) break;
      }
    } catch (e) {
      throw Exception('Failed to delete unread notifications: $e');
    }
  }

  @override
  Future<void> deleteAll(String userId) async {
    try {
      // Delete EVERY notification for the user (read + unread), paged/batched.
      while (true) {
        final snapshot = await firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .limit(400)
            .get();
        if (snapshot.docs.isEmpty) break;

        final batch = firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (snapshot.docs.length < 400) break;
      }
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
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
      final tokenData = {
        'fcmToken': token,
        'fcmTokenUpdatedAt': Timestamp.now(),
      };
      // Save to both 'profiles' (used by Cloud Functions for push)
      // and 'users' (legacy) to ensure notifications work
      await Future.wait([
        firestore.collection('profiles').doc(userId).set(
          tokenData,
          SetOptions(merge: true),
        ),
        firestore.collection('users').doc(userId).set(
          tokenData,
          SetOptions(merge: true),
        ),
      ]);
    } catch (e) {
      throw Exception('Failed to save FCM token: $e');
    }
  }
}
