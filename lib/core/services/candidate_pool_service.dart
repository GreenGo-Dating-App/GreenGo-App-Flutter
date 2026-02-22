import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Lightweight representation of a candidate from a pre-computed pool.
///
/// Contains just enough data for the matching pipeline to filter and
/// score without fetching the full profile document.
class PoolCandidate {
  final String userId;
  final int age;
  final double lat;
  final double lng;
  final List<String> interests;
  final List<String> languages;
  final bool isVerified;
  final bool isBoosted;
  final DateTime? boostExpiry;
  final bool isOnline;
  final DateTime? lastActive;
  final String? sexualOrientation;

  const PoolCandidate({
    required this.userId,
    required this.age,
    required this.lat,
    required this.lng,
    required this.interests,
    required this.languages,
    required this.isVerified,
    required this.isBoosted,
    this.boostExpiry,
    required this.isOnline,
    this.lastActive,
    this.sexualOrientation,
  });

  factory PoolCandidate.fromMap(Map<String, dynamic> map) {
    return PoolCandidate(
      userId: map['userId'] as String,
      age: (map['age'] as num?)?.toInt() ?? 0,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      interests: List<String>.from(map['interests'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      isVerified: map['isVerified'] as bool? ?? false,
      isBoosted: map['isBoosted'] as bool? ?? false,
      boostExpiry: map['boostExpiry'] != null
          ? DateTime.tryParse(map['boostExpiry'] as String)
          : null,
      isOnline: map['isOnline'] as bool? ?? false,
      lastActive: map['lastActive'] != null
          ? DateTime.tryParse(map['lastActive'] as String)
          : null,
      sexualOrientation: map['sexualOrientation'] as String?,
    );
  }
}

/// Pre-computed candidate pool read from Firestore.
class CandidatePool {
  final String poolKey;
  final String country;
  final String gender;
  final String ageBucket;
  final List<PoolCandidate> members;
  final DateTime? updatedAt;

  const CandidatePool({
    required this.poolKey,
    required this.country,
    required this.gender,
    required this.ageBucket,
    required this.members,
    this.updatedAt,
  });

  /// Pool is considered stale if older than 1 hour.
  bool get isStale {
    if (updatedAt == null) return true;
    return DateTime.now().difference(updatedAt!).inMinutes > 60;
  }
}

/// Age bucket definitions — must match the Cloud Function.
class _AgeBucket {
  final int min;
  final int max;
  const _AgeBucket(this.min, this.max);
  String get key => '$min-$max';
}

const _ageBuckets = [
  _AgeBucket(18, 24),
  _AgeBucket(25, 34),
  _AgeBucket(35, 44),
  _AgeBucket(45, 54),
  _AgeBucket(55, 64),
  _AgeBucket(65, 99),
];

/// Service for reading pre-computed candidate pools from Firestore.
///
/// Used by the matching pipeline to narrow the set of profiles to fetch
/// instead of scanning the entire profiles collection.
class CandidatePoolService {
  final FirebaseFirestore firestore;

  static const _poolCollection = 'candidate_pools';
  static const _cacheTtl = Duration(minutes: 10);

  /// In-memory cache: poolKey → CandidatePool
  final Map<String, _CachedPool> _cache = {};

  CandidatePoolService({required this.firestore});

  /// Returns candidate user IDs from pools matching the given preferences.
  ///
  /// [country] — country to search in (e.g. "Germany")
  /// [genders] — list of preferred genders (empty = all genders)
  /// [minAge], [maxAge] — age range filter
  ///
  /// Returns `null` if no pools are available (caller should fall back
  /// to the full-scan approach).
  Future<List<PoolCandidate>?> getCandidatesFromPools({
    required String country,
    required List<String> genders,
    required int minAge,
    required int maxAge,
  }) async {
    // Determine which age buckets overlap with the requested range
    final overlappingBuckets = _ageBuckets.where(
      (b) => b.min <= maxAge && b.max >= minAge,
    );

    if (overlappingBuckets.isEmpty) return null;

    // Determine gender keys to query
    final genderKeys = genders.isEmpty
        ? ['Male', 'Female', 'Non-binary', 'Unknown']
        : genders;

    // Build pool keys to fetch
    final poolKeys = <String>[];
    final sanitizedCountry = country.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    for (final gender in genderKeys) {
      final sanitizedGender = gender.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      for (final bucket in overlappingBuckets) {
        poolKeys.add('${sanitizedCountry}_${sanitizedGender}_${bucket.key}');
      }
    }

    if (poolKeys.isEmpty) return null;

    // Fetch pools (from cache or Firestore)
    final pools = await _fetchPools(poolKeys);

    if (pools.isEmpty) {
      debugPrint('[CandidatePoolService] No pools found for $country / $genderKeys / $minAge-$maxAge');
      return null;
    }

    // Flatten members, applying fine-grained age filter
    final candidates = <PoolCandidate>[];
    for (final pool in pools) {
      for (final member in pool.members) {
        if (member.age >= minAge && member.age <= maxAge) {
          candidates.add(member);
        }
      }
    }

    debugPrint('[CandidatePoolService] Found ${candidates.length} candidates from ${pools.length} pools');
    return candidates;
  }

  /// Fetch multiple pools by key, using cache where valid.
  Future<List<CandidatePool>> _fetchPools(List<String> poolKeys) async {
    final results = <CandidatePool>[];
    final keysToFetch = <String>[];

    // Check cache first
    for (final key in poolKeys) {
      final cached = _cache[key];
      if (cached != null && cached.isValid) {
        results.add(cached.pool);
      } else {
        keysToFetch.add(key);
      }
    }

    if (keysToFetch.isEmpty) return results;

    // Fetch from Firestore in batches of 10 (whereIn limit)
    for (var i = 0; i < keysToFetch.length; i += 10) {
      final batch = keysToFetch.sublist(
        i,
        i + 10 > keysToFetch.length ? keysToFetch.length : i + 10,
      );

      try {
        final snapshot = await firestore
            .collection(_poolCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          final pool = _parsePoolDoc(doc);
          if (pool != null && !pool.isStale) {
            results.add(pool);
            _cache[pool.poolKey] = _CachedPool(pool);
          }
        }
      } catch (e) {
        debugPrint('[CandidatePoolService] Error fetching pools: $e');
      }
    }

    return results;
  }

  CandidatePool? _parsePoolDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;

    final membersRaw = data['members'] as List<dynamic>?;
    if (membersRaw == null) return null;

    final members = <PoolCandidate>[];
    for (final m in membersRaw) {
      if (m is Map<String, dynamic>) {
        try {
          members.add(PoolCandidate.fromMap(m));
        } catch (_) {}
      }
    }

    DateTime? updatedAt;
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    }

    return CandidatePool(
      poolKey: data['poolKey'] as String? ?? doc.id,
      country: data['country'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      ageBucket: data['ageBucket'] as String? ?? '',
      members: members,
      updatedAt: updatedAt,
    );
  }

  /// Clear in-memory cache.
  void clearCache() {
    _cache.clear();
    debugPrint('[CandidatePoolService] Cache cleared');
  }
}

class _CachedPool {
  final CandidatePool pool;
  final DateTime fetchedAt;

  _CachedPool(this.pool) : fetchedAt = DateTime.now();

  bool get isValid =>
      DateTime.now().difference(fetchedAt) < CandidatePoolService._cacheTtl;
}
