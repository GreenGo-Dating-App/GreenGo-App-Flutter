import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/conversation_queries.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/blocked_users_service.dart';
import '../../../matching/data/datasources/matching_remote_datasource.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../../matching/domain/entities/match_preferences.dart' as matching;
import '../../../matching/domain/entities/match_score.dart';
import '../../../matching/domain/usecases/feature_engineer.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/discovery_visibility.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_preferences.dart';
import '../../domain/entities/swipe_action.dart';
import '../models/match_model.dart';
import '../models/swipe_action_model.dart';
import '../../../../core/services/effective_tier.dart';

/// Discovery Remote Data Source Interface
abstract class DiscoveryRemoteDataSource {
  /// Whether the last getDiscoveryStack call used the worldwide fallback
  /// (country pool had fewer than 500 candidates)
  bool get lastUsedWorldwideFallback;

  Future<List<MatchCandidate>> getDiscoveryStack({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
    bool forceRefresh = false,
  });

  /// A small, cheap "people around you" strip (Explore): a few bounded
  /// same-city / same-country reads instead of the full discovery stack, with
  /// the SAME visibility rules (blocked, ghost, incognito, testers, incomplete
  /// profiles, admin/support, recent passes) and priority order as
  /// [getDiscoveryStack]. Business accounts are excluded (they have their own
  /// section). Falls back to the full stack when [viewer] has no location.
  Future<List<MatchCandidate>> getNearbyPeople({
    required String userId,
    required Profile viewer,
    int limit = 15,
  });

  /// Clears the in-memory discovery cache for a user
  void clearDiscoveryCache(String userId);

  /// Clears all in-memory discovery caches
  void clearAllDiscoveryCaches();

  Future<SwipeAction> recordSwipe({
    required String userId,
    required String targetUserId,
    required SwipeActionType actionType,
  });

  Future<Match?> checkForMatch({
    required String userId,
    required String targetUserId,
  });

  Future<List<Match>> getMatches({
    required String userId,
    bool activeOnly = true,
  });

  Future<(Match, Profile)> getMatchWithProfile({
    required String matchId,
    required String currentUserId,
  });

  Future<void> markMatchAsSeen({
    required String matchId,
    required String userId,
  });

  Future<void> unmatch({
    required String matchId,
    required String userId,
  });

  Future<List<String>> getUserLikes(String userId);

  Future<List<Profile>> getWhoLikedMe(String userId);

  Future<bool> hasSwipedOn({
    required String userId,
    required String targetUserId,
  });

  /// Search for a profile by nickname
  Future<Profile?> searchByNickname(String nickname);

  /// Undo (delete) the most recent swipe on a target user
  Future<void> undoSwipe({
    required String userId,
    required String targetUserId,
  });

  /// Activate profile boost for 30 minutes
  Future<DateTime> activateBoost(String userId);
}

/// Simple container for a cached discovery result
class _CachedStack {

  _CachedStack(this.candidates, this.preferencesHash) : fetchedAt = DateTime.now();
  final List<MatchCandidate> candidates;
  final DateTime fetchedAt;
  final String preferencesHash;
  static const ttl = Duration(minutes: 5);

  bool isValid(String currentHash) =>
      DateTime.now().difference(fetchedAt) < ttl && preferencesHash == currentHash;
}

/// Discovery Remote Data Source Implementation
class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {

  DiscoveryRemoteDataSourceImpl({
    required this.firestore,
    required this.matchingDataSource,
    required this.blockedUsersService,
  });
  final FirebaseFirestore firestore;
  final MatchingRemoteDataSource matchingDataSource;
  final BlockedUsersService blockedUsersService;

  @override
  bool lastUsedWorldwideFallback = false;

  // In-memory LRU keyed by `userId|preferencesHash` — survives bloc recreation
  // (datasource is singleton). A few slots so Explore, Discovery and the
  // background prefetch don't evict each other's stacks.
  final Map<String, _CachedStack> _cache = {}; // insertion-ordered (LRU)
  static const int _maxCachedStacks = 3;

  // Explore's full-stack FALLBACK (getNearbyPeople in a sparse area) keeps its
  // own single slot so it can never evict the real Discovery grid.
  (String, _CachedStack)? _nearbyFallback;

  // Recent swipe history, shared by the stack and the Explore strip so both
  // honour the same 90-day window without reading it twice. Dropped on every
  // swipe / undo.
  (String, DateTime, Map<String, _SwipeRecord>)? _swipeMemo;

  // Cached admin candidate (session-level, avoids query on every discovery load)
  MatchCandidate? _cachedAdminCandidate;
  DateTime? _adminCacheFetchedAt;
  static const _adminCacheTtl = Duration(hours: 1);

  // Cached current user profile to avoid re-reading on every load
  Map<String, dynamic>? _cachedUserProfile;
  String? _cachedUserProfileId;

  @override
  void clearDiscoveryCache(String userId) {
    _cache.removeWhere((key, _) => key.startsWith('$userId|'));
    if (_nearbyFallback?.$1 == userId) _nearbyFallback = null;
    debugPrint('[Discovery] Cache cleared for $userId');
  }

  /// Also drops every other per-user memo (viewer profile, swipe history,
  /// the Explore fallback stack, the admin card) — call on sign-out.
  @override
  void clearAllDiscoveryCaches() {
    _cache.clear();
    _nearbyFallback = null;
    _swipeMemo = null;
    _cachedUserProfile = null;
    _cachedUserProfileId = null;
    _cachedAdminCandidate = null;
    _adminCacheFetchedAt = null;
    debugPrint('[Discovery] All caches cleared');
  }

  /// Cache key: every preference that changes the resulting stack. (It used
  /// to miss showSupportUser, onlyRecentlyActive, dealBreakers and
  /// localGuidesOnly, so a stack built for one set could be served for another.)
  static String _preferencesHash(MatchPreferences p) =>
      '${p.preferredCountries.join(',')}'
      '|${p.interestedInGender}'
      '|${p.minAge}-${p.maxAge}'
      '|${p.maxDistanceKm}'
      '|${p.randomMode}'
      '|${p.onlyVerified}'
      '|${p.onlyOnlineNow}'
      '|${p.onlyRecentlyActive}'
      '|${p.languageFilter}'
      '|${p.travelersOnly}'
      '|${p.localGuidesOnly}'
      '|${p.showSupportUser}'
      '|${p.preferredInterests.join(',')}'
      '|${p.dealBreakers.join(',')}'
      '|${p.preferredOrientations.join(',')}';

  void _storeStack(String key, List<MatchCandidate> result, String prefHash) {
    _cache.remove(key);
    _cache[key] = _CachedStack(result, prefHash);
    while (_cache.length > _maxCachedStacks) {
      _cache.remove(_cache.keys.first); // least recently used
    }
  }

  /// The viewer's raw profile, memoised for the session.
  Future<Map<String, dynamic>?> _viewerData(String userId) async {
    if (_cachedUserProfileId == userId && _cachedUserProfile != null) {
      return _cachedUserProfile;
    }
    final doc = await firestore.collection('profiles').doc(userId).get();
    _cachedUserProfile = doc.data();
    _cachedUserProfileId = userId;
    return _cachedUserProfile;
  }

  @override
  Future<List<MatchCandidate>> getDiscoveryStack({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
    bool forceRefresh = false,
  }) =>
      _stack(
        userId: userId,
        preferences: preferences,
        forceRefresh: forceRefresh,
        primary: true,
      );

  /// Builds (or serves) a stack. [primary] stacks are Discovery's: they use the
  /// shared LRU and publish [lastUsedWorldwideFallback]. A non-primary stack
  /// (Explore's fallback) uses its own slot and never touches that flag.
  Future<List<MatchCandidate>> _stack({
    required String userId,
    required MatchPreferences preferences,
    required bool forceRefresh,
    required bool primary,
  }) async {
    if (primary) lastUsedWorldwideFallback = false;

    // Build a hash of preferences so cache invalidates when filters change
    final prefHash = _preferencesHash(preferences);
    final cacheKey = '$userId|$prefHash';

    if (!primary) {
      final slot = _nearbyFallback;
      if (!forceRefresh &&
          slot != null &&
          slot.$1 == userId &&
          slot.$2.isValid(prefHash)) {
        return slot.$2.candidates;
      }
    }

    // Serve from cache when valid, not forced, and preferences haven't changed
    // (the non-primary slot was checked above).
    if (primary && !forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null && cached.isValid(prefHash)) {
        // Touch: move to the most-recently-used end.
        _cache
          ..remove(cacheKey)
          ..[cacheKey] = cached;
        debugPrint('[Discovery] Cache hit — ${cached.candidates.length} profiles (${DateTime.now().difference(cached.fetchedAt).inSeconds}s old)');
        return cached.candidates;
      }
    } else if (primary) {
      _cache.remove(cacheKey);
      debugPrint('[Discovery] Cache bypassed (forceRefresh)');
    }
    // Map discovery gender preference to matching gender list
    // Empty list = no gender filter (show everyone)
    final preferredGenders = _gendersFor(preferences.interestedInGender);

    // Get candidates from matching datasource
    // When no countries selected: worldwide (pass empty to get all)
    // When countries selected: pass them to filter (regardless of randomMode)
    final hasCountryFilter = preferences.preferredCountries.isNotEmpty;
    final effectiveCountries = hasCountryFilter
        ? preferences.preferredCountries
        : const <String>[];

    // The candidate scan, the viewer's profile and the per-user history all
    // run in ONE parallel round trip (they used to be sequential).
    // Active matches are not fetched: matched users stay in the grid (the UI
    // applies the 'matched' overlay), so that set was never used here.
    final results = await Future.wait<Object?>([
      matchingDataSource.getMatchCandidates(
        userId: userId,
        preferences: matching.MatchPreferences(
          userId: preferences.userId,
          minAge: preferences.minAge,
          maxAge: preferences.maxAge,
          maxDistance: (preferences.randomMode && !hasCountryFilter)
              ? 99999.0
              : (preferences.maxDistanceKm ?? 99999).toDouble(),
          preferredGenders: preferredGenders,
          showOnlyVerified: preferences.onlyVerified,
          preferredCountries: effectiveCountries,
          updatedAt: DateTime.now(),
        ),
        limit: 500, // Cap to avoid loading entire database into memory
      ),
      // Check if current user is admin/support — admins bypass all discovery
      // filters. Cached to avoid re-reading on every load.
      _viewerData(userId),
      _getSwipeHistoryWithTypes(userId),
      blockedUsersService.getBlockedUserIds(userId),
    ]);

    final candidates = results[0] as List<MatchCandidate>;
    final currentUserData = results[1] as Map<String, dynamic>?;
    final swipeHistory = results[2] as Map<String, _SwipeRecord>;
    final blockedUserIds = results[3] as Set<String>;

    debugPrint('[Discovery] Candidates from matching: ${candidates.length}');

    final isCurrentUserPrivileged = currentUserData != null &&
        ((currentUserData['isAdmin'] as bool? ?? false) ||
         (currentUserData['isSupport'] as bool? ?? false));

    // Determine viewer's tier for boost visibility limit
    // EFFECTIVE tier — an expired paid tier gets the free allowance.
    final maxBoostedVisible =
        _getMaxBoostedVisible(effectiveTierFromDoc(currentUserData).value);

    // Admin/support users bypass all discovery preference filters (see all users)
    var filteredCandidates = candidates.toList();

    if (!isCurrentUserPrivileged) {
      // Apply sexual orientation filter
      if (preferences.preferredOrientations.isNotEmpty) {
        filteredCandidates = filteredCandidates.where((candidate) {
          final orientation = candidate.profile.sexualOrientation;
          if (orientation == null || orientation.isEmpty) return true;
          if (!preferences.preferredOrientations.contains(orientation)) {
            return false;
          }
          return true;
        }).toList();
      }

      // Apply country filter — use effectiveLocation so traveler candidates show in correct country
      // When user has a country filter, profiles with unknown/empty country are excluded
      // Apply country filter when countries are selected (regardless of randomMode)
      if (preferences.preferredCountries.isNotEmpty) {
        filteredCandidates = filteredCandidates.where((candidate) {
          final country = candidate.profile.effectiveLocation.country;
          // Profiles with unknown/empty location are not discoverable to other
          // users (they're dropped later in the per-candidate loop too); exclude
          // them here so they don't consume worldwide-fallback slots.
          if (country.isEmpty || country == 'Unknown') {
            return false;
          }
          final matches = preferences.preferredCountries
              .map((c) => c.toLowerCase())
              .contains(country.toLowerCase());
          return matches;
        }).toList();
      }

      // Current user's ANCHOR location for distance sorting (used by the
      // worldwide fallback and the final nearest-first sort). This must be
      // TRAVELER-AWARE: when the user is actively traveling (e.g. to Paris),
      // people near the TRAVELED location must appear first — not last.
      // `Profile.effectiveLocation` is a computed getter and is NEVER persisted,
      // so reading `currentUserData['effectiveLocation']` always missed and fell
      // back to the HOME location. Recompute it here from the raw doc instead.
      Map<String, dynamic> userLoc = <String, dynamic>{};
      if (currentUserData != null) {
        final isTraveler = currentUserData['isTraveler'] as bool? ?? false;
        final expiryRaw = currentUserData['travelerExpiry'];
        final expiry = expiryRaw is Timestamp ? expiryRaw.toDate() : null;
        final travelerActive =
            isTraveler && expiry != null && expiry.isAfter(DateTime.now());
        final travelerLoc =
            currentUserData['travelerLocation'] as Map<String, dynamic>?;
        userLoc = (travelerActive && travelerLoc != null)
            ? travelerLoc
            : (currentUserData['location'] as Map<String, dynamic>? ?? {});
      }
      final userLat = (userLoc['latitude'] as num?)?.toDouble() ?? 0.0;
      final userLng = (userLoc['longitude'] as num?)?.toDouble() ?? 0.0;
      final fe = FeatureEngineer();

      // Worldwide fallback: pad a thin result set with people from further
      // afield, but ONLY when the user has not asked for a specific area.
      //
      // This used to pad up to 500 candidates whenever no country was selected.
      // With a user base far smaller than 500 that meant it fired on virtually
      // every load and re-fetched at maxDistance 99999 — so a distance filter
      // never actually limited anything, and the orientation/country filters
      // above were skipped for everything it appended. Padding now stops when
      // the user has expressed a preference at all.
      const minCandidates = 40;
      final userChoseAnArea = preferences.preferredCountries.isNotEmpty ||
          preferences.maxDistanceKm != null;
      final shouldFallback =
          !userChoseAnArea && filteredCandidates.length < minCandidates;
      if (primary) lastUsedWorldwideFallback = shouldFallback;
      // (The padding re-scan was removed: with no area chosen the primary
      // query above is ALREADY the worldwide scan, so re-running it with a new
      // random pivot re-read up to 500 profiles for nothing. The flag is kept
      // for the UI.)

      // Ordering. Random mode previously did nothing at all: it only varied the
      // cache key and the distance cap, and no shuffle existed anywhere. It now
      // genuinely randomises, seeded per user per hour so paging through the
      // grid stays stable instead of re-dealing on every fetch.
      //
      // sortByDistance was likewise never read — distance sorting was
      // unconditional. It is now the (default) alternative to random mode.
      if (preferences.randomMode) {
        final seed = preferences.userId.hashCode ^
            (DateTime.now().millisecondsSinceEpoch ~/ 3600000);
        filteredCandidates.shuffle(Random(seed));
      } else if (userLat != 0 && userLng != 0) {
        // DISTANCE IS THE DEFAULT ORDER. This used to be gated on
        // preferences.sortByDistance, which defaults to false - so unless the
        // user had gone and turned it on, neither this branch nor the random
        // one ran and the grid rendered in whatever order the query happened to
        // return. People discovery is meant to be nearest-first, so distance is
        // now the ordering whenever we actually know where the user is;
        // randomMode above remains the deliberate opt-out.
        filteredCandidates.sort((a, b) {
          final aLoc = a.profile.effectiveLocation;
          final bLoc = b.profile.effectiveLocation;
          final aDist = fe.calculateDistance(userLat, userLng, aLoc.latitude, aLoc.longitude);
          final bDist = fe.calculateDistance(userLat, userLng, bLoc.latitude, bLoc.longitude);
          return aDist.compareTo(bDist);
        });
      }

      // Apply the "recently active" filter. This preference has always been
      // persisted and never read — the toggle did nothing.
      if (preferences.onlyRecentlyActive) {
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        filteredCandidates = filteredCandidates.where((candidate) {
          if (candidate.profile.isOnline) return true;
          final seen = candidate.profile.lastSeen;
          return seen != null && seen.isAfter(cutoff);
        }).toList();
      }

      // Apply deal breakers: EXCLUDE anyone carrying one of these interests.
      // Also never read before. Note this is the opposite sense to the
      // matching feature's dealBreakerInterests, which REQUIRES them — here
      // the user is naming what they do not want to see.
      if (preferences.dealBreakers.isNotEmpty) {
        final unwanted = preferences.dealBreakers
            .map((e) => e.toLowerCase().trim())
            .toSet();
        filteredCandidates = filteredCandidates.where((candidate) {
          final has = candidate.profile.interests
              .map((e) => e.toLowerCase().trim())
              .toSet();
          return has.intersection(unwanted).isEmpty;
        }).toList();
      }

      // Apply online-only filter
      if (preferences.onlyOnlineNow) {
        filteredCandidates = filteredCandidates
            .where((candidate) {
              return candidate.profile.isOnline;
            })
            .toList();
      }

      // Apply language filter — only return candidates who speak the specified language
      if (preferences.languageFilter != null && preferences.languageFilter!.isNotEmpty) {
        final langFilter = preferences.languageFilter!.toLowerCase().trim();
        filteredCandidates = filteredCandidates.where((candidate) {
          final candidateLangs = candidate.profile.languages
              .map((l) => l.toLowerCase().trim())
              .toList();
          return candidateLangs.contains(langFilter);
        }).toList();
      }

      // Apply interest filter — only return candidates who share at least one preferred interest
      if (preferences.preferredInterests.isNotEmpty) {
        final wantedInterests = preferences.preferredInterests
            .map((i) => i.toLowerCase().trim())
            .toSet();
        filteredCandidates = filteredCandidates.where((candidate) {
          final candidateInterests = candidate.profile.interests
              .map((i) => i.toLowerCase().trim())
              .toSet();
          return candidateInterests.intersection(wantedInterests).isNotEmpty;
        }).toList();
      }

      // Apply travelers-only filter — only return active travelers
      if (preferences.travelersOnly) {
        filteredCandidates = filteredCandidates.where((candidate) {
          return candidate.profile.isTravelerActive;
        }).toList();
      }

      // Apply local-guides-only filter
      if (preferences.localGuidesOnly) {
        filteredCandidates = filteredCandidates.where((candidate) {
          return candidate.profile.isLocalGuide &&
              candidate.profile.localGuideCity != null &&
              candidate.profile.localGuideCity!.isNotEmpty;
        }).toList();
      }
    } else {
      // Admin/support user — skip preference filters
    }

    final prioritizedCandidates = _prioritize(
      filteredCandidates,
      swipeHistory: swipeHistory,
      blockedUserIds: blockedUserIds,
      showSupportUser: preferences.showSupportUser,
      isViewerPrivileged: isCurrentUserPrivileged,
      maxBoostedVisible: maxBoostedVisible,
      viewerId: userId,
    );

    // Add admin/support profile at the beginning only when showSupportUser is enabled
    final List<MatchCandidate> result;
    if (preferences.showSupportUser) {
      final adminCandidate = await _getAdminCandidate(userId);
      if (adminCandidate != null) {
        prioritizedCandidates.removeWhere(
          (c) => c.profile.userId == adminCandidate.profile.userId,
        );
        result = [adminCandidate, ...prioritizedCandidates];
      } else {
        result = prioritizedCandidates;
      }
    } else {
      result = prioritizedCandidates;
    }

    // Store in in-memory cache (keyed by userId + preferences hash)
    if (primary) {
      _storeStack(cacheKey, result, prefHash);
    } else {
      _nearbyFallback = (userId, _CachedStack(result, prefHash));
    }
    debugPrint('[Discovery] Cache stored — ${result.length} profiles for $userId');

    return result;
  }

  static List<String> _gendersFor(String interestedInGender) {
    switch (interestedInGender.toLowerCase()) {
      case 'women':
      case 'female':
        return ['Female'];
      case 'men':
      case 'male':
        return ['Male'];
      default: // 'everyone' or any other value — no gender filter
        return [];
    }
  }

  /// Visibility rules + priority ordering shared by [getDiscoveryStack] and
  /// [getNearbyPeople]. Keeps the incoming order within each tier.
  List<MatchCandidate> _prioritize(
    List<MatchCandidate> filteredCandidates, {
    required Map<String, _SwipeRecord> swipeHistory,
    required Set<String> blockedUserIds,
    required bool showSupportUser,
    required bool isViewerPrivileged,
    required int maxBoostedVisible,
    required String viewerId,
  }) {
    // Categorize candidates into priority tiers:
    // Priority 0: Boosted profiles (isBoosted && boostExpiry > now)
    // Priority 1: Never seen (not in swipe history)
    // Priority 2: Skipped (swipe down) - queued for next session
    // Priority 3: Liked but no response (not matched)
    // Excluded: Nope/pass (swipe left) - hidden for 90 days

    final priority0Boosted = <MatchCandidate>[];
    final priority1NotSeen = <MatchCandidate>[];
    final priority2Skipped = <MatchCandidate>[];
    final priority3LikedNoResponse = <MatchCandidate>[];

    final now = DateTime.now();
    const nopeCooldownDays = 90;
    const likeCooldownDays = 30;

    var addedAdminOrSupport = false;

    for (final candidate in filteredCandidates) {
      final candidateId = candidate.profile.userId;
      final candidateProfile = candidate.profile;
      final isPrivileged = (candidateProfile.isAdmin || candidateProfile.isSupport) && showSupportUser;

      // Admin/support hidden when showSupportUser is disabled
      if ((candidateProfile.isAdmin || candidateProfile.isSupport) && !showSupportUser) {
        continue;
      }

      // Admin/support visible — only add one
      if (isPrivileged) {
        if (!addedAdminOrSupport) {
          priority0Boosted.add(candidate);
          addedAdminOrSupport = true;
        }
        continue;
      }

      // Matched users still appear in discovery grid (with 'matched' overlay)
      // They are only filtered out in swipe card mode by the UI layer

      // Blocked (bidirectional), removed accounts, ghost/incognito, testers and
      // incomplete profiles (name/location) — the shared rules every people
      // surface and every cached preview uses. Admin/support viewers still see
      // testers and incomplete profiles.
      if (!DiscoveryVisibility.isVisible(
        candidateProfile,
        viewerId: viewerId,
        blockedIds: blockedUserIds,
        viewerIsPrivileged: isViewerPrivileged,
        now: now,
      )) {
        continue;
      }

      // Check if profile is boosted
      final isBoosted = candidateProfile.isBoosted &&
          candidateProfile.boostExpiry != null &&
          candidateProfile.boostExpiry!.isAfter(now);

      final swipeRecord = swipeHistory[candidateId];

      if (swipeRecord == null) {
        if (isBoosted) {
          // Collect ALL boosted — we'll trim to closest N after the loop
          priority0Boosted.add(candidate);
        } else {
          priority1NotSeen.add(candidate);
        }
      } else if (swipeRecord.actionType == 'skip') {
        // Skipped (swipe down) - Priority 2: show again next session
        priority2Skipped.add(candidate);
      } else if (swipeRecord.actionType == 'pass' || swipeRecord.actionType == 'nope') {
        // Nope (swipe left) - hidden for 90 days
        final daysSinceSwipe = now.difference(swipeRecord.timestamp).inDays;
        if (daysSinceSwipe >= nopeCooldownDays) {
          // Cooldown expired, show again at low priority
          priority2Skipped.add(candidate);
        }
        // Otherwise: still within 90 days, don't show
      } else if (swipeRecord.actionType == 'like' || swipeRecord.actionType == 'superLike') {
        // Liked but not matched - hidden for 30 days, then reappear
        final daysSinceSwipe = now.difference(swipeRecord.timestamp).inDays;
        if (daysSinceSwipe >= likeCooldownDays) {
          // Cooldown expired, show again as unseen
          priority1NotSeen.add(candidate);
        } else {
          // Still within 30 days, show as low priority
          priority3LikedNoResponse.add(candidate);
        }
      }
    }

    // Sort boosted by distance (closest first), then keep only the tier limit
    // Overflow boosted profiles go into the normal pool so they're still visible
    priority0Boosted.sort((a, b) => a.distance.compareTo(b.distance));
    if (priority0Boosted.length > maxBoostedVisible) {
      // Admin/support profiles (added earlier) should stay — only trim real boosted
      final admins = priority0Boosted.where((c) =>
          c.profile.isAdmin || c.profile.isSupport).take(1).toList();
      final realBoosted = priority0Boosted.where((c) =>
          !c.profile.isAdmin && !c.profile.isSupport).toList();
      final kept = realBoosted.take(maxBoostedVisible).toList();
      final overflow = realBoosted.skip(maxBoostedVisible).toList();
      priority0Boosted
        ..clear()
        ..addAll(admins)
        ..addAll(kept);
      priority1NotSeen.addAll(overflow);
    }

    // Build the final list with priority ordering (no limit - endless)
    final prioritizedCandidates = <MatchCandidate>[];

    // Add priority 1 (not seen) first
    prioritizedCandidates.addAll(priority1NotSeen);

    // Place boosted profiles at the very top (first 1-2 rows of grid)
    // regardless of distance — they paid for priority visibility
    if (priority0Boosted.isNotEmpty) {
      prioritizedCandidates.insertAll(0, priority0Boosted);
    }

    // Then priority 2 (skipped / expired nope cooldown)
    prioritizedCandidates.addAll(priority2Skipped);

    // Then priority 3 (liked no response)
    prioritizedCandidates.addAll(priority3LikedNoResponse);

    return prioritizedCandidates;
  }

  @override
  Future<List<MatchCandidate>> getNearbyPeople({
    required String userId,
    required Profile viewer,
    int limit = 15,
  }) async {
    final loc = viewer.effectiveLocation;
    final city = loc.city.trim();
    final country = loc.country.trim();
    bool known(String v) => v.isNotEmpty && v.toLowerCase() != 'unknown';
    final hasCity = known(city);
    final hasCountry = known(country);

    Future<List<MatchCandidate>> fullStack() async {
      // Own cache slot + no fallback flag: Explore must not evict or relabel
      // the Discovery grid's stack.
      final stack = await _stack(
        userId: userId,
        preferences: MatchPreferences.defaultFor(userId)
            .copyWith(showSupportUser: false),
        forceRefresh: false,
        primary: false,
      );
      return stack
          .where((c) => !c.profile.isBusiness && c.profile.userId != userId)
          .take(limit)
          .toList();
    }

    // No area to anchor a light query on → the full stack, as before.
    if (!hasCity && !hasCountry) return fullStack();

    final profiles = firestore.collection('profiles');
    Future<QuerySnapshot<Map<String, dynamic>>?> read(
        Query<Map<String, dynamic>> q) async {
      try {
        return await q.get();
      } catch (_) {
        return null; // best-effort: another pool may still fill the strip
      }
    }

    // A few bounded, single-field (auto-indexed) reads, all in parallel:
    // locals in the viewer's city, travellers currently visiting it, and a
    // same-country top-up; plus the viewer's recent swipes and blocks.
    final results = await Future.wait<Object?>([
      hasCity
          ? read(profiles.where('location.city', isEqualTo: city).limit(40))
          : Future<Object?>.value(),
      hasCity
          ? read(profiles
              .where('travelerLocation.city', isEqualTo: city)
              .limit(20))
          : Future<Object?>.value(),
      hasCountry
          ? read(profiles.where('location.country', isEqualTo: country).limit(40))
          : Future<Object?>.value(),
      // Same bounded 90-day window as the stack (memoised, so it is read once
      // for both), so "passed in the last 90 days" holds for heavy swipers too.
      _getSwipeHistoryWithTypes(userId),
      blockedUsersService.getBlockedUserIds(userId),
    ]);

    final ids = <String>[];
    final data = <Map<String, dynamic>>[];
    final seen = <String>{userId};
    for (final r in results.take(3)) {
      if (r is! QuerySnapshot<Map<String, dynamic>>) continue;
      for (final doc in r.docs) {
        if (!seen.add(doc.id)) continue;
        ids.add(doc.id);
        data.add(doc.data());
      }
    }
    final swipeHistory = results[3] as Map<String, _SwipeRecord>;
    final blockedUserIds = results[4] as Set<String>;

    // Same parse/score/age rules as the matching scan (defaults: 18–99, any
    // gender, no distance cap), off the UI isolate.
    final parsed = await buildCandidatesOffThread(CandidateBuildRequest(
      userId: userId,
      viewer: viewer,
      docIds: ids,
      docData: data,
      shuffle: false,
    ));
    // Nearest first (distance is 0 when either side has no coordinates; those
    // candidates are dropped by the no-usable-location rule below).
    parsed.sort((a, b) => a.distance.compareTo(b.distance));

    final people = _prioritize(
      parsed,
      swipeHistory: swipeHistory,
      blockedUserIds: blockedUserIds,
      showSupportUser: false,
      isViewerPrivileged: viewer.isAdmin || viewer.isSupport,
      maxBoostedVisible: _getMaxBoostedVisible(viewer.effectiveTier.value),
      viewerId: userId,
    ).where((c) => !c.profile.isBusiness).take(limit).toList();

    // A sparse area (almost nobody in the city/country) would leave the strip
    // near-empty; the worldwide stack pads with the nearest people elsewhere.
    if (people.length < (limit / 3).ceil()) {
      try {
        final padded = await fullStack();
        if (padded.length > people.length) return padded;
      } catch (_) {
        // Keep the light result.
      }
    }
    return people;
  }

  /// Get swipe history with action types and timestamps
  /// Only fetches last 90 days (nope cooldown) to reduce reads at scale
  Future<Map<String, _SwipeRecord>> _getSwipeHistoryWithTypes(
    String userId, {
    int limit = 2000,
  }) async {
    final memo = _swipeMemo;
    if (memo != null &&
        memo.$1 == userId &&
        DateTime.now().difference(memo.$2) < _CachedStack.ttl) {
      return memo.$3;
    }
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(ninetyDaysAgo))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    final history = <String, _SwipeRecord>{};
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final targetId = data['targetUserId'] as String?;
      final actionType = data['actionType'] as String?;
      final timestamp = data['timestamp'] as Timestamp?;
      // Newest first, so the FIRST record per target is the latest action
      // (a plain assignment let an older swipe overwrite a newer one).
      if (targetId != null && actionType != null) {
        history.putIfAbsent(
          targetId,
          () => _SwipeRecord(
            actionType: actionType,
            timestamp: timestamp?.toDate() ?? DateTime.now(),
          ),
        );
      }
    }
    _swipeMemo = (userId, DateTime.now(), history);
    return history;
  }

  /// Get admin profile as a match candidate — always visible to all users
  /// Cached for 1 hour to avoid querying on every discovery load (cost saving)
  Future<MatchCandidate?> _getAdminCandidate(String userId) async {
    try {
      // Return cached admin if still valid
      if (_cachedAdminCandidate != null &&
          _adminCacheFetchedAt != null &&
          DateTime.now().difference(_adminCacheFetchedAt!) < _adminCacheTtl &&
          _cachedAdminCandidate!.profile.userId != userId) {
        return _cachedAdminCandidate;
      }

      // Query for admin profile
      final adminQuery = await firestore
          .collection('profiles')
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) return null;

      final adminDoc = adminQuery.docs.first;

      // Don't show admin to themselves
      if (adminDoc.id == userId) return null;

      Profile adminProfile;
      try {
        adminProfile = ProfileModel.fromFirestore(adminDoc);
      } catch (parseError) {
        // Fallback: build minimal profile from raw data
        final data = adminDoc.data();
        final loc = data['location'] as Map<String, dynamic>?;
        adminProfile = ProfileModel(
          userId: adminDoc.id,
          displayName: data['displayName'] as String? ?? 'GreenGo Support',
          nickname: data['nickname'] as String?,
          dateOfBirth: DateTime(1990, 1, 1),
          gender: data['gender'] as String? ?? 'other',
          photoUrls: data['photoUrls'] != null
              ? List<String>.from(data['photoUrls'] as List)
              : <String>[],
          bio: data['bio'] as String? ?? '',
          interests: data['interests'] != null
              ? List<String>.from(data['interests'] as List)
              : <String>[],
          location: LocationModel(
            latitude: (loc?['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (loc?['longitude'] as num?)?.toDouble() ?? 0,
            city: loc?['city'] as String? ?? 'Unknown',
            country: loc?['country'] as String? ?? 'Unknown',
            displayAddress: loc?['displayAddress'] as String? ?? 'Unknown',
          ),
          languages: data['languages'] != null
              ? List<String>.from(data['languages'] as List)
              : <String>[],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isComplete: true,
          isAdmin: true,
          verificationStatus: VerificationStatus.approved,
        );
      }

      // Create a special match score for admin (always shown as recommended)
      final adminMatchScore = MatchScore(
        userId1: userId,
        userId2: adminDoc.id,
        overallScore: 100.0,
        breakdown: const ScoreBreakdown(
          locationScore: 100.0,
          ageCompatibilityScore: 100.0,
          interestOverlapScore: 100.0,
          languageScore: 100.0,
        ),
        calculatedAt: DateTime.now(),
      );

      final candidate = MatchCandidate(
        profile: adminProfile,
        matchScore: adminMatchScore,
        distance: 0.0,
        suggestedAt: DateTime.now(),
        isSuperLike: true,
      );

      // Cache for 1 hour
      _cachedAdminCandidate = candidate;
      _adminCacheFetchedAt = DateTime.now();

      return candidate;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<SwipeAction> recordSwipe({
    required String userId,
    required String targetUserId,
    required SwipeActionType actionType,
  }) async {
    // Create swipe action
    final action = SwipeAction(
      userId: userId,
      targetUserId: targetUserId,
      actionType: actionType,
      timestamp: DateTime.now(),
      createdMatch: false,
    );

    // Save to Firestore
    final model = SwipeActionModel.fromEntity(action);
    await firestore.collection('swipes').add(model.toFirestore());
    _swipeMemo = null; // history changed

    // If it's a like or super like, send notification and check for match
    if (action.isPositive) {
      // Get sender's profile for nickname in notification
      final senderProfile = await firestore.collection('profiles').doc(userId).get();
      final senderNickname = senderProfile.data()?['nickname'] as String? ?? 'Someone';
      final senderName = senderProfile.data()?['displayName'] as String? ?? 'Someone';

      // If super like, create a one-way conversation visible only to the target
      if (actionType == SwipeActionType.superLike) {
        await _createSuperLikeConversation(
          userId: userId,
          targetUserId: targetUserId,
          senderNickname: senderNickname.isNotEmpty ? senderNickname : senderName,
        );
      }

      // NOTE: dating-style "new like / super like" notifications were REMOVED —
      // GreenGo is a cross-cultural networking app, not a dating app. The swipe
      // and the connection mechanic (match + conversation) stay; no like/
      // super-like notification is created or pushed.

      // Check for match
      final match = await checkForMatch(
        userId: userId,
        targetUserId: targetUserId,
      );

      if (match != null) {
        return action.copyWith(createdMatch: true, matchId: match.matchId);
      }
    }

    return action;
  }

  /// Create a super like conversation visible only to the target until they reply
  Future<void> _createSuperLikeConversation({
    required String userId,
    required String targetUserId,
    required String senderNickname,
  }) async {
    // Check if a super like conversation already exists between these users
    final existing1 = await firestore
        .collection('conversations')
        .where('userId1', isEqualTo: userId)
        .where('userId2', isEqualTo: targetUserId)
        .where('conversationType', isEqualTo: 'superLike')
        .limit(1)
        .get();

    if (existing1.docs.isNotEmpty) return; // Already exists

    final existing2 = await firestore
        .collection('conversations')
        .where('userId1', isEqualTo: targetUserId)
        .where('userId2', isEqualTo: userId)
        .where('conversationType', isEqualTo: 'superLike')
        .limit(1)
        .get();

    if (existing2.docs.isNotEmpty) return; // Already exists

    final conversationRef = firestore.collection('conversations').doc();
    final now = Timestamp.now();

    await conversationRef.set({
      'conversationId': conversationRef.id,
      'matchId': 'superlike_${userId}_$targetUserId',
      'userId1': userId,
      'userId2': targetUserId,
      'conversationType': 'superLike',
      'visibleTo': [targetUserId],
      'superLikeSenderId': userId,
      'createdAt': now,
      'unreadCount': 1,
      'isTyping': false,
      'isPinned': false,
      'isMuted': false,
      'isArchived': false,
      'isDeleted': false,
      'theme': 'gold',
      'lastMessageAt': now,
    });

    // Create system message
    final msgRef = conversationRef.collection('messages').doc();
    await msgRef.set({
      'messageId': msgRef.id,
      'senderId': 'system',
      'receiverId': targetUserId,
      'content': '$senderNickname sent you a Super Like!',
      'type': 'system',
      'sentAt': now,
      'status': 'sent',
    });

    // Update lastMessage on the conversation
    await conversationRef.update({
      'lastMessage': {
        'messageId': msgRef.id,
        'senderId': 'system',
        'receiverId': targetUserId,
        'content': '$senderNickname sent you a Super Like!',
        'type': 'system',
        'sentAt': now,
      },
    });
  }

  @override
  Future<Match?> checkForMatch({
    required String userId,
    required String targetUserId,
  }) async {
    // Check if target user has also liked current user
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: targetUserId)
        .where('targetUserId', isEqualTo: userId)
        .where('actionType', whereIn: ['like', 'superLike']).get();

    if (querySnapshot.docs.isEmpty) {
      // No mutual like yet
      return null;
    }

    // Check if match already exists
    final existingMatch = await _findExistingMatch(userId, targetUserId);
    if (existingMatch != null) {
      return existingMatch;
    }

    // Create new match
    final match = Match(
      matchId: '', // Will be set by Firestore
      userId1: userId,
      userId2: targetUserId,
      matchedAt: DateTime.now(),
      isActive: true,
      user1Seen: false,
      user2Seen: false,
    );

    final model = MatchModel.fromEntity(match);
    final docRef = await firestore.collection('matches').add(model.toFirestore());
    final createdMatch = match.copyWith(matchId: docRef.id);

    // NOTE: dating-style "new match" notifications were REMOVED (GreenGo is a
    // networking app, not dating). The connection + conversation below stay.

    // Create conversation with "Start Connecting!" system message for both users
    await _createMatchConversation(
      userId1: userId,
      userId2: targetUserId,
      matchId: createdMatch.matchId,
    );

    return createdMatch;
  }

  /// Create a conversation for a new match with a system message visible to both users
  Future<void> _createMatchConversation({
    required String userId1,
    required String userId2,
    required String matchId,
  }) async {
    try {
      // Check if conversation already exists for this match
      // Scoped to userId1 (the acting user on this side of the match) so the
      // query is provable under the conversations rule - see
      // conversationsByMatchId.
      final existing = await conversationsByMatchId(
        firestore,
        matchId,
        uid: userId1,
      ).limit(1).get();

      if (existing.docs.isNotEmpty) return;

      final conversationRef = firestore.collection('conversations').doc();
      final now = Timestamp.now();

      await conversationRef.set({
        'conversationId': conversationRef.id,
        'matchId': matchId,
        'userId1': userId1,
        'userId2': userId2,
        'createdAt': now,
        'unreadCount': 0,
        'isTyping': false,
        'isPinned': false,
        'isMuted': false,
        'isArchived': false,
        'isDeleted': false,
        'lastMessageAt': now,
      });

      // Create "Start Connecting!" system message visible to both users
      final msgRef = conversationRef.collection('messages').doc();
      await msgRef.set({
        'messageId': msgRef.id,
        'senderId': 'system',
        'receiverId': 'all',
        'content': 'Start Connecting!',
        'type': 'system',
        'sentAt': now,
        'status': 'sent',
      });

      // Update lastMessage on the conversation
      await conversationRef.update({
        'lastMessage': {
          'messageId': msgRef.id,
          'senderId': 'system',
          'receiverId': 'all',
          'content': 'Start Connecting!',
          'type': 'system',
          'sentAt': now,
        },
      });
    } catch (e) {
      // Silently fail — conversation will be created on-demand when user opens chat
    }
  }

  // _sendMatchNotifications was REMOVED — GreenGo does not send dating-style
  // "new match" notifications. The match doc + conversation are created directly
  // in checkForMatch; connecting happens through the Exchange, not a push.

  @override
  Future<List<Match>> getMatches({
    required String userId,
    bool activeOnly = true,
  }) async {
    debugPrint('[getMatches] Loading matches for userId: $userId, activeOnly: $activeOnly');

    // Query matches where user is userId1
    final Query query1 = firestore
        .collection('matches')
        .where('userId1', isEqualTo: userId)
        .limit(500);

    // Query matches where user is userId2
    final Query query2 = firestore
        .collection('matches')
        .where('userId2', isEqualTo: userId)
        .limit(500);

    // NOTE: We do NOT filter isActive in Firestore query because legacy matches
    // may not have the isActive field at all (null != true). Instead we filter
    // client-side after fetching.
    // NOTE: No orderBy here — avoids requiring composite indexes.
    // We sort client-side after combining both queries.

    // Execute both queries
    final results1 = await query1.get();
    final results2 = await query2.get();

    // Get blocked user IDs to filter out blocked matches
    final blockedUserIds = await blockedUsersService.getBlockedUserIds(userId);

    // Combine and convert
    final matches = <Match>[];

    for (final doc in results1.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (activeOnly && data != null) {
        // Skip globally deactivated matches (delete for both)
        if (data['isActive'] == false) continue;
        // Skip matches deactivated for this user (delete for me)
        final deactivatedFor = data['deactivatedFor'] as Map<String, dynamic>?;
        if (deactivatedFor != null && deactivatedFor[userId] == true) continue;
      }
      final match = MatchModel.fromFirestore(doc);
      if (!blockedUserIds.contains(match.userId2)) {
        matches.add(match);
      }
    }

    for (final doc in results2.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (activeOnly && data != null) {
        if (data['isActive'] == false) continue;
        final deactivatedFor = data['deactivatedFor'] as Map<String, dynamic>?;
        if (deactivatedFor != null && deactivatedFor[userId] == true) continue;
      }
      final match = MatchModel.fromFirestore(doc);
      if (!blockedUserIds.contains(match.userId1)) {
        matches.add(match);
      }
    }

    // Sort by match date (most recent first)
    matches.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));

    debugPrint('[getMatches] Found ${matches.length} matches for $userId '
        '(query1: ${results1.docs.length}, query2: ${results2.docs.length})');

    return matches;
  }

  @override
  Future<(Match, Profile)> getMatchWithProfile({
    required String matchId,
    required String currentUserId,
  }) async {
    // Get match document
    final matchDoc = await firestore.collection('matches').doc(matchId).get();

    if (!matchDoc.exists) {
      throw Exception('Match not found');
    }

    final match = MatchModel.fromFirestore(matchDoc);

    // Get other user's profile
    final otherUserId = match.getOtherUserId(currentUserId);
    final profileDoc =
        await firestore.collection('profiles').doc(otherUserId).get();

    if (!profileDoc.exists) {
      throw Exception('Profile not found');
    }

    final profile = ProfileModel.fromFirestore(profileDoc);

    return (match, profile);
  }

  @override
  Future<void> markMatchAsSeen({
    required String matchId,
    required String userId,
  }) async {
    final matchDoc = await firestore.collection('matches').doc(matchId).get();

    if (!matchDoc.exists) return;

    final match = MatchModel.fromFirestore(matchDoc);

    // Update the appropriate seen field
    final updateData = userId == match.userId1
        ? {'user1Seen': true}
        : {'user2Seen': true};

    await firestore.collection('matches').doc(matchId).update(updateData);
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    await firestore.collection('matches').doc(matchId).update({
      'isActive': false,
      'unmatchedAt': FieldValue.serverTimestamp(),
      'unmatchedBy': userId,
    });
  }

  @override
  Future<List<String>> getUserLikes(String userId) async {
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .where('actionType', whereIn: ['like', 'superLike']).get();

    return querySnapshot.docs
        .map((doc) => doc.data()['targetUserId'] as String)
        .toList();
  }

  @override
  Future<List<Profile>> getWhoLikedMe(String userId) async {
    // Get all users who liked current user
    final querySnapshot = await firestore
        .collection('swipes')
        .where('targetUserId', isEqualTo: userId)
        .where('actionType', whereIn: ['like', 'superLike'])
        .limit(200)
        .get();

    final likerIds = querySnapshot.docs
        .map((doc) => doc.data()['userId'] as String)
        .toSet()
        .toList();

    if (likerIds.isEmpty) return [];

    // Batch fetch profiles using whereIn (max 10 per query) in parallel
    final batchFutures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < likerIds.length; i += 10) {
      final batch = likerIds.sublist(i, i + 10 > likerIds.length ? likerIds.length : i + 10);
      batchFutures.add(
        firestore
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get(),
      );
    }

    final batchResults = await Future.wait(batchFutures);
    final profiles = <Profile>[];
    for (final result in batchResults) {
      for (final doc in result.docs) {
        try {
          profiles.add(ProfileModel.fromFirestore(doc));
        } catch (e) {
          // Skip invalid profiles
        }
      }
    }

    return profiles;
  }

  @override
  Future<bool> hasSwipedOn({
    required String userId,
    required String targetUserId,
  }) async {
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .where('targetUserId', isEqualTo: targetUserId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Helper methods

  Future<Set<String>> _getSwipedUserIds(String userId) async {
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .limit(5000)
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data()['targetUserId'] as String)
        .toSet();
  }

  Future<Match?> _findExistingMatch(String userId1, String userId2) async {
    // Try both user orders
    final query1 = await firestore
        .collection('matches')
        .where('userId1', isEqualTo: userId1)
        .where('userId2', isEqualTo: userId2)
        .limit(1)
        .get();

    if (query1.docs.isNotEmpty) {
      return MatchModel.fromFirestore(query1.docs.first);
    }

    final query2 = await firestore
        .collection('matches')
        .where('userId1', isEqualTo: userId2)
        .where('userId2', isEqualTo: userId1)
        .limit(1)
        .get();

    if (query2.docs.isNotEmpty) {
      return MatchModel.fromFirestore(query2.docs.first);
    }

    return null;
  }

  @override
  Future<Profile?> searchByNickname(String nickname) async {
    try {
      final querySnapshot = await firestore
          .collection('profiles')
          .where('nickname', isEqualTo: nickname.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ProfileModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Max boosted profiles visible based on viewer's tier.
  /// Free: 2, Silver: 5, Gold: 10, Platinum/Test: unlimited
  int _getMaxBoostedVisible(String tierStr) {
    switch (tierStr.toUpperCase()) {
      case 'PLATINUM':
      case 'TEST':
        return 999; // effectively unlimited
      case 'GOLD':
        return 10;
      case 'SILVER':
        return 5;
      default: // FREE
        return 2;
    }
  }

  @override
  Future<DateTime> activateBoost(String userId) async {
    final expiry = DateTime.now().add(const Duration(minutes: 30));
    await firestore.collection('profiles').doc(userId).update({
      'isBoosted': true,
      'boostExpiry': Timestamp.fromDate(expiry),
    });
    return expiry;
  }

  @override
  Future<void> undoSwipe({
    required String userId,
    required String targetUserId,
  }) async {
    // Find the most recent swipe from userId to targetUserId
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .where('targetUserId', isEqualTo: targetUserId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.delete();
      _swipeMemo = null; // history changed
    }
  }
}

/// Internal record for swipe history with timestamp
class _SwipeRecord {

  const _SwipeRecord({
    required this.actionType,
    required this.timestamp,
  });
  final String actionType;
  final DateTime timestamp;
}

/// Extension for SwipeAction to add copyWith
extension SwipeActionCopyWith on SwipeAction {
  SwipeAction copyWith({bool? createdMatch}) {
    return SwipeAction(
      userId: userId,
      targetUserId: targetUserId,
      actionType: actionType,
      timestamp: timestamp,
      createdMatch: createdMatch ?? this.createdMatch,
    );
  }
}

/// Extension for Match to add copyWith for matchId
extension MatchCopyWith on Match {
  Match copyWith({String? matchId}) {
    return Match(
      matchId: matchId ?? this.matchId,
      userId1: userId1,
      userId2: userId2,
      matchedAt: matchedAt,
      isActive: isActive,
      lastMessageAt: lastMessageAt,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      user1Seen: user1Seen,
      user2Seen: user2Seen,
    );
  }
}
