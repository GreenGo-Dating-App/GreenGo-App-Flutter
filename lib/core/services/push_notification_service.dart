import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../features/chat/presentation/screens/support_chat_screen.dart';

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

    // Listen for token refresh
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
    if (incomingConvId != null &&
        incomingConvId == activeConversationId) {
      debugPrint('[FCM] Suppressed notification for active conversation $incomingConvId');
      return;
    }

    // Show local notification so user sees it in foreground
    await _localNotifications.show(
      notification.hashCode,
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
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
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
  void _navigateFromNotificationData(Map<String, dynamic> data) {
    final action = data['action'] as String?;
    final type = data['type'] as String?;
    final conversationId = data['conversationId'] as String?;
    final navigator = navigatorKey.currentState;
    final userId = currentUserId;

    if (navigator == null || userId == null) {
      debugPrint('[FCM] Cannot navigate: navigator=$navigator, userId=$userId');
      return;
    }

    // Support message notification → open the support chat
    if ((action == 'support_message' || type == 'support_message') &&
        conversationId != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => SupportChatScreen(
            conversationId: conversationId,
            currentUserId: userId,
          ),
        ),
      );
    }
  }

  /// Handle FCM token refresh — save new token to Firestore
  void _handleTokenRefresh(String token) {
    debugPrint('[FCM] Token refreshed');
    // Token will be saved on next app start via the existing flow
    // The token is also refreshed in the notification datasource
  }
}

/// Global singleton instance
final pushNotificationService = PushNotificationService();
