import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/cache/last_result_cache.dart';

import '../profile/data/models/profile_model.dart';
import '../profile/domain/entities/profile.dart';

/// Smart, HEURISTIC "Recommended for you" people ranking.
///
/// No paid ML/API: this reads a small, bounded, index-free pool of `profiles`
/// and scores each candidate against the current user purely on the client. It
/// powers the "Recommended for you" carousel on the Explore tab.
///
/// Scoring is deliberately transparent (see [recommendPeople]) so the ordering
/// is explainable and cheap to compute for millions of users — every query is a
/// single-field equality or a plain bounded batch (both served by Firestore's
/// automatic single-field indexes, so no composite index is required).
class RecommendationService {
  RecommendationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ── Scoring weights ────────────────────────────────────────────────────────
  /// Points per shared interest.
  static const double _wSharedInterest = 3;

  /// Points per shared spoken language.
  static const double _wSharedLanguage = 2;

  /// Flat bonus when the candidate is in the same city as the user.
  static const double _wSameCity = 4;

  /// Maximum proximity bonus (awarded at ~0 km, decaying to 0 at [_proxRangeKm]).
  static const double _wProximityMax = 6;

  /// Distance (km) at which the proximity bonus decays to zero.
  static const double _proxRangeKm = 500;

  /// Amplitude of the random tie-breaking jitter (keeps the row feeling fresh).
  static const double _jitterAmplitude = 1.5;

  /// How many `profiles` docs to pull per bounded batch (kept small/cheap).
  static const int _poolBatch = 40;

  /// Returns up to [limit] recommended [Profile]s for [userId], ranked by
  /// relevance to [me]. [lat]/[lng] (when provided) drive the proximity bonus.
  ///
  /// Pool fetch (cheap, index-free, in parallel): same city+country, same
  /// country, travellers in my country and same-language batches, each capped
  /// at [_poolBatch]. Only when they all come back too thin is a plain bounded
  /// batch read as a top-up (that batch is simply the first docs by id —
  /// arbitrary, so it is the last resort).
  /// Self, ghost-mode, admin/support and non-active accounts are excluded.
  Future<List<Profile>> recommendPeople({
    required String userId,
    required Profile me,
    double? lat,
    double? lng,
    int limit = 15,
    bool Function(Profile profile)? isVisible,
  }) async {
    final pool = <String, Profile>{};

    // [isVisible] is the caller's extra visibility rule (Explore passes the
    // shared discovery predicate: blocked, incognito, testers, incomplete).
    void ingest(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
      for (final doc in docs) {
        if (pool.containsKey(doc.id)) continue;
        final profile = _parse(doc.id, doc.data(), userId);
        if (profile == null) continue;
        if (isVisible != null && !isVisible(profile)) continue;
        pool[doc.id] = profile;
      }
    }

    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> read(
        Query<Map<String, dynamic>> q) async {
      try {
        return (await q.limit(_poolBatch).get()).docs;
      } catch (_) {
        return const []; // Non-fatal — the other batch may still fill the pool.
      }
    }

    // 1) Local batches, all in ONE parallel round (equality / array-contains
    //    only, so Firestore serves them from single-field indexes — no
    //    composite index):
    //    * same city AND same country (city alone mixed same-name cities in
    //      different countries); city-only if that query is rejected,
    //    * same country,
    //    * travellers currently in my country (their `location.*` is home,
    //      but scoring uses effectiveLocation, so they were never fetched),
    //    * people who speak my first language (fills sparse areas without
    //      the arbitrary top-up).
    final profiles = _firestore.collection('profiles');
    final myCity = me.effectiveLocation.city.trim();
    final myCountry = me.effectiveLocation.country.trim();
    final hasCountry =
        myCountry.isNotEmpty && myCountry.toLowerCase() != 'unknown';
    final myLanguage = me.languages
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');

    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> cityBatch() async {
      if (!hasCountry) {
        return read(profiles.where('location.city', isEqualTo: myCity));
      }
      try {
        return (await profiles
                .where('location.city', isEqualTo: myCity)
                .where('location.country', isEqualTo: myCountry)
                .limit(_poolBatch)
                .get())
            .docs;
      } catch (_) {
        return read(profiles.where('location.city', isEqualTo: myCity));
      }
    }

    final batches = await Future.wait([
      if (myCity.isNotEmpty) cityBatch(),
      if (hasCountry)
        read(profiles.where('location.country', isEqualTo: myCountry)),
      if (hasCountry)
        read(profiles
            .where('isTraveler', isEqualTo: true)
            .where('travelerLocation.country', isEqualTo: myCountry)),
      if (myLanguage.isNotEmpty)
        read(profiles.where('languages', arrayContains: myLanguage)),
    ]);
    for (final docs in batches) {
      ingest(docs);
    }

    // 2) General bounded batch — only when the local pools are too thin.
    if (pool.length < limit) {
      ingest(await read(profiles));
    }

    if (pool.isEmpty) return const <Profile>[];

    final rng = math.Random();
    final myInterests = _lower(me.interests);
    final myLanguages = _lower(me.languages);
    final myCityLower = myCity.toLowerCase();

    final scored = pool.values.map((candidate) {
      double score = 0;

      // Shared interests / languages (set intersection counts).
      score += _sharedCount(myInterests, _lower(candidate.interests)) *
          _wSharedInterest;
      score +=
          _sharedCount(myLanguages, _lower(candidate.languages)) * _wSharedLanguage;

      // Same city.
      final candCity = candidate.effectiveLocation.city.trim().toLowerCase();
      if (myCityLower.isNotEmpty && candCity == myCityLower) {
        score += _wSameCity;
      }

      // Proximity bonus (closer == higher), when both sides have coordinates.
      final candLoc = candidate.effectiveLocation;
      if (lat != null &&
          lng != null &&
          (candLoc.latitude != 0 || candLoc.longitude != 0)) {
        final km = _distanceKm(lat, lng, candLoc.latitude, candLoc.longitude);
        final proximity =
            _wProximityMax * (1 - (math.min(km, _proxRangeKm) / _proxRangeKm));
        score += proximity;
      }

      // Small jitter so equally-scored people don't freeze in one order.
      score += rng.nextDouble() * _jitterAmplitude;

      return _Scored(candidate, score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final result = scored.take(limit).map((s) => s.profile).toList();
    // Ids for an instant paint on the next open ([cachedRecommendations]).
    unawaited(LastResultCache.saveIds(cacheKey, result.map((p) => p.userId)));
    return result;
  }

  /// [LastResultCache] key of the last server-ranked result.
  static const String cacheKey = 'recommendations_v1';

  /// The last ranked result, read by id from the LOCAL Firestore cache only
  /// (no network), with the same exclusions as [recommendPeople]. Paint it
  /// only when NON-EMPTY, then call [recommendPeople] and replace it.
  Future<List<Profile>> cachedRecommendations({
    required String userId,
    bool Function(Profile profile)? isVisible,
  }) async {
    try {
      final docs = await LastResultCache.loadDocs(
          cacheKey, _firestore.collection('profiles'));
      final out = <Profile>[];
      for (final doc in docs) {
        final data = doc.data();
        if (data == null) continue;
        final p = _parse(doc.id, data, userId);
        if (p == null) continue;
        if (isVisible != null && !isVisible(p)) continue;
        out.add(p);
      }
      return out;
    } catch (_) {
      return const <Profile>[];
    }
  }

  /// Parses a `profiles` document into a [Profile], or null when it must not be
  /// surfaced (self, ghost-mode, admin/support, or non-active account).
  Profile? _parse(String id, Map<String, dynamic> d, String userId) {
    if (id == userId) return null;
    if (d['isGhostMode'] == true) return null;
    if (d['isAdmin'] == true || d['isSupport'] == true) return null;
    final status = d['accountStatus'];
    if (status != null && status != 'active') return null;
    try {
      return ProfileModel.fromJson({...d, 'userId': id});
    } catch (_) {
      return null;
    }
  }

  List<String> _lower(List<String> values) => values
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  int _sharedCount(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final setB = b.toSet();
    return a.where(setB.contains).length;
  }

  /// Haversine great-circle distance in kilometres.
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    double toRad(double d) => d * math.pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }
}

class _Scored {
  const _Scored(this.profile, this.score);
  final Profile profile;
  final double score;
}
