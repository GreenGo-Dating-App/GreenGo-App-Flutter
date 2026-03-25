import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/globe_user.dart';
import '../models/globe_user_model.dart';
import '../country_centroids.dart';

abstract class GlobeRemoteDataSource {
  Future<GlobeData> getGlobeData({required String userId});
  Stream<List<GlobeUser>> watchMatchUpdates({required String userId});
  Stream<Map<String, bool>> watchOnlineStatus({required List<String> userIds});
}

class GlobeRemoteDataSourceImpl implements GlobeRemoteDataSource {
  final FirebaseFirestore firestore;

  GlobeRemoteDataSourceImpl({required this.firestore});

  @override
  Future<GlobeData> getGlobeData({required String userId}) async {
    final rng = Random();

    // Fetch current user profile
    final userDoc =
        await firestore.collection('profiles').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('Current user profile not found');
    }
    final userData = userDoc.data()!;
    userData['userId'] = userId;

    final currentUser = GlobeUserModel.fromFirestore(
      data: userData,
      odcId: userId,
      pinType: GlobePinType.currentUser,
      random: rng,
    );

    // Fetch blocked users list
    final blockedSnapshot = await firestore
        .collection('profiles')
        .doc(userId)
        .collection('blocked_users')
        .get();
    final blockedIds =
        blockedSnapshot.docs.map((d) => d.id).toSet();

    // QUERY 1: Matched users (gold pins)
    final matchedUsers = await _fetchMatchedUsers(
      userId: userId,
      blockedIds: blockedIds,
      rng: rng,
    );

    return GlobeData(
      currentUser: currentUser,
      matchedUsers: matchedUsers,
      discoveryUsers: const [],
    );
  }

  Future<List<GlobeUser>> _fetchMatchedUsers({
    required String userId,
    required Set<String> blockedIds,
    required Random rng,
  }) async {
    // Firestore doesn't support OR queries, so use two queries
    final query1 = await firestore
        .collection('matches')
        .where('userId1', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();
    final query2 = await firestore
        .collection('matches')
        .where('userId2', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final allMatchDocs = [...query1.docs, ...query2.docs];
    final matchedUsers = <GlobeUser>[];

    for (final matchDoc in allMatchDocs) {
      final matchData = matchDoc.data();
      final matchId = matchDoc.id;
      final otherUserId = matchData['userId1'] == userId
          ? matchData['userId2'] as String
          : matchData['userId1'] as String;

      if (blockedIds.contains(otherUserId)) continue;

      try {
        final profileDoc =
            await firestore.collection('profiles').doc(otherUserId).get();
        if (!profileDoc.exists) continue;
        final profileData = profileDoc.data()!;

        // Skip inactive accounts
        if (profileData['accountStatus'] != 'active') continue;

        // Skip incognito users
        final isIncognito = profileData['isIncognito'] as bool? ?? false;
        if (isIncognito) {
          final incognitoExpiryTs =
              profileData['incognitoExpiry'] as Timestamp?;
          if (incognitoExpiryTs == null ||
              incognitoExpiryTs.toDate().isAfter(DateTime.now())) {
            continue;
          }
        }

        // Skip ghost mode users
        if (profileData['isGhostMode'] as bool? ?? false) continue;

        // Skip users with unknown/missing location
        final loc = profileData['location'] as Map<String, dynamic>?;
        final hasLocation = loc != null &&
            loc['latitude'] != null &&
            loc['longitude'] != null &&
            loc['country'] != null &&
            (loc['country'] as String?) != 'Unknown';
        if (!hasLocation) continue;

        matchedUsers.add(GlobeUserModel.fromFirestore(
          data: profileData,
          odcId: otherUserId,
          pinType: GlobePinType.matched,
          matchId: matchId,
          random: rng,
        ));
      } catch (_) {
        // Skip profiles that can't be loaded
      }
    }

    return matchedUsers;
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

    final stream1 = firestore
        .collection('matches')
        .where('userId1', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots();
    final stream2 = firestore
        .collection('matches')
        .where('userId2', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots();

    // Keep latest snapshot from each query and combine
    QuerySnapshot? latest1;
    QuerySnapshot? latest2;

    return StreamGroup.merge([
      stream1.map((s) { latest1 = s; return true; }),
      stream2.map((s) { latest2 = s; return true; }),
    ]).asyncMap((_) async {
      final allDocs = <QueryDocumentSnapshot>[
        ...?latest1?.docs,
        ...?latest2?.docs,
      ];
      // Deduplicate by matchId
      final seen = <String>{};
      final matchedUsers = <GlobeUser>[];
      for (final matchDoc in allDocs) {
        if (!seen.add(matchDoc.id)) continue;
        final matchData = matchDoc.data() as Map<String, dynamic>;
        final otherUserId = matchData['userId1'] == userId
            ? matchData['userId2'] as String
            : matchData['userId1'] as String;

        try {
          final profileDoc =
              await firestore.collection('profiles').doc(otherUserId).get();
          if (!profileDoc.exists) continue;
          final profileData = profileDoc.data()!;
          if (profileData['accountStatus'] != 'active') continue;

          // Skip users with unknown/missing location
          final loc = profileData['location'] as Map<String, dynamic>?;
          if (loc == null ||
              loc['latitude'] == null ||
              loc['longitude'] == null ||
              (loc['country'] as String?) == null ||
              (loc['country'] as String?) == 'Unknown') continue;

          matchedUsers.add(GlobeUserModel.fromFirestore(
            data: profileData,
            odcId: otherUserId,
            pinType: GlobePinType.matched,
            matchId: matchDoc.id,
            random: rng,
          ));
        } catch (_) {}
      }
      return matchedUsers;
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
