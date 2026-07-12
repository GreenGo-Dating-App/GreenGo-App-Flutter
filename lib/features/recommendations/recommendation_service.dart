import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

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
  static const int _poolBatch = 80;

  /// Returns up to [limit] recommended [Profile]s for [userId], ranked by
  /// relevance to [me]. [lat]/[lng] (when provided) drive the proximity bonus.
  ///
  /// Pool fetch (cheap, index-free): a same-city equality batch (when the user
  /// has a city) merged with a plain bounded batch — both capped at [_poolBatch].
  /// Self, ghost-mode, admin/support and non-active accounts are excluded.
  Future<List<Profile>> recommendPeople({
    required String userId,
    required Profile me,
    double? lat,
    double? lng,
    int limit = 15,
  }) async {
    final pool = <String, Profile>{};

    void ingest(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
      for (final doc in docs) {
        if (pool.containsKey(doc.id)) continue;
        final profile = _parse(doc.id, doc.data(), userId);
        if (profile != null) pool[doc.id] = profile;
      }
    }

    // 1) Same-city batch — a single-field equality query (auto-indexed).
    final myCity = me.effectiveLocation.city.trim();
    if (myCity.isNotEmpty) {
      try {
        final snap = await _firestore
            .collection('profiles')
            .where('location.city', isEqualTo: myCity)
            .limit(_poolBatch)
            .get();
        ingest(snap.docs);
      } catch (_) {
        // Non-fatal — fall through to the general batch.
      }
    }

    // 2) General bounded batch — a plain capped read (auto-indexed).
    if (pool.length < _poolBatch) {
      try {
        final snap =
            await _firestore.collection('profiles').limit(_poolBatch).get();
        ingest(snap.docs);
      } catch (_) {
        // Keep whatever we have.
      }
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

    return scored.take(limit).map((s) => s.profile).toList();
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
