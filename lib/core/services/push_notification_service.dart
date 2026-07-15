import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/chat/presentation/screens/chat_screen.dart';
import '../../../features/chat/presentation/screens/group_chat_screen.dart';
import '../../../features/chat/presentation/screens/support_chat_screen.dart';
import '../../../features/communities/domain/repositories/communities_repository.dart';
import '../../../features/communities/presentation/bloc/communities_bloc.dart';
import '../../../features/communities/presentation/screens/community_detail_screen.dart';
import '../../../features/discovery/presentation/screens/profile_detail_screen.dart';
import '../../../features/events/presentation/screens/event_detail_loader_screen.dart';
import '../../../features/profile/data/models/profile_model.dart';
import '../../../features/profile/domain/repositories/profile_repository.dart';
import '../../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../../features/profile/presentation/bloc/profile_event.dart';
import '../di/injection_container.dart' as di;
import 'app_sound_service.dart';

/// Top-level background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
  // Firebase Messaging plugin automatically shows the notification
  // when the app is in background/terminated if a `notification` payload is present.
}

/// Service for handling push notifications
class PushNotificationService {
  factory PushNotificationService() => _instance;
  PushNotificationService._();
  static final PushNotificationService _instance = PushNotificationService._();

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

    // Web uses a service-worker flow (web/firebase-messaging-sw.js) for
    // background/closed-tab notifications, and has no flutter_local_notifications
    // or background isolate handler. We still wire the foreground/tap/refresh
    // listeners so in-app sounds + deep-navigation on click work on web too.
    if (kIsWeb) {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);
      _isInitialized = true;
      debugPrint('[FCM] Push notification service initialized (web)');
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

  /// Foreground messages: do NOT show an OS/local notification while the app is
  /// in use. `FirebaseMessaging.onMessage` fires only when the app is in the
  /// foreground; backgrounded/terminated messages are displayed by the OS
  /// automatically (not via this handler). The in-app notifications list
  /// (Firestore `notifications`) still updates, so the user still sees it
  /// inside the app — they just don't get a phone notification while using it.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
        '[FCM] Foreground message ${message.messageId} — not shown (app in use)');
    // No OS notification while the app is open, but play an in-app sound
    // effect (WhatsApp-style) based on context:
    //  - viewing this chat        -> "message sent" sound
    //  - super-like / first msg   -> "new message (first time)" sound
    //  - message from existing chat -> "new message" sound
    try {
      final data = message.data;
      final convId = data['conversationId'];
      final type = (data['type'] ?? data['notificationType'] ?? '')
          .toString()
          .toLowerCase();
      if (convId != null && convId == activeConversationId) {
        AppSoundService().play(AppSound.messageSent);
      } else if (type.contains('super')) {
        AppSoundService().play(AppSound.newMessageFirstTime);
      } else if (type.contains('chat')) {
        // 'new_chat' = first message from this user.
        AppSoundService().play(AppSound.newMessageFirstTime);
      } else if (type.contains('message')) {
        AppSoundService().play(AppSound.newMessage);
      }
    } catch (_) {}
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
    if (type == 'newMatch' && (data['matchId'] as String?) != null) {
      await _openChatScreen(
          conversationId: data['matchId'] as String, currentUserId: userId);
      return;
    }

    // ── Parity with the in-app notifications router ─────────────────────────
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    // EVENT (community_event / event_reminder / new_event / event_join / like…)
    final eventId = pick(['eventId']);
    if (action == 'event' || action == 'open_event' || eventId != null) {
      if (eventId != null) {
        navigator.push(
          EventDetailLoaderScreen.route(eventId: eventId, currentUserId: userId),
        );
      }
      return;
    }

    // COMMUNITY — must precede group (community_join / announcement / event).
    final communityId = pick(['communityId']);
    if (action == 'community' ||
        action == 'open_community' ||
        communityId != null) {
      if (communityId != null) await _openCommunityById(communityId, userId);
      return;
    }

    // GROUP chat (group_add / group_join / group message).
    final groupId = pick(['groupId']);
    if (action == 'group' || action == 'open_group' || groupId != null) {
      if (groupId != null) {
        navigator.push(
          GroupChatScreen.route(
            groupId: groupId,
            groupName: (data['groupName'] as String?) ?? '',
            currentUserId: userId,
            groupPhotoUrl: data['groupPhotoUrl'] as String?,
          ),
        );
      }
      return;
    }

    // PROFILE (like / super-like / profile view / business follow-rate / QR).
    final profileId = pick([
      'actorId',
      'profileId',
      'likerId',
      'matchedUserId',
      'targetUserId',
      'fromUserId',
      'senderId',
    ]);
    if (action == 'profile' ||
        action == 'profile_view' ||
        action == 'open_profile' ||
        type == 'newLike' ||
        type == 'superLike' ||
        type == 'profileView' ||
        type == 'business_follow' ||
        type == 'business_rating' ||
        type == 'qr_scanned' ||
        (profileId != null && action == null && type == null)) {
      if (profileId != null && profileId != userId) {
        await _openProfileById(profileId, userId);
      }
      return;
    }
  }

  /// Loads a community by id and opens [CommunityDetailScreen] (with its blocs).
  Future<void> _openCommunityById(String communityId, String userId) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    try {
      final result =
          await di.sl<CommunitiesRepository>().getCommunityById(communityId);
      final community = result.fold((_) => null, (c) => c);
      if (community == null) return;
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<CommunitiesBloc>(
                create: (_) => di.sl<CommunitiesBloc>(),
              ),
              BlocProvider<ProfileBloc>(
                create: (_) => di.sl<ProfileBloc>()
                  ..add(ProfileLoadRequested(userId: userId)),
              ),
            ],
            child: CommunityDetailScreen(community: community),
          ),
        ),
      );
    } catch (_) {/* silent */}
  }

  /// Loads a profile by id and opens [ProfileDetailScreen] (self-safe).
  Future<void> _openProfileById(String profileId, String userId) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    try {
      final result = await di.sl<ProfileRepository>().getProfile(profileId);
      final profile = result.fold((_) => null, (p) => p);
      if (profile == null) return;
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ProfileDetailScreen(
            profile: profile,
            currentUserId: userId,
          ),
        ),
      );
    } catch (_) {/* silent */}
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
      var participants = <String>[];
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
