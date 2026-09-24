import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/cache/last_result_cache.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../matching/domain/entities/match_candidate.dart';
import '../../domain/entities/match_preferences.dart';
import '../../presentation/widgets/network_grid_card.dart';
import '../datasources/discovery_remote_datasource.dart';

/// Background prefetch for Discovery (NetworkDiscoveryScreen).
///
/// Called by MainNavigationScreen once the first tab has painted. It must warm
/// the stack with the user's SAVED preferences (the same cache key the screen
/// uses). Never throws; safe to call more than once (deduplicated per session).
///
/// The preference loading, the grid-only rules and the grid cache key live here
/// so the screen and the prefetch can never drift apart: a prefetch built with
/// different preferences would warm a cache slot the screen never reads.
class DiscoveryPrefetch {
  DiscoveryPrefetch._();

  /// [LastResultCache] key for the ids of the last rendered Discovery grid.
  static const String gridCacheKey = 'network_discovery_grid_v1';

  /// Pool size the Discovery grid asks the stack for.
  static const int stackLimit = 500;

  /// Photos warmed ahead of time: the first screenful of the 3-column grid.
  static const int _photosToWarm = 9;

  static final Set<String> _started = <String>{};

  /// Forgets this session's prefetch state and the datasource's in-memory
  /// stacks/memos. Call on sign-out.
  static void reset() {
    _started.clear();
    try {
      di.sl<DiscoveryRemoteDataSource>().clearAllDiscoveryCaches();
    } catch (_) {
      // DI not ready — nothing cached yet.
    }
  }

  /// Warms the Discovery stack (in-memory, 5 min) exactly as the screen will
  /// request it, records the grid ids for an instant paint on the next cold
  /// open, and pre-downloads the first screenful of photos.
  static Future<void> warm(String userId) async {
    // The swipe build (full flavor) opens its own DiscoveryScreen/bloc, not
    // this grid, so there is nothing to warm there.
    if (!FlavorConfig.exploreFirst) return;
    if (userId.isEmpty || !_started.add(userId)) return;
    try {
      final saved = await loadSavedPreferences(userId);
      final stack = await di.sl<DiscoveryRemoteDataSource>().getDiscoveryStack(
            userId: userId,
            preferences: effectivePreferences(saved, userId),
            limit: stackLimit,
          );
      final grid = gridPool(stack, userId);
      await LastResultCache.saveIds(
        gridCacheKey,
        grid.map((c) => c.profile.userId),
      );
      final photos = grid
          .map((c) => c.profile.photoUrls.isEmpty ? '' : c.profile.photoUrls.first)
          .where((u) => u.isNotEmpty)
          .take(_photosToWarm);
      await Future.wait(photos.map(NetworkGridCard.precachePhoto));
    } catch (e) {
      // Best-effort: the screen simply loads normally. Allow a later retry.
      _started.remove(userId);
      debugPrint('[DiscoveryPrefetch] warm failed: $e');
    }
  }

  /// The user's saved filters from `users/{uid}.matchPreferences` (the document
  /// DiscoveryPreferencesScreen persists to), or null when none are saved.
  ///
  /// With [cacheOnly] the read never touches the network (instant, may be
  /// stale or missing); otherwise it is a normal server-first read.
  static Future<MatchPreferences?> loadSavedPreferences(
    String userId, {
    bool cacheOnly = false,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get(cacheOnly ? const GetOptions(source: Source.cache) : null);
    final raw = doc.data()?['matchPreferences'];
    if (raw is Map) {
      return MatchPreferences.fromMap(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  /// The saved filters merged with the rules the Apple-safe grid always
  /// enforces: orientation and verified-only are neutralised (removed as
  /// user-facing filters, so a value saved before the removal cannot keep
  /// silently excluding people), and in the culture flavor age is never a
  /// filter (forced to the full 18–99 span).
  static MatchPreferences effectivePreferences(
    MatchPreferences? saved,
    String userId,
  ) {
    final base = saved ?? MatchPreferences.defaultFor(userId);
    return base.copyWith(
      preferredOrientations: const [],
      onlyVerified: false,
      minAge: FlavorConfig.enableMatching ? base.minAge : 18,
      maxAge: FlavorConfig.enableMatching ? base.maxAge : 99,
    );
  }

  /// The stack as the grid shows it: admin accounts stay hidden (support does
  /// not — it is a real account users can reach) and the user's own tile is
  /// pinned separately, never inside the pool.
  static List<MatchCandidate> gridPool(
    List<MatchCandidate> stack,
    String userId,
  ) =>
      stack
          .where((c) => !c.profile.isAdmin)
          .where((c) => c.profile.userId != userId)
          .toList();
}
