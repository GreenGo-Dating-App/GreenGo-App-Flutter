import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/blocked_users_service.dart';
import '../../../matching/data/datasources/matching_remote_datasource.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../../matching/domain/entities/match_preferences.dart' as matching;
import '../../../matching/domain/entities/match_score.dart';
import '../../../matching/domain/usecases/feature_engineer.dart';
import '../../domain/entities/match_preferences.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_action.dart';
import '../models/match_model.dart';
import '../models/swipe_action_model.dart';

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
  final List<MatchCandidate> candidates;
  final DateTime fetchedAt;
  static const ttl = Duration(minutes: 5);

  _CachedStack(this.candidates) : fetchedAt = DateTime.now();

  bool get isValid => DateTime.now().difference(fetchedAt) < ttl;
}

/// Discovery Remote Data Source Implementation
class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  final FirebaseFirestore firestore;
  final MatchingRemoteDataSource matchingDataSource;
  final BlockedUsersService blockedUsersService;

  @override
  bool lastUsedWorldwideFallback = false;

  // In-memory cache keyed by userId — survives bloc recreation (datasource is singleton)
  final Map<String, _CachedStack> _cache = {};

  // Cached admin candidate (session-level, avoids query on every discovery load)
  MatchCandidate? _cachedAdminCandidate;
  DateTime? _adminCacheFetchedAt;
  static const _adminCacheTtl = Duration(hours: 1);

  // Cached current user profile to avoid re-reading on every load
  Map<String, dynamic>? _cachedUserProfile;
  String? _cachedUserProfileId;

  DiscoveryRemoteDataSourceImpl({
    required this.firestore,
    required this.matchingDataSource,
    required this.blockedUsersService,
  });

  @override
  void clearDiscoveryCache(String userId) {
    _cache.remove(userId);
    debugPrint('[Discovery] Cache cleared for $userId');
  }

  @override
  void clearAllDiscoveryCaches() {
    _cache.clear();
    debugPrint('[Discovery] All caches cleared');
  }

  @override
  Future<List<MatchCandidate>> getDiscoveryStack({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    lastUsedWorldwideFallback = false;

    // Serve from cache when valid and not a forced refresh
    if (!forceRefresh) {
      final cached = _cache[userId];
      if (cached != null && cached.isValid) {
        debugPrint('[Discovery] Cache hit — ${cached.candidates.length} profiles (${DateTime.now().difference(cached.fetchedAt).inSeconds}s old)');
        return cached.candidates;
      }
    } else {
      _cache.remove(userId);
      debugPrint('[Discovery] Cache bypassed (forceRefresh)');
    }
    // Map discovery gender preference to matching gender list
    // Empty list = no gender filter (show everyone)
    List<String> preferredGenders;
    switch (preferences.interestedInGender.toLowerCase()) {
      case 'women':
      case 'female':
        preferredGenders = ['Female'];
        break;
      case 'men':
      case 'male':
        preferredGenders = ['Male'];
        break;
      default: // 'everyone' or any other value — no gender filter
        preferredGenders = [];
    }

    // Get candidates from matching datasource
    // When no countries selected: worldwide (pass empty to get all)
    // When countries selected: pass them to filter (regardless of randomMode)
    final hasCountryFilter = preferences.preferredCountries.isNotEmpty;
    final effectiveCountries = hasCountryFilter
        ? preferences.preferredCountries
        : const <String>[];
    final candidates = await matchingDataSource.getMatchCandidates(
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
    );

    debugPrint('[Discovery] Candidates from matching: ${candidates.length}');

    // Check if current user is admin/support — admins bypass all discovery filters
    // Cache the user profile to avoid re-reading on every load
    Map<String, dynamic>? currentUserData;
    if (_cachedUserProfileId == userId && _cachedUserProfile != null) {
      currentUserData = _cachedUserProfile;
    } else {
      final currentUserDoc = await firestore.collection('profiles').doc(userId).get();
      currentUserData = currentUserDoc.data();
      _cachedUserProfile = currentUserData;
      _cachedUserProfileId = userId;
    }

    final isCurrentUserPrivileged = currentUserData != null &&
        ((currentUserData['isAdmin'] as bool? ?? false) ||
         (currentUserData['isSupport'] as bool? ?? false));

    // Determine viewer's tier for boost visibility limit
    final viewerTierStr = currentUserData?['membershipTier'] as String? ?? 'FREE';
    final maxBoostedVisible = _getMaxBoostedVisible(viewerTierStr);

    // Run all historical data queries in parallel (cost-efficient: one round trip)
    final results = await Future.wait([
      _getSwipeHistoryWithTypes(userId),
      _getMatchedUserIds(userId),
      blockedUsersService.getBlockedUserIds(userId),
    ]);

    final swipeHistory = results[0] as Map<String, _SwipeRecord>;
    final matchedUserIds = results[1] as Set<String>;
    final blockedUserIds = results[2] as Set<String>;

    print('[Discovery] Swipe: ${swipeHistory.length}, Matches: ${matchedUserIds.length}, Blocked: ${blockedUserIds.length}');

    // Log travelers that made it through matching filters
    for (final c in candidates) {
      if (c.profile.isTravelerActive) {
        print('[Discovery] TRAVELER ${c.profile.nickname} in candidates from matching (effectiveLoc: ${c.profile.effectiveLocation.country}/${c.profile.effectiveLocation.city})');
      }
    }

    // Admin/support users bypass all discovery preference filters (see all users)
    var filteredCandidates = candidates.toList();

    if (!isCurrentUserPrivileged) {
      // Apply sexual orientation filter
      if (preferences.preferredOrientations.isNotEmpty) {
        final before = filteredCandidates.length;
        filteredCandidates = filteredCandidates.where((candidate) {
          final orientation = candidate.profile.sexualOrientation;
          if (orientation == null || orientation.isEmpty) return true;
          if (!preferences.preferredOrientations.contains(orientation)) {
            if (candidate.profile.isTravelerActive) print('[Discovery] TRAVELER ${candidate.profile.nickname} EXCLUDED: orientation $orientation');
            return false;
          }
          return true;
        }).toList();
        if (before != filteredCandidates.length) print('[Discovery] Orientation filter: $before → ${filteredCandidates.length}');
      }

      // Apply country filter — use effectiveLocation so traveler candidates show in correct country
      // When user has a country filter, profiles with unknown/empty country are excluded
      // Apply country filter when countries are selected (regardless of randomMode)
      if (preferences.preferredCountries.isNotEmpty) {
        print('[Discovery] Country filter active: ${preferences.preferredCountries}');
        filteredCandidates = filteredCandidates.where((candidate) {
          final country = candidate.profile.effectiveLocation.country;
          if (country.isEmpty || country == 'Unknown') {
            if (candidate.profile.isTravelerActive) print('[Discovery] TRAVELER ${candidate.profile.nickname} EXCLUDED: empty/unknown country');
            return false;
          }
          final matches = preferences.preferredCountries
              .map((c) => c.toLowerCase())
              .contains(country.toLowerCase());
          if (!matches && candidate.profile.isTravelerActive) {
            print('[Discovery] TRAVELER ${candidate.profile.nickname} EXCLUDED: country $country not in ${preferences.preferredCountries}');
          }
          return matches;
        }).toList();
      }

      // Get user location for distance sorting (used by fallback and final sort)
      final userLoc = currentUserData != null
          ? (currentUserData['effectiveLocation'] as Map<String, dynamic>? ??
             currentUserData['location'] as Map<String, dynamic>? ?? {})
          : <String, dynamic>{};
      final userLat = (userLoc['latitude'] as num?)?.toDouble() ?? 0.0;
      final userLng = (userLoc['longitude'] as num?)?.toDouble() ?? 0.0;
      final fe = FeatureEngineer();

      // Worldwide fallback: only when no country filter is active.
      // When a country IS selected, show only people from that country (no padding).
      const minCandidates = 500;
      final shouldFallback = preferences.preferredCountries.isEmpty &&
          filteredCandidates.length < minCandidates;
      lastUsedWorldwideFallback = shouldFallback;
      if (shouldFallback) {
        print('[Discovery] Pool has ${filteredCandidates.length} candidates (< $minCandidates), fetching worldwide fallback');

        // Fetch worldwide candidates (no country restriction)
        final worldwideCandidates = await matchingDataSource.getMatchCandidates(
          userId: userId,
          preferences: matching.MatchPreferences(
            userId: preferences.userId,
            minAge: preferences.minAge,
            maxAge: preferences.maxAge,
            maxDistance: 99999.0,
            preferredGenders: preferredGenders,
            showOnlyVerified: preferences.onlyVerified,
            preferredCountries: const [], // No country filter
            updatedAt: DateTime.now(),
          ),
          limit: 500,
        );

        // Collect IDs already in filtered list
        final existingIds = filteredCandidates
            .map((c) => c.profile.userId)
            .toSet();

        // Get worldwide candidates not already included
        var worldwideNew = worldwideCandidates
            .where((c) => !existingIds.contains(c.profile.userId))
            .toList();

        // Sort worldwide candidates by distance to user (closest first)
        if (userLat != 0 && userLng != 0) {
          worldwideNew.sort((a, b) {
            final aLoc = a.profile.effectiveLocation;
            final bLoc = b.profile.effectiveLocation;
            final aDist = fe.calculateDistance(userLat, userLng, aLoc.latitude, aLoc.longitude);
            final bDist = fe.calculateDistance(userLat, userLng, bLoc.latitude, bLoc.longitude);
            return aDist.compareTo(bDist);
          });
        }

        // Fill up to minCandidates
        final needed = minCandidates - filteredCandidates.length;
        final toAdd = worldwideNew.take(needed).toList();
        filteredCandidates.addAll(toAdd);

        print('[Discovery] Added ${toAdd.length} worldwide candidates (total: ${filteredCandidates.length})');
      }

      // Always sort the entire pool by distance so nearest profiles appear
      // first in grid mode — critical for user experience in small countries
      if (userLat != 0 && userLng != 0) {
        filteredCandidates.sort((a, b) {
          final aLoc = a.profile.effectiveLocation;
          final bLoc = b.profile.effectiveLocation;
          final aDist = fe.calculateDistance(userLat, userLng, aLoc.latitude, aLoc.longitude);
          final bDist = fe.calculateDistance(userLat, userLng, bLoc.latitude, bLoc.longitude);
          return aDist.compareTo(bDist);
        });
        print('[Discovery] Sorted ${filteredCandidates.length} candidates by distance');
      }

      // Apply online-only filter
      if (preferences.onlyOnlineNow) {
        filteredCandidates = filteredCandidates
            .where((candidate) {
              if (!candidate.profile.isOnline && candidate.profile.isTravelerActive) {
                print('[Discovery] TRAVELER ${candidate.profile.nickname} EXCLUDED: not online (onlyOnline filter)');
              }
              return candidate.profile.isOnline;
            })
            .toList();
      }

      // Apply language filter — only return candidates who speak the specified language
      if (preferences.languageFilter != null && preferences.languageFilter!.isNotEmpty) {
        final langFilter = preferences.languageFilter!.toLowerCase().trim();
        final before = filteredCandidates.length;
        filteredCandidates = filteredCandidates.where((candidate) {
          final candidateLangs = candidate.profile.languages
              .map((l) => l.toLowerCase().trim())
              .toList();
          return candidateLangs.contains(langFilter);
        }).toList();
        print('[Discovery] Language filter ($langFilter): $before -> ${filteredCandidates.length}');
      }

      // Apply interest filter — only return candidates who share at least one preferred interest
      if (preferences.preferredInterests.isNotEmpty) {
        final wantedInterests = preferences.preferredInterests
            .map((i) => i.toLowerCase().trim())
            .toSet();
        final before = filteredCandidates.length;
        filteredCandidates = filteredCandidates.where((candidate) {
          final candidateInterests = candidate.profile.interests
              .map((i) => i.toLowerCase().trim())
              .toSet();
          return candidateInterests.intersection(wantedInterests).isNotEmpty;
        }).toList();
        print('[Discovery] Interest filter (${wantedInterests.join(', ')}): $before -> ${filteredCandidates.length}');
      }

      // Apply travelers-only filter — only return active travelers
      if (preferences.travelersOnly) {
        final before = filteredCandidates.length;
        filteredCandidates = filteredCandidates.where((candidate) {
          return candidate.profile.isTravelerActive;
        }).toList();
        print('[Discovery] Travelers-only filter: $before -> ${filteredCandidates.length}');
      }

      // Apply local-guides-only filter
      if (preferences.localGuidesOnly) {
        final before = filteredCandidates.length;
        filteredCandidates = filteredCandidates.where((candidate) {
          return candidate.profile.isLocalGuide &&
              candidate.profile.localGuideCity != null &&
              candidate.profile.localGuideCity!.isNotEmpty;
        }).toList();
        print('[Discovery] Local-guides-only filter: $before -> ${filteredCandidates.length}');
      }
    } else {
      print('[Discovery] Admin/support user — skipping preference filters');
    }

    // Log travelers that survived all filters
    for (final c in filteredCandidates) {
      if (c.profile.isTravelerActive) {
        print('[Discovery] TRAVELER ${c.profile.nickname} SURVIVED all discovery filters');
      }
    }

    // Categorize candidates into priority tiers:
    // Priority 0: Boosted profiles (isBoosted && boostExpiry > now)
    // Priority 1: Never seen (not in swipe history)
    // Priority 2: Skipped (swipe down) - queued for next session
    // Priority 3: Liked but no response (not matched)
    // Excluded: Nope/pass (swipe left) - hidden for 90 days

    final List<MatchCandidate> priority0Boosted = [];
    final List<MatchCandidate> priority1NotSeen = [];
    final List<MatchCandidate> priority2Skipped = [];
    final List<MatchCandidate> priority3LikedNoResponse = [];

    final now = DateTime.now();
    const nopeCooldownDays = 90;
    const likeCooldownDays = 30;
    bool addedAdminOrSupport = false;

    for (final candidate in filteredCandidates) {
      final candidateId = candidate.profile.userId;
      final candidateProfile = candidate.profile;
      final isPrivileged = (candidateProfile.isAdmin || candidateProfile.isSupport) && preferences.showSupportUser;

      // Admin/support visible only when showSupportUser is true
      // Skip match/block/incognito/swipe filters for privileged profiles
      if (isPrivileged) {
        if (!addedAdminOrSupport) {
          priority0Boosted.add(candidate);
          addedAdminOrSupport = true;
        }
        continue;
      }

      // Admin/Support profiles hidden when showSupportUser is false — skip entirely
      if ((candidateProfile.isAdmin || candidateProfile.isSupport) && !preferences.showSupportUser) {
        continue;
      }

      // Matched users still appear in discovery grid (with 'matched' overlay)
      // They are only filtered out in swipe card mode by the UI layer

      // Skip blocked users (bidirectional) - they shouldn't appear in discovery
      if (blockedUserIds.contains(candidateId)) {
        if (candidateProfile.isTravelerActive) print('[Discovery] TRAVELER ${candidateProfile.nickname} EXCLUDED: blocked');
        print('[Discovery] Excluded ${candidateProfile.displayName}: blocked');
        continue;
      }

      // Skip ghost mode profiles (hidden from discovery + nickname search, unlimited)
      if (candidateProfile.isGhostMode) {
        print('[Discovery] Excluded ${candidateProfile.displayName}: ghost mode');
        continue;
      }

      // Skip incognito profiles (hidden from discovery for 24h)
      if (candidateProfile.isIncognito &&
          candidateProfile.incognitoExpiry != null &&
          candidateProfile.incognitoExpiry!.isAfter(now)) {
        print('[Discovery] Excluded ${candidateProfile.displayName}: incognito');
        continue;
      }

      // Skip test users — testers should never be visible to regular users
      if (!isCurrentUserPrivileged &&
          candidateProfile.membershipTier == MembershipTier.test) {
        print('[Discovery] Excluded ${candidateProfile.displayName}: tester account');
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

    print('[Discovery] After filtering: P0=${priority0Boosted.length} P1=${priority1NotSeen.length} P2=${priority2Skipped.length} P3=${priority3LikedNoResponse.length}');

    // Build the final list with priority ordering (no limit - endless)
    final List<MatchCandidate> prioritizedCandidates = [];

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

    // Store in in-memory cache
    _cache[userId] = _CachedStack(result);
    debugPrint('[Discovery] Cache stored — ${result.length} profiles for $userId');

    return result;
  }

  /// Get swipe history with action types and timestamps
  /// Only fetches last 90 days (nope cooldown) to reduce reads at scale
  Future<Map<String, _SwipeRecord>> _getSwipeHistoryWithTypes(String userId) async {
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final querySnapshot = await firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(ninetyDaysAgo))
        .orderBy('timestamp', descending: true)
        .limit(2000)
        .get();

    final Map<String, _SwipeRecord> history = {};
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final targetId = data['targetUserId'] as String?;
      final actionType = data['actionType'] as String?;
      final timestamp = data['timestamp'] as Timestamp?;
      if (targetId != null && actionType != null) {
        history[targetId] = _SwipeRecord(
          actionType: actionType,
          timestamp: timestamp?.toDate() ?? DateTime.now(),
        );
      }
    }
    return history;
  }

  /// Get all matched user IDs (mutual likes)
  /// Uses select() to fetch only the needed field, reducing bandwidth and cost
  Future<Set<String>> _getMatchedUserIds(String userId) async {
    final Set<String> matchedIds = {};

    // Fetch only the other userId field (not full docs) to reduce bandwidth
    final results = await Future.wait([
      firestore
          .collection('matches')
          .where('userId1', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1000)
          .get(),
      firestore
          .collection('matches')
          .where('userId2', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1000)
          .get(),
    ]);

    for (final doc in results[0].docs) {
      matchedIds.add(doc.data()['userId2'] as String);
    }
    for (final doc in results[1].docs) {
      matchedIds.add(doc.data()['userId1'] as String);
    }

    return matchedIds;
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
        print('[Discovery] _getAdminCandidate: parsed profile OK — ${adminProfile.displayName}');
      } catch (parseError, parseStack) {
        print('[Discovery] _getAdminCandidate: ProfileModel.fromFirestore FAILED: $parseError');
        print('[Discovery] _getAdminCandidate: stack: $parseStack');
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
        print('[Discovery] _getAdminCandidate: using fallback profile for ${adminProfile.displayName}');
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
    } catch (e, stack) {
      print('[Discovery] _getAdminCandidate FAILED completely: $e');
      print('[Discovery] Stack: $stack');
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

      // Create like notification for target user
      final notificationType = actionType == SwipeActionType.superLike ? 'super_like' : 'new_like';
      final notificationTitle = actionType == SwipeActionType.superLike
          ? 'l10n:priorityConnectNotificationTitle'
          : 'You received a Like!';
      final notificationMessage = actionType == SwipeActionType.superLike
          ? 'l10n:priorityConnectNotificationMessage'
          : (senderNickname.isNotEmpty
              ? 'You received a like from @$senderNickname. See profile.'
              : 'You received a like from $senderName. See profile.');

      await _createNotification(
        userId: targetUserId,
        type: notificationType,
        title: notificationTitle,
        message: notificationMessage,
        data: {
          'likerId': userId,
          'likerNickname': senderNickname,
          'likerName': senderName,
          'actionType': actionType.toString(),
        },
      );

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

  /// Helper to create notifications
  Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      await firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });
    } catch (e) {
      // Silently fail notification creation
    }
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

    // Send match notifications to BOTH users
    await _sendMatchNotifications(userId, targetUserId, createdMatch.matchId);

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
      final existing = await firestore
          .collection('conversations')
          .where('matchId', isEqualTo: matchId)
          .limit(1)
          .get();

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
      print('[Discovery] Failed to create match conversation: $e');
    }
  }

  /// Send match notifications to both users
  Future<void> _sendMatchNotifications(String userId1, String userId2, String matchId) async {
    try {
      // Get both profiles for nicknames
      final profile1Doc = await firestore.collection('profiles').doc(userId1).get();
      final profile2Doc = await firestore.collection('profiles').doc(userId2).get();

      final nickname1 = profile1Doc.data()?['nickname'] as String? ?? '';
      final name1 = profile1Doc.data()?['displayName'] as String? ?? 'Someone';
      final nickname2 = profile2Doc.data()?['nickname'] as String? ?? '';
      final name2 = profile2Doc.data()?['displayName'] as String? ?? 'Someone';

      // Notification for user1
      final displayName2 = nickname2.isNotEmpty ? '@$nickname2' : name2;
      await _createNotification(
        userId: userId1,
        type: 'new_match',
        title: "Start Connecting!",
        message: "You matched with $displayName2. Start chatting now.",
        data: {
          'matchId': matchId,
          'matchedUserId': userId2,
          'matchedNickname': nickname2,
          'matchedName': name2,
        },
      );

      // Notification for user2
      final displayName1 = nickname1.isNotEmpty ? '@$nickname1' : name1;
      await _createNotification(
        userId: userId2,
        type: 'new_match',
        title: "Start Connecting!",
        message: "You matched with $displayName1. Start chatting now.",
        data: {
          'matchId': matchId,
          'matchedUserId': userId1,
          'matchedNickname': nickname1,
          'matchedName': name1,
        },
      );
    } catch (e) {
      // Silently fail notification creation
    }
  }

  @override
  Future<List<Match>> getMatches({
    required String userId,
    bool activeOnly = true,
  }) async {
    debugPrint('[getMatches] Loading matches for userId: $userId, activeOnly: $activeOnly');

    // Query matches where user is userId1
    Query query1 = firestore
        .collection('matches')
        .where('userId1', isEqualTo: userId)
        .limit(500);

    // Query matches where user is userId2
    Query query2 = firestore
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
    final List<Future<QuerySnapshot<Map<String, dynamic>>>> batchFutures = [];
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
    }
  }
}

/// Internal record for swipe history with timestamp
class _SwipeRecord {
  final String actionType;
  final DateTime timestamp;

  const _SwipeRecord({
    required this.actionType,
    required this.timestamp,
  });
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
