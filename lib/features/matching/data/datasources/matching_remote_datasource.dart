import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/candidate_pool_service.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/data/profile_geohash.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/match_candidate.dart';
import '../../domain/entities/match_preferences.dart';
import '../../domain/entities/match_score.dart';
import '../../domain/entities/user_vector.dart';
import '../../domain/repositories/matching_repository.dart';
import '../../domain/usecases/compatibility_scorer.dart';
import '../../domain/usecases/feature_engineer.dart';
import '../models/match_preferences_model.dart';
import '../models/user_vector_model.dart';
import '../../../profile/data/private_profile.dart';
import '../../../profile/data/profile_geo_scan.dart';

/// Matching Remote Data Source
///
/// Handles all Firestore operations for matching feature
abstract class MatchingRemoteDataSource {
  /// Get potential matches for a user
  Future<List<MatchCandidate>> getMatchCandidates({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  });

  /// Get user vector from Firestore
  Future<UserVector> getUserVector(String userId);

  /// Save user vector to Firestore
  Future<void> saveUserVector(UserVector vector);

  /// Get match preferences
  Future<MatchPreferences> getMatchPreferences(String userId);

  /// Save match preferences
  Future<void> saveMatchPreferences(MatchPreferences preferences);

  /// Record user interaction
  Future<void> recordInteraction({
    required String userId,
    required String targetUserId,
    required InteractionType interactionType,
  });

  /// Get collaborative filtering score
  Future<double> getCollaborativeScore(String userId, String targetUserId);
}

/// Implementation of Matching Remote Data Source
class MatchingRemoteDataSourceImpl implements MatchingRemoteDataSource {

  MatchingRemoteDataSourceImpl({
    required this.firestore,
    FeatureEngineer? featureEngineer,
    CompatibilityScorer? compatibilityScorer,
    this.candidatePoolService,
  })  : featureEngineer = featureEngineer ?? FeatureEngineer(),
        compatibilityScorer = compatibilityScorer ?? CompatibilityScorer();
  final FirebaseFirestore firestore;
  final FeatureEngineer featureEngineer;
  final CompatibilityScorer compatibilityScorer;
  final CandidatePoolService? candidatePoolService;

  @override
  Future<List<MatchCandidate>> getMatchCandidates({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  }) async {
    final hasCountries = preferences.preferredCountries.isNotEmpty;

    // Everything that does not depend on the viewer's profile starts NOW, in
    // parallel with the profile read (these used to run one after another).
    final userDocFuture = firestore.collection('profiles').doc(userId).get();
    final travelerIdsFuture = _getTravelerIdsInCountries(preferences: preferences);

    // LOCATION-FIRST (worldwide mode): when the viewer's coordinates are known
    // (local cache, instant) query the profiles whose `geohash` falls within
    // maxDistance — the people who will actually be shown first — instead of
    // a random worldwide slice that rarely contains anyone nearby.
    final cachedCoordsFuture =
        hasCountries ? null : _viewerCoordsFromCache(userId);
    final geoFuture = cachedCoordsFuture?.then((c) => c == null
        ? null
        : _geoScan(c.$1, c.$2, preferences.maxDistance));
    geoFuture?.ignore();
    // With no distance limit the random slice is always part of the pool, so
    // it starts now too (as it always did); with an explicit radius it is
    // only read if the nearby result is thin.
    final eagerRandom =
        hasCountries || _isExplicitRadius(preferences.maxDistance)
            ? null
            : _randomWorldwideScan();
    eagerRandom?.ignore();
    final userDoc = await userDocFuture;
    if (!userDoc.exists) throw Exception('User profile not found');
    // The viewer's own view (exact private location, birth date). Candidate
    // profiles stay public views: their distance comes from approxLocation.
    final viewerRaw = (await ownRawViewLoaded(userId, userDoc.data()))!;

    final userProfile = ProfileModel.fromJson({...viewerRaw, 'userId': userId});

    // Pre-computed pools are only consulted with a country filter.
    final poolCandidateIds = hasCountries
        ? await _getPoolCandidateIds(
            userProfile: userProfile,
            preferences: preferences,
          )
        : null;

    List<QueryDocumentSnapshot<Map<String, dynamic>>> profileDocs;

    if (poolCandidateIds != null && poolCandidateIds.isNotEmpty) {
      // Pool path: fetch pool candidates + supplement with direct country scan
      // Pool only contains verified profiles with photos — direct scan catches the rest
      final results = await Future.wait([
        travelerIdsFuture,
        _countryScan(preferences.preferredCountries, includeUnknown: false),
      ]);
      final travelerIds = results[0] as List<String>;
      final scanned =
          results[1] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
      final allIds = {
        ...poolCandidateIds,
        ...travelerIds,
        ...scanned.map((d) => d.id),
      };

      final idList = allIds.toList();
      debugPrint('[Matching] Using pool: ${poolCandidateIds.length} pool + ${idList.length - poolCandidateIds.length} extra = ${idList.length}');
      profileDocs = await _fetchProfilesByIds(idList);
    } else {
      // Fallback: full scan (pools unavailable, stale, or empty)
      // When no country filter is active, use random starting point so each
      // refresh gives a different set of worldwide profiles.
      debugPrint('[Matching] Pool unavailable, falling back to full scan');

      if (!hasCountries) {
        profileDocs = await _worldwide(
          cachedCoordsFuture: cachedCoordsFuture!,
          geoFuture: geoFuture!,
          viewerData: viewerRaw,
          maxDistanceKm: preferences.maxDistance,
          eagerRandom: eagerRandom,
        );
      } else {
        profileDocs = await _countryScan(
          preferences.preferredCountries,
          includeUnknown: true,
        );
        debugPrint('[Matching] Country-filtered scan: ${profileDocs.length} profiles for ${preferences.preferredCountries}');
      }

      // Merge travelers that may not be in the first 500 docs
      final existingIds = profileDocs.map((d) => d.id).toSet();
      final travelerIds = await travelerIdsFuture;
      final missingTravelerIds = travelerIds.where((id) => !existingIds.contains(id)).toList();
      if (missingTravelerIds.isNotEmpty) {
        debugPrint('[Matching] Adding ${missingTravelerIds.length} missing travelers to fallback scan');
        final travelerDocs = await _fetchProfilesByIds(missingTravelerIds);
        profileDocs = [...profileDocs, ...travelerDocs];
      }
    }

    // Parsing + scoring hundreds of profiles is the expensive part, so it runs
    // on a background isolate (plain maps in, plain entities out).
    final request = CandidateBuildRequest(
      userId: userId,
      viewerData: viewerRaw,
      docIds: [for (final d in profileDocs) d.id],
      docData: [for (final d in profileDocs) d.data()],
      minAge: preferences.minAge,
      maxAge: preferences.maxAge,
      preferredGenders: preferences.preferredGenders,
      applyDistanceCap: hasCountries,
      maxDistance: preferences.maxDistance,
      dealBreakerInterests: preferences.dealBreakerInterests,
    );
    return buildCandidatesOffThread(request);
  }

  /// Minimum nearby profiles before the location-first scan is considered
  /// enough on its own; below this the random worldwide slice pads it.
  static const int _geoEnough = 60;

  /// Per geohash-range read size (up to 9 ranges, in parallel).
  static const int _geoPerRange = 40;

  /// Above this radius a geohash scan covers most of the planet and is no
  /// better than the random slice, so the "no limit" radius below is used.
  static const double _geoMaxRadiusKm = 2000;

  /// "Nearby" radius merged in front of worldwide (no distance limit) results.
  static const double _defaultNearbyKm = 200;

  static bool _isExplicitRadius(double km) => km > 0 && km <= _geoMaxRadiusKm;

  /// The viewer's discoverable coordinates (active travel location, else
  /// home) from the LOCAL Firestore cache only. Null when unknown, so the
  /// caller simply keeps the previous behaviour.
  Future<(double, double)?> _viewerCoordsFromCache(String userId) async {
    try {
      final doc = await firestore
          .collection('profiles')
          .doc(userId)
          .get(const GetOptions(source: Source.cache));
      // Own exact location: profiles_private (security P1-4).
      final data = ownRawView(userId, doc.data());
      return data == null ? null : discoverableCoords(data);
    } catch (_) {
      return null;
    }
  }

  /// Profiles within [maxDistanceKm] of the point via up to 9 parallel
  /// range reads on the public `geohash5` (ProfileGeoScan; single-field
  /// index, no composite). Profiles without a cell are simply not returned
  /// here — the random slice still covers them. Returns null when the scan
  /// is not applicable or fails, so the caller falls back to the old path.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>?> _geoScan(
    double lat,
    double lng,
    double maxDistanceKm,
  ) async {
    final radiusKm =
        _isExplicitRadius(maxDistanceKm) ? maxDistanceKm : _defaultNearbyKm;
    try {
      final out = await ProfileGeoScan(firestore, perRange: _geoPerRange)
          .near(lat, lng, radiusKm);
      debugPrint('[Matching] Geo scan: ${out.length} profiles '
          '(${radiusKm.round()} km)');
      return out;
    } catch (e) {
      debugPrint('[Matching] Geo scan unavailable, using random slice: $e');
      return null;
    }
  }

  /// Worldwide pool: nearby people first (geo scan) plus the random
  /// worldwide slice.
  ///  * An explicit distance (<= [_geoMaxRadiusKm]): the geo scan alone when
  ///    it found enough people, padded with the random slice when thin.
  ///  * No distance limit (default worldwide browsing): the random slice as
  ///    before, with the nearest people within [_defaultNearbyKm] merged in
  ///    front so a nearest-first grid actually starts with people nearby.
  /// With no geo result (no coords, profiles not geohashed yet, query
  /// failure) this is exactly the previous random slice.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _worldwide({
    required Future<(double, double)?> cachedCoordsFuture,
    required Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>
        geoFuture,
    required Map<String, dynamic>? viewerData,
    required double maxDistanceKm,
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>? eagerRandom,
  }) async {
    final explicit = _isExplicitRadius(maxDistanceKm);
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> random() =>
        eagerRandom ?? _randomWorldwideScan();
    final cached = await cachedCoordsFuture;
    if (cached == null) {
      // Not in the local cache: use the server profile we just read, with the
      // random slice alongside so a thin area costs no extra latency.
      final c = viewerData == null ? null : discoverableCoords(viewerData);
      if (c == null) return random();
      final both = await Future.wait([
        _geoScan(c.$1, c.$2, maxDistanceKm),
        random(),
      ]);
      return _mergeGeo(both[0], both[1]!, padAlways: !explicit);
    }
    if (!explicit) {
      final both = await Future.wait([geoFuture, random()]);
      return _mergeGeo(both[0], both[1]!, padAlways: true);
    }
    final geo = await geoFuture;
    if (geo != null && geo.length >= _geoEnough) return geo;
    return _mergeGeo(geo, await random(), padAlways: true);
  }

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> _mergeGeo(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? geo,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> random, {
    required bool padAlways,
  }) {
    if (geo == null || geo.isEmpty) return random;
    if (!padAlways && geo.length >= _geoEnough) return geo;
    final seen = geo.map((d) => d.id).toSet();
    return [...geo, ...random.where((d) => seen.add(d.id))];
  }

  /// Random worldwide slice (no country filter): two bounded reads either side
  /// of a random document-id pivot, fetched in parallel. (150 total — it is a
  /// fallback/padding now; it used to read 500 full profiles every load.)
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _randomWorldwideScan() async {
    final randomKey = _generateRandomDocId();
    debugPrint('[Matching] Random worldwide mode — pivot: $randomKey');
    final snaps = await Future.wait([
      firestore
          .collection('profiles')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: randomKey)
          .limit(75)
          .get(),
      firestore
          .collection('profiles')
          .where(FieldPath.documentId, isLessThan: randomKey)
          .limit(75)
          .get(),
    ]);
    debugPrint('[Matching] Random scan: ${snaps[0].docs.length} + ${snaps[1].docs.length}');
    return [...snaps[0].docs, ...snaps[1].docs];
  }

  /// Country-filtered scan, all queries in parallel and de-duplicated:
  ///  * exact `location.country` (e.g. "Italy"),
  ///  * `location.countryLower` (profiles geocoded in another locale),
  ///  * optionally profiles with an unknown/empty country, which the country
  ///    `whereIn` would otherwise make invisible to everyone.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _countryScan(
    List<String> countries, {
    required bool includeUnknown,
  }) async {
    final countriesLower = countries.map((c) => c.toLowerCase()).toList();
    Future<QuerySnapshot<Map<String, dynamic>>?> optional(
        Future<QuerySnapshot<Map<String, dynamic>>> q) async {
      try {
        return await q;
      } catch (_) {
        return null; // best-effort supplement (field may not exist yet)
      }
    }

    final snaps = await Future.wait([
      firestore
          .collection('profiles')
          .where('location.country', whereIn: countries)
          .limit(500)
          .get(),
      optional(firestore
          .collection('profiles')
          .where('location.countryLower', whereIn: countriesLower)
          .limit(500)
          .get()),
      if (includeUnknown)
        optional(firestore
            .collection('profiles')
            .where('location.country', whereIn: ['Unknown', ''])
            .limit(200)
            .get()),
    ]);

    final seenIds = <String>{};
    final out = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final snap in snaps) {
      if (snap == null) continue;
      for (final doc in snap.docs) {
        if (seenIds.add(doc.id)) out.add(doc);
      }
    }
    return out;
  }

  /// Try to get candidate user IDs from pre-computed pools.
  /// Returns null if pools are unavailable or stale.
  Future<List<String>?> _getPoolCandidateIds({
    required Profile userProfile,
    required MatchPreferences preferences,
  }) async {
    if (candidatePoolService == null) return null;

    try {
      // Use preferred countries if set; when no country filter is active,
      // skip the pool entirely so the fallback full scan returns worldwide profiles.
      if (preferences.preferredCountries.isEmpty) {
        debugPrint('[Matching] No country filter — skipping pool, using worldwide fallback');
        return null;
      }
      final countries = preferences.preferredCountries;

      final poolCandidates = await candidatePoolService!.getCandidatesFromPools(
        countries: countries,
        genders: preferences.preferredGenders,
        minAge: preferences.minAge,
        maxAge: preferences.maxAge,
      );

      if (poolCandidates == null || poolCandidates.isEmpty) return null;

      // Pre-filter by distance using pool metadata (avoids fetching distant profiles)
      final userLoc = userProfile.effectiveLocation;
      final filtered = <String>[];

      for (final pc in poolCandidates) {
        // Skip candidates with no location
        if (pc.lat == 0 && pc.lng == 0) {
          filtered.add(pc.userId);
          continue;
        }
        // Skip if user has no location
        if (userLoc.latitude == 0 && userLoc.longitude == 0) {
          filtered.add(pc.userId);
          continue;
        }

        final distance = featureEngineer.calculateDistance(
          userLoc.latitude,
          userLoc.longitude,
          pc.lat,
          pc.lng,
        );

        if (distance <= preferences.maxDistance) {
          filtered.add(pc.userId);
        }
      }

      debugPrint('[Matching] Pool pre-filter: ${poolCandidates.length} → ${filtered.length} (distance)');
      return filtered.isEmpty ? null : filtered;
    } catch (e) {
      debugPrint('[Matching] Pool lookup failed, falling back: $e');
      return null;
    }
  }

  /// Active-traveler ids per country filter, memoised for the session (the
  /// set changes slowly; every discovery load used to re-read 200 profiles).
  static final Map<String, (DateTime, List<String>)> _travelerMemo = {};
  static const Duration _travelerMemoTtl = Duration(minutes: 5);

  /// Fetch active travelers whose travelerLocation.country matches the target countries.
  /// These users are missed by the pool system because pools are indexed by home country.
  ///
  /// Server-side: `isTraveler == true && travelerExpiry > now`, ordered by
  /// expiry, limit 100 (index profiles(isTraveler, travelerExpiry)). With a
  /// country filter it also narrows by `travelerLocation.country in [...]`
  /// (needs index profiles(isTraveler, travelerLocation.country,
  /// travelerExpiry)); if that is rejected it drops the country clause, and if
  /// the expiry query is rejected too it falls back to the previous
  /// single-field read. The expiry and country checks still run in memory on
  /// every path as the safety net.
  Future<List<String>> _getTravelerIdsInCountries({
    required MatchPreferences preferences,
  }) async {
    try {
      // When no country filter is active, include all travelers worldwide
      final filterByCountry = preferences.preferredCountries.isNotEmpty;
      final countries = filterByCountry
          ? preferences.preferredCountries.map((c) => c.toLowerCase()).toList()
          : <String>[];

      final memoKey = ([...countries]..sort()).join('|');
      final memo = _travelerMemo[memoKey];
      if (memo != null && DateTime.now().difference(memo.$1) < _travelerMemoTtl) {
        return memo.$2;
      }

      final now = DateTime.now();
      final travelerIds = <String>[];

      Query<Map<String, dynamic>> active() => firestore
          .collection('profiles')
          .where('isTraveler', isEqualTo: true)
          .where('travelerExpiry', isGreaterThan: Timestamp.fromDate(now));

      // Exact spellings the user picked plus their lower-case forms
      // (Firestore `in` is case-sensitive; max 30 values).
      final countryValues = <String>{
        ...preferences.preferredCountries,
        ...countries,
      }.take(30).toList();

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        var q = active();
        if (filterByCountry) {
          q = q.where('travelerLocation.country', whereIn: countryValues);
        }
        snapshot = await q.orderBy('travelerExpiry').limit(100).get();
      } catch (e) {
        debugPrint('[Matching] Traveler indexed query failed ($e) — fallback');
        try {
          snapshot =
              await active().orderBy('travelerExpiry').limit(100).get();
        } catch (_) {
          // Single-field query — no composite index needed
          snapshot = await firestore
              .collection('profiles')
              .where('isTraveler', isEqualTo: true)
              .limit(200)
              .get();
        }
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Check traveler expiry is still active
        final expiry = data['travelerExpiry'];
        if (expiry == null || expiry is! Timestamp || !expiry.toDate().isAfter(now)) {
          continue;
        }

        // Check traveler country matches target countries (skip if no filter)
        if (filterByCountry) {
          final travelerLoc = data['travelerLocation'] as Map<String, dynamic>?;
          if (travelerLoc == null) continue;
          final travelerCountry = (travelerLoc['country'] as String? ?? '').toLowerCase();
          if (travelerCountry.isEmpty || !countries.contains(travelerCountry)) {
            continue;
          }
        }

        travelerIds.add(doc.id);
      }

      debugPrint('[Matching] Found ${travelerIds.length} active travelers in $countries');
      _travelerMemo[memoKey] = (DateTime.now(), travelerIds);
      return travelerIds;
    } catch (e) {
      debugPrint('[Matching] Traveler lookup failed: $e');
      return [];
    }
  }

  /// Fetch profile documents by a list of user IDs in parallel batches of 10.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchProfilesByIds(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return [];

    // Cap at 500 to match previous behavior
    final idsToFetch = userIds.length > 500 ? userIds.sublist(0, 500) : userIds;

    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < idsToFetch.length; i += 10) {
      final batch = idsToFetch.sublist(
        i,
        i + 10 > idsToFetch.length ? idsToFetch.length : i + 10,
      );
      futures.add(
        firestore
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get(),
      );
    }

    final results = await Future.wait(futures);
    return results.expand((snapshot) => snapshot.docs).toList();
  }

  @override
  Future<UserVector> getUserVector(String userId) async {
    final doc = await firestore.collection('user_vectors').doc(userId).get();

    if (!doc.exists) {
      throw Exception('User vector not found for user: $userId');
    }

    return UserVectorModel.fromFirestore(doc);
  }

  @override
  Future<void> saveUserVector(UserVector vector) async {
    final model = UserVectorModel.fromEntity(vector);
    await firestore
        .collection('user_vectors')
        .doc(vector.userId)
        .set(model.toFirestore());
  }

  @override
  Future<MatchPreferences> getMatchPreferences(String userId) async {
    final doc =
        await firestore.collection('match_preferences').doc(userId).get();

    if (!doc.exists) {
      // Return default preferences
      return MatchPreferences.defaultFor(userId);
    }

    return MatchPreferencesModel.fromFirestore(doc);
  }

  @override
  Future<void> saveMatchPreferences(MatchPreferences preferences) async {
    final model = MatchPreferencesModel.fromEntity(preferences);
    await firestore
        .collection('match_preferences')
        .doc(preferences.userId)
        .set(model.toFirestore());
  }

  @override
  Future<void> recordInteraction({
    required String userId,
    required String targetUserId,
    required InteractionType interactionType,
  }) async {
    await firestore.collection('user_interactions').add({
      'userId': userId,
      'targetUserId': targetUserId,
      'interactionType': interactionType.toString().split('.').last,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<double> getCollaborativeScore(
    String userId,
    String targetUserId,
  ) async {
    // TODO: Implement actual collaborative filtering using:
    // 1. Matrix factorization (SVD)
    // 2. Item-based collaborative filtering
    // 3. User-based collaborative filtering
    //
    // For now, return placeholder score based on simple heuristics

    try {
      // Get interactions for current user
      final userInteractions = await firestore
          .collection('user_interactions')
          .where('userId', isEqualTo: userId)
          .limit(500)
          .get();

      if (userInteractions.docs.isEmpty) {
        return 50.0; // Neutral score for new users
      }

      // Count positive interactions
      var positiveCount = 0;
      for (final doc in userInteractions.docs) {
        final type = doc.data()['interactionType'] as String;
        if (type == 'like' || type == 'superLike' || type == 'match') {
          positiveCount++;
        }
      }

      // Simple heuristic: more positive interactions = higher base score
      final baseScore = (positiveCount / userInteractions.docs.length) * 100;

      return baseScore.clamp(0.0, 100.0);
    } catch (e) {
      return 50.0; // Default to neutral on error
    }
  }

  /// Generate a random Firestore-style document ID for random pivot queries
  static String _generateRandomDocId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random();
    return String.fromCharCodes(
      Iterable.generate(20, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }
}

/// Plain-data input for [buildCandidatesOffThread]. Holds only maps, strings
/// and numbers so it can cross an isolate boundary.
class CandidateBuildRequest {
  const CandidateBuildRequest({
    required this.userId,
    this.viewerData = const {},
    this.viewer,
    required this.docIds,
    required this.docData,
    this.minAge = 18,
    this.maxAge = 99,
    this.preferredGenders = const [],
    this.applyDistanceCap = false,
    this.maxDistance = 99999,
    this.dealBreakerInterests = const [],
    this.shuffle = true,
  });

  final String userId;

  /// The viewer's raw `profiles/{userId}` data (ignored when [viewer] is set).
  final Map<String, dynamic> viewerData;

  /// The viewer's already-parsed profile, when the caller has one.
  final Profile? viewer;

  /// Candidate document ids and their raw data, index-aligned.
  final List<String> docIds;
  final List<Map<String, dynamic>> docData;

  final int minAge;
  final int maxAge;
  final List<String> preferredGenders;

  /// Only a country-filtered search caps by [maxDistance]; worldwide browsing
  /// shows everyone sorted by distance.
  final bool applyDistanceCap;
  final double maxDistance;
  final List<String> dealBreakerInterests;

  /// Shuffle the result (the matching feed's historical behaviour).
  final bool shuffle;
}

/// Parses, filters and scores candidate profiles on a background isolate.
///
/// Falls back to the calling isolate if the payload cannot be sent (e.g. an
/// unexpected non-sendable value inside a document), so it never fails where
/// the old inline loop would have succeeded. On web `compute` already runs
/// inline.
Future<List<MatchCandidate>> buildCandidatesOffThread(
  CandidateBuildRequest request,
) async {
  if (request.docIds.isEmpty) return <MatchCandidate>[];
  try {
    return await compute(buildCandidates, request);
  } catch (e) {
    debugPrint('[Matching] Background build unavailable, running inline: $e');
    return buildCandidates(request);
  }
}

/// The candidate build itself (top-level so it can run in an isolate).
/// Skips self and suspended/banned/deleted accounts, applies the age / gender /
/// distance / deal-breaker filters (all bypassed for admin/support candidates
/// and for admin/support viewers) and computes the compatibility score.
List<MatchCandidate> buildCandidates(CandidateBuildRequest r) {
  final userProfile =
      r.viewer ?? ProfileModel.fromJson({...r.viewerData, 'userId': r.userId});
  final userLoc = userProfile.effectiveLocation;
  final isCurrentUserAdmin = userProfile.isAdmin || userProfile.isSupport;
  final featureEngineer = FeatureEngineer();
  final compatibilityScorer =
      CompatibilityScorer(featureEngineer: featureEngineer);
  final genders = r.preferredGenders.map((g) => g.toLowerCase()).toList();

  final candidates = <MatchCandidate>[];
  final now = DateTime.now();

  for (var i = 0; i < r.docIds.length; i++) {
    final id = r.docIds[i];
    // Skip self
    if (id == r.userId) continue;

    try {
      final candidateProfile =
          ProfileModel.fromJson({...r.docData[i], 'userId': id});

      // Skip explicitly suspended/banned/deleted profiles
      final status = candidateProfile.accountStatus.toLowerCase();
      if (status == 'suspended' || status == 'banned' || status == 'deleted') {
        continue;
      }

      // Admin/support profiles bypass all filters — always visible
      final isPrivileged = candidateProfile.isAdmin || candidateProfile.isSupport;

      // Admin users see ALL profiles (bypass age, gender, distance filters).
      // Users are visible immediately after registration — no verification
      // or photo gate.
      if (!isCurrentUserAdmin && !isPrivileged) {
        final age = candidateProfile.age;
        if (age > 0 && (age < r.minAge || age > r.maxAge)) continue;

        if (genders.isNotEmpty) {
          final gender = candidateProfile.gender;
          if (gender.isNotEmpty && !genders.contains(gender.toLowerCase())) {
            continue;
          }
        }
      }

      // Apply distance filter (skip for admin/support candidates and admin users)
      final candidateLoc = candidateProfile.effectiveLocation;
      var distance = 0.0;
      if (!isPrivileged && !isCurrentUserAdmin &&
          userLoc.latitude != 0 &&
          userLoc.longitude != 0 &&
          candidateLoc.latitude != 0 &&
          candidateLoc.longitude != 0) {
        distance = featureEngineer.calculateDistance(
          userLoc.latitude,
          userLoc.longitude,
          candidateLoc.latitude,
          candidateLoc.longitude,
        );
        if (r.applyDistanceCap && distance > r.maxDistance) continue;
      }

      // Apply deal-breaker interests (skip for admin/support and admin users)
      if (!isPrivileged && !isCurrentUserAdmin && r.dealBreakerInterests.isNotEmpty) {
        final hasAllDealBreakers = r.dealBreakerInterests.every(
          candidateProfile.interests.contains,
        );
        if (!hasAllDealBreakers) continue;
      }

      // Calculate compatibility score
      // Admin/support candidates always show 100% compatibility
      MatchScore matchScore;
      if (isPrivileged) {
        matchScore = MatchScore(
          userId1: r.userId,
          userId2: candidateProfile.userId,
          overallScore: 100.0,
          breakdown: const ScoreBreakdown(
            locationScore: 100.0,
            ageCompatibilityScore: 100.0,
            interestOverlapScore: 100.0,
            languageScore: 100.0,
          ),
          calculatedAt: now,
        );
      } else {
        try {
          matchScore = compatibilityScorer.calculateScore(
            profile1: userProfile,
            profile2: candidateProfile,
          );
        } catch (_) {
          // If scoring fails, use a default neutral score
          matchScore = MatchScore(
            userId1: r.userId,
            userId2: candidateProfile.userId,
            overallScore: 50.0,
            breakdown: const ScoreBreakdown(
              locationScore: 50.0,
              ageCompatibilityScore: 50.0,
              interestOverlapScore: 50.0,
              languageScore: 50.0,
            ),
            calculatedAt: now,
          );
        }
      }

      candidates.add(MatchCandidate(
        profile: candidateProfile,
        matchScore: matchScore,
        distance: distance,
        suggestedAt: now,
        isSuperLike: matchScore.overallScore >= 80.0,
      ));
    } catch (_) {
      continue;
    }
  }

  // Shuffle candidates randomly so users see a different order each time
  if (r.shuffle) candidates.shuffle(Random());

  // Return ALL candidates (no limit) for endless scrolling
  return candidates;
}
