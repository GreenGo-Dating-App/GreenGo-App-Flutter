import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/globe_user.dart';
import '../models/globe_user_model.dart';

abstract class GlobeRemoteDataSource {
  /// Just the signed-in user's own pin (one doc read, shared with an
  /// in-flight [getGlobeData]) so the map can render before the matches.
  Future<GlobeUser> getCurrentUserPin({required String userId});
  Future<GlobeData> getGlobeData({required String userId});
  Stream<List<GlobeUser>> watchMatchUpdates({required String userId});
  Stream<Map<String, bool>> watchOnlineStatus({required List<String> userIds});
}

class GlobeRemoteDataSourceImpl implements GlobeRemoteDataSource {

  GlobeRemoteDataSourceImpl({required this.firestore});
  final FirebaseFirestore firestore;

  /// Matched users read per side (newest first). Bounded: the globe shows
  /// pins, and an unbounded read pulled every match + profile on each open.
  static const int _matchLimit = 200;
  static const int _whereInChunk = 30;

  // Session memo, reused by [watchMatchUpdates] so a match snapshot only
  // reads the profiles of NEW matches (it used to re-read every profile,
  // one by one, on the first and every later snapshot).
  String? _memoUserId;
  final Map<String, GlobeUser> _matchedPins = {}; // otherUserId -> pin
  final Set<String> _rejectedIds = {}; // filtered out (inactive, hidden...)
  Set<String> _blockedIds = {};
  (String, Future<GlobeUser>)? _currentUserLoad;

  void _resetMemo(String userId) {
    _memoUserId = userId;
    _matchedPins.clear();
    _rejectedIds.clear();
    _blockedIds = {};
  }

  @override
  Future<GlobeUser> getCurrentUserPin({required String userId}) {
    final inflight = _currentUserLoad;
    if (inflight != null && inflight.$1 == userId) return inflight.$2;
    final future = _loadCurrentUser(userId);
    _currentUserLoad = (userId, future);
    future
        .whenComplete(() {
          if (identical(_currentUserLoad?.$2, future)) _currentUserLoad = null;
        })
        .ignore();
    return future;
  }

  Future<GlobeUser> _loadCurrentUser(String userId) async {
    final userDoc = await firestore.collection('profiles').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('Current user profile not found');
    }
    final userData = userDoc.data()!;
    userData['userId'] = userId;
    return GlobeUserModel.fromFirestore(
      data: userData,
      odcId: userId,
      pinType: GlobePinType.currentUser,
      random: Random(),
    );
  }

  @override
  Future<GlobeData> getGlobeData({required String userId}) async {
    final rng = Random();
    _resetMemo(userId);

    // Own profile, block list and both match sides in ONE parallel round
    // trip (they used to run one after another).
    final results = await Future.wait<Object>([
      getCurrentUserPin(userId: userId),
      firestore
          .collection('profiles')
          .doc(userId)
          .collection('blocked_users')
          .limit(1000)
          .get(),
      _activeMatches('userId1', userId),
      _activeMatches('userId2', userId),
    ]);

    final currentUser = results[0] as GlobeUser;
    final blockedSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    _blockedIds = blockedSnapshot.docs.map((d) => d.id).toSet();

    // QUERY 1: Matched users (gold pins)
    final matchedUsers = await _matchedPinsFor(
      userId: userId,
      matchDocs: [
        ...(results[2] as QuerySnapshot<Map<String, dynamic>>).docs,
        ...(results[3] as QuerySnapshot<Map<String, dynamic>>).docs,
      ],
      rng: rng,
    );

    return GlobeData(
      currentUser: currentUser,
      matchedUsers: matchedUsers,
      discoveryUsers: const [],
    );
  }

  Query<Map<String, dynamic>> _activeMatchesQuery(String field, String userId) =>
      firestore
          .collection('matches')
          .where(field, isEqualTo: userId)
          .where('isActive', isEqualTo: true);

  /// Index: matches (userId1|userId2, isActive, matchedAt desc). Falls back to
  /// the unordered (equality-only) read if the ordered one is rejected.
  Future<QuerySnapshot<Map<String, dynamic>>> _activeMatches(
      String field, String userId) async {
    try {
      return await _activeMatchesQuery(field, userId)
          .orderBy('matchedAt', descending: true)
          .limit(_matchLimit)
          .get();
    } catch (_) {
      return _activeMatchesQuery(field, userId).limit(_matchLimit).get();
    }
  }

  /// Pins for [matchDocs] in their order: memoised pins are reused; the
  /// profiles of the rest are read in parallel `whereIn` batches of 30.
  Future<List<GlobeUser>> _matchedPinsFor({
    required String userId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> matchDocs,
    required Random rng,
  }) async {
    final seenMatch = <String>{};
    final pairs = <(String matchId, String otherId)>[];
    for (final doc in matchDocs) {
      if (!seenMatch.add(doc.id)) continue;
      final data = doc.data();
      final other = data['userId1'] == userId
          ? data['userId2'] as String?
          : data['userId1'] as String?;
      if (other == null || other.isEmpty) continue;
      if (_blockedIds.contains(other)) continue;
      pairs.add((doc.id, other));
    }

    final toFetch = {
      for (final p in pairs)
        if (!_matchedPins.containsKey(p.$2) && !_rejectedIds.contains(p.$2))
          p.$2,
    }.toList();
    if (toFetch.isNotEmpty) {
      final chunks = <List<String>>[
        for (var i = 0; i < toFetch.length; i += _whereInChunk)
          toFetch.sublist(i, min(i + _whereInChunk, toFetch.length)),
      ];
      final snaps = await Future.wait(chunks.map((c) async {
        try {
          return await firestore
              .collection('profiles')
              .where(FieldPath.documentId, whereIn: c)
              .get();
        } catch (_) {
          return null; // Skip profiles that can't be loaded
        }
      }));
      final byId = <String, Map<String, dynamic>>{
        for (final snap in snaps)
          if (snap != null)
            for (final d in snap.docs) d.id: d.data(),
      };
      final matchIdFor = {for (final p in pairs) p.$2: p.$1};
      for (final id in toFetch) {
        final data = byId[id];
        if (data == null) continue; // missing / failed: retried next time
        final pin = _matchedPinFrom(data, id, matchIdFor[id]!, rng);
        if (pin == null) {
          _rejectedIds.add(id);
        } else {
          _matchedPins[id] = pin;
        }
      }
    }

    return [
      for (final p in pairs)
        if (_matchedPins[p.$2] != null) _matchedPins[p.$2]!,
    ];
  }

  /// A matched user's pin, or null when they must not be shown (inactive,
  /// incognito, ghost mode, unknown location).
  GlobeUser? _matchedPinFrom(
    Map<String, dynamic> profileData,
    String otherUserId,
    String matchId,
    Random rng,
  ) {
    try {
      // Skip inactive accounts
      if (profileData['accountStatus'] != 'active') return null;

      // Skip incognito users
      final isIncognito = profileData['isIncognito'] as bool? ?? false;
      if (isIncognito) {
        final incognitoExpiryTs = profileData['incognitoExpiry'] as Timestamp?;
        if (incognitoExpiryTs == null ||
            incognitoExpiryTs.toDate().isAfter(DateTime.now())) {
          return null;
        }
      }

      // Skip ghost mode users
      if (profileData['isGhostMode'] as bool? ?? false) return null;

      // Skip users with unknown/missing location
      final loc = profileData['location'] as Map<String, dynamic>?;
      final hasLocation = loc != null &&
          loc['latitude'] != null &&
          loc['longitude'] != null &&
          loc['country'] != null &&
          (loc['country'] as String?) != 'Unknown';
      if (!hasLocation) return null;

      return GlobeUserModel.fromFirestore(
        data: profileData,
        odcId: otherUserId,
        pinType: GlobePinType.matched,
        matchId: matchId,
        random: rng,
      );
    } catch (_) {
      return null; // Skip profiles that can't be parsed
    }
  }

  Future<List<GlobeUser>> _fetchDiscoveryUsers({
    required String userId,
    required Set<String> blockedIds,
    required Set<String> matchedUserIds,
    required Random rng,
  }) async {
    final now = DateTime.now();

    // Fetch a pool of active profiles
    final snapshot = await firestore
        .collection('profiles')
        .where('accountStatus', isEqualTo: 'active')
        .limit(200)
        .get();

    final discoveryPool = <GlobeUser>[];

    for (final doc in snapshot.docs) {
      if (doc.id == userId) continue;
      if (blockedIds.contains(doc.id)) continue;
      if (matchedUserIds.contains(doc.id)) continue;

      final data = doc.data();

      // Skip incognito users
      final isIncognito = data['isIncognito'] as bool? ?? false;
      if (isIncognito) {
        final incognitoExpiryTs = data['incognitoExpiry'] as Timestamp?;
        if (incognitoExpiryTs == null ||
            incognitoExpiryTs.toDate().isAfter(now)) {
          continue;
        }
      }

      // Skip ghost mode users
      if (data['isGhostMode'] as bool? ?? false) continue;

      // Check globe discoverability
      final discoverability =
          data['globeDiscoverability'] as String? ?? 'country';
      if (discoverability == 'hidden') continue;

      discoveryPool.add(GlobeUserModel.fromFirestore(
        data: data,
        odcId: doc.id,
        pinType: GlobePinType.discovery,
        random: rng,
      ));
    }

    // Shuffle and take max 50
    discoveryPool.shuffle(rng);
    return discoveryPool.take(50).toList();
  }

  @override
  Stream<List<GlobeUser>> watchMatchUpdates({required String userId}) {
    final rng = Random();
    if (_memoUserId != userId) _resetMemo(userId);

    Stream<QuerySnapshot<Map<String, dynamic>>> side(String field) =>
        _activeMatchesQuery(field, userId)
            .orderBy('matchedAt', descending: true)
            .limit(_matchLimit)
            .snapshots();

    // Keep latest snapshot from each query and combine
    QuerySnapshot<Map<String, dynamic>>? latest1;
    QuerySnapshot<Map<String, dynamic>>? latest2;

    return StreamGroup.merge([
      side('userId1').map((s) { latest1 = s; return true; }),
      side('userId2').map((s) { latest2 = s; return true; }),
    ])
        // Until BOTH sides reported, a combined list would drop half the pins.
        .where((_) => latest1 != null && latest2 != null)
        .asyncMap((_) {
      // Profiles already resolved by getGlobeData / earlier snapshots are
      // reused (same pin, no re-read); only new matches hit Firestore.
      return _matchedPinsFor(
        userId: userId,
        matchDocs: [...?latest1?.docs, ...?latest2?.docs],
        rng: rng,
      );
    });
  }

  @override
  Stream<Map<String, bool>> watchOnlineStatus({
    required List<String> userIds,
  }) {
    if (userIds.isEmpty) return Stream.value({});

    // Batch userIds into groups of 30 (Firestore whereIn limit)
    final batches = <List<String>>[];
    for (var i = 0; i < userIds.length; i += 30) {
      batches.add(
        userIds.sublist(i, i + 30 > userIds.length ? userIds.length : i + 30),
      );
    }

    final streams = batches.map((batch) {
      return firestore
          .collection('profiles')
          .where(FieldPath.documentId, whereIn: batch)
          .snapshots()
          .map((snapshot) {
        final statusMap = <String, bool>{};
        for (final doc in snapshot.docs) {
          statusMap[doc.id] = doc.data()['isOnline'] as bool? ?? false;
        }
        return statusMap;
      });
    });

    // Merge all batch streams
    return StreamGroup.merge(streams);
  }
}

/// Merges multiple streams into a single stream.
class StreamGroup {
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>();
    final subscriptions = <StreamSubscription<T>>[];

    for (final stream in streams) {
      subscriptions.add(stream.listen(
        controller.add,
        onError: controller.addError,
      ));
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }
}
