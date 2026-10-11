import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:get_it/get_it.dart';

import '../../features/admin/domain/entities/tier_config.dart';
import '../../features/business/data/services/follow_count_overlay.dart';
import '../../features/chat/presentation/widgets/message_bubble.dart';
import '../../features/discovery/data/datasources/discovery_remote_datasource.dart';
import '../../features/discovery/data/services/discovery_prefetch.dart';
import '../../features/events/data/datasources/events_remote_datasource.dart';
import '../../features/events/data/services/events_prefetch.dart';
import '../../features/gamification/data/services/chat_partner_ids.dart';
import '../../features/passport/data/services/passport_service.dart';
import '../../features/profile/data/datasources/people_tags_service.dart';
import '../../features/safety/data/services/age_assurance_service.dart';
import '../../features/subscription/data/datasources/subscription_remote_datasource.dart';
import '../cache/last_result_cache.dart';
import 'access_control_service.dart';
import 'app_sound_service.dart';
import 'blocked_users_service.dart';
import 'cache_service.dart';
import 'candidate_pool_service.dart';
import 'chat_learning_service.dart';
import 'data_preload_service.dart';
import 'location_refresh_service.dart';
import 'onboarding_gate.dart';
import 'own_profile_store.dart';
import 'presence_service.dart';
import 'pronunciation_service.dart';
import 'push_notification_service.dart';
import 'session_cache_gate.dart';
import 'sign_out_coordinator.dart';
import 'visual_vocabulary_service.dart';

/// Runs [action] only if [T] is registered in GetIt (tests / partial DI).
void _ifRegistered<T extends Object>(void Function(T it) action) {
  final sl = GetIt.instance;
  if (sl.isRegistered<T>()) action(sl<T>());
}

/// Registers every per-user activity the background sign-out must end, in
/// the order the owner asked for (UI is already on the login page):
///
/// 1. listeners  — push session statics (stops token re-attach + tap
///    routing), IAP purchase-stream listener bound to the old uid, the
///    private-profile snapshot listener (via OwnProfileStore.reset).
///    Shell-owned listeners (badge counts, entitlement, level-up,
///    achievements, notification/coin/profile/gamification blocs, activity
///    heartbeat) are cancelled by MainNavigationScreen.dispose(), which runs
///    as soon as AuthUnauthenticated swaps the shell for the login page.
/// 2. presence   — timers stopped, offline + lastSeen written once.
/// 3. push       — this device's token removed from users/{uid}, FCM token
///    deleted, shown local notifications cancelled.
/// 4. media      — sound effects + shared chat TTS player stopped. (The app
///    has no location stream, live-location sharing or foreground service.)
/// 5. localData  — every per-user in-memory / Hive cache, decoded images,
///    analytics / crashlytics user id.
/// 6. (coordinator) Google/Facebook sign-out + FirebaseAuth.signOut().
///
/// Idempotent: re-registering replaces steps by name.
void registerDefaultSignOutSteps([SignOutCoordinator? coordinator]) {
  final c = coordinator ?? SignOutCoordinator.instance;

  // ── 1. listeners / subscriptions / timers ─────────────────────────────
  c.register(SignOutPhase.listeners, 'push.sessionStatics', (_) async {
    PushNotificationService.currentUserId = null;
    PushNotificationService.activeConversationId = null;
  });
  c.register(SignOutPhase.listeners, 'iap.purchaseStreamListener', (_) async {
    _ifRegistered<SubscriptionRemoteDataSource>(
        (ds) => ds.disposePurchaseStreamListener());
  });
  c.register(SignOutPhase.listeners, 'profile.privateListener', (_) async {
    // Cancels the profiles_private/{uid} snapshot listener and drops the
    // own-profile store before the token goes away (no permission errors).
    OwnProfileStore.instance.reset();
  });

  // ── 2. presence ───────────────────────────────────────────────────────
  c.register(SignOutPhase.presence, 'presence.offline', (uid) async {
    final presence = PresenceService.instance;
    if (presence == null) return;
    if (uid != null && presence.userId != uid) return; // not the old user
    await presence.endSession();
  });

  // ── 3. push ───────────────────────────────────────────────────────────
  c.register(SignOutPhase.push, 'push.deviceToken', (uid) async {
    await PushNotificationService().signOutCleanup(uid);
  });

  // ── 4. media ──────────────────────────────────────────────────────────
  c.register(SignOutPhase.media, 'media.soundEffects', (_) async {
    await AppSoundService().stopAll();
  });
  c.register(SignOutPhase.media, 'media.chatTts', (_) async {
    await MessageBubble.stopSharedPlayback();
  });

  // ── 5. per-user local data ────────────────────────────────────────────
  c.register(SignOutPhase.localData, 'cache.sessionStores', (_) async {
    // Same set AuthWrapper clears synchronously on AuthUnauthenticated —
    // repeated here AFTER listeners stopped so nothing can repopulate them.
    OwnProfileStore.instance.reset();
    SessionCacheGate.reset();
    AccessControlService.clearSessionCache();
    DataPreloadService.instance.reset();
    LocationRefreshService.resetSession();
    EventsPrefetch.reset();
    DiscoveryPrefetch.reset();
    OnboardingGate.reset();
  });
  c.register(SignOutPhase.localData, 'cache.hive', (_) async {
    await LastResultCache.clear();
    await CacheService.instance.clearAll();
  });
  c.register(SignOutPhase.localData, 'cache.services', (uid) async {
    _ifRegistered<DiscoveryRemoteDataSource>(
        (ds) => ds.clearAllDiscoveryCaches());
    _ifRegistered<BlockedUsersService>((s) => s.clearAll());
    _ifRegistered<CandidatePoolService>((s) => s.clearCache());
    _ifRegistered<EventsRemoteDataSource>((ds) {
      if (ds is EventsRemoteDataSourceImpl) {
        ds.invalidateUserEvents(uid);
        ds.invalidateNearbyCommunity();
      }
    });
    if (uid != null) {
      _ifRegistered<PassportService>((s) => s.invalidate(uid));
      ChatPartnerIds.invalidate(uid);
    }
    PeopleTagsService.clearCache();
    ChatLearningService().clearCaches();
    VisualVocabularyService().clearMemoryCache();
    PronunciationService().clearMemoryCache();
    AgeAssuranceService.instance.invalidate();
    TierConfigProvider().clear();
    FollowCountOverlay.shared.clear();
  });
  c.register(SignOutPhase.localData, 'cache.decodedImages', (_) async {
    // Private photos the old user could see must not be served from memory.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });
  c.register(SignOutPhase.localData, 'analytics.userId', (_) async {
    await FirebaseAnalytics.instance.setUserId(id: null);
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
    }
  });
}
