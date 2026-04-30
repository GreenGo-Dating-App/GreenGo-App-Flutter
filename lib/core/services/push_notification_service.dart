import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../features/chat/presentation/screens/support_chat_screen.dart';
import '../../../features/chat/presentation/screens/chat_screen.dart';
import '../../../features/profile/data/models/profile_model.dart';

/// Top-level background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
  // Firebase Messaging plugin automatically shows the notification
  // when the app is in background/terminated if a `notification` payload is present.
}

/// Service for handling push notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Global navigator key — set from MaterialApp for push notification navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Current user ID — set after authentication for push notification navigation
  static String? currentUserId;

  /// Currently active conversation ID (set when user is viewing a chat).
  /// Foreground notifications for this conversation are suppressed.
  static String? activeConversationId;

  /// Android notification channel matching the one in Cloud Functions
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'greengo_notifications',
    'GreenGo Notifications',
    description: 'Push notifications from GreenGo',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize push notification handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Skip on web — uses a different (service-worker) flow.
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Initialize local notifications for foreground display
    const androidSettings = AndroidInitializationSettings('@drawable/ic_launcher_foreground');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for notification taps (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification (terminated state)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Listen for token refresh — persist new token immediately
    FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);

    _isInitialized = true;
    debugPrint('[FCM] Push notification service initialized');
  }

  /// Handle foreground messages — show a local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    // Suppress notification if user is currently viewing this conversation
    final incomingConvId = message.data['conversationId'];
    if (incomingConvId != null && incomingConvId == activeConversationId) {
      debugPrint('[FCM] Suppressed notification for active conversation $incomingConvId');
      return;
    }

    // Group key for stacking per-conversation
    final groupKey = (incomingConvId is String && incomingConvId.isNotEmpty)
        ? 'conversation_$incomingConvId'
        : null;
    final tag = (incomingConvId is String && incomingConvId.isNotEmpty)
        ? incomingConvId
        : null;

    // Notification ID: use conversationId hash so subsequent messages from the same
    // conversation REPLACE the existing card (WhatsApp behavior) rather than stacking.
    final notifId = tag != null ? tag.hashCode : notification.hashCode;

    await _localNotifications.show(
      notifId,
      notification.title ?? 'GreenGo',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_launcher_foreground',
          tag: tag,
          groupKey: groupKey,
          setAsGroupSummary: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: groupKey,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap when app was in background
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    _navigateFromNotificationData(message.data);
  }

  /// Handle tap on local notification (foreground notifications)
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        debugPrint('[FCM] Notification data: $data');
        _navigateFromNotificationData(data);
      } catch (_) {}
    }
  }

  /// Navigate based on notification data payload
  Future<void> _navigateFromNotificationData(Map<String, dynamic> data) async {
    final action = data['action'] as String?;
    final type = data['type'] as String?;
    final conversationId = data['conversationId'] as String?;
    final navigator = navigatorKey.currentState;
    final userId = currentUserId;

    if (navigator == null || userId == null) {
      debugPrint('[FCM] Cannot navigate: navigator=$navigator, userId=$userId');
      return;
    }

    // Support message → support chat
    if ((action == 'support_message' || type == 'support_message' || type == 'supportReply' || type == 'supportMessage') &&
        conversationId != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => SupportChatScreen(
            conversationId: conversationId,
            currentUserId: userId,
          ),
        ),
      );
      return;
    }

    // Regular message → chat screen
    if (type == 'newMessage' && conversationId != null) {
      await _openChatScreen(conversationId: conversationId, currentUserId: userId);
      return;
    }

    // Match — open chat with matched user (matchId == conversationId in this app)
    if (type == 'newMatch') {
      final matchId = data['matchId'] as String?;
      if (matchId != null) {
        await _openChatScreen(conversationId: matchId, currentUserId: userId);
      }
      return;
    }
  }

  /// Open ChatScreen for a given conversation. Fetches participants + other-user
  /// profile from Firestore. Silent no-op on failure.
  Future<void> _openChatScreen({
    required String conversationId,
    required String currentUserId,
  }) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    try {
      final firestore = FirebaseFirestore.instance;

      // Look up conversation to find participants
      final convDoc =
          await firestore.collection('conversations').doc(conversationId).get();
      List<String> participants = [];
      if (convDoc.exists) {
        participants =
            (convDoc.data()?['participants'] as List?)?.cast<String>() ?? [];
      }

      // Fall back to matches doc (matchId == conversationId)
      if (participants.isEmpty) {
        final matchDoc =
            await firestore.collection('matches').doc(conversationId).get();
        if (matchDoc.exists) {
          final m = matchDoc.data()!;
          participants = [
            (m['userId1'] as String?) ?? '',
            (m['userId2'] as String?) ?? '',
          ].where((s) => s.isNotEmpty).toList();
        }
      }

      if (participants.isEmpty) {
        debugPrint('[FCM] No participants for conversation $conversationId');
        return;
      }

      final otherUserId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isEmpty) return;

      final profileDoc =
          await firestore.collection('profiles').doc(otherUserId).get();
      if (!profileDoc.exists) {
        debugPrint('[FCM] Other user profile $otherUserId not found');
        return;
      }

      final profile = ProfileModel.fromFirestore(profileDoc);

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            matchId: conversationId,
            currentUserId: currentUserId,
            otherUserId: otherUserId,
            otherUserProfile: profile,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[FCM] _openChatScreen error: $e');
    }
  }

  /// Handle FCM token refresh — persist new token immediately so the user
  /// keeps receiving pushes even if the token rotates mid-session.
  void _handleTokenRefresh(String token) {
    debugPrint('[FCM] Token refreshed');
    final userId = currentUserId;
    if (userId == null) return;
    final tokenData = {
      'fcmToken': token,
      'fcmTokenUpdatedAt': Timestamp.now(),
    };
    Future.wait([
      FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .set(tokenData, SetOptions(merge: true)),
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(tokenData, SetOptions(merge: true)),
    ]).catchError((e) {
      debugPrint('[FCM] Token refresh save error: $e');
      return <void>[];
    });
  }
}

/// Global singleton instance
final pushNotificationService = PushNotificationService();
