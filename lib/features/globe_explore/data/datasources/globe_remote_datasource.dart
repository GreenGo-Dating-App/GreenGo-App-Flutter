import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/globe_user.dart';
import '../models/globe_user_model.dart';
import '../network_pin_assembler.dart';
import '../world_map_snapshot.dart';
import '../../../profile/data/private_profile.dart';

abstract class GlobeRemoteDataSource {
  /// Just the signed-in user's own pin (one doc read, shared with an
  /// in-flight [getGlobeData]) so the map can render before the network.
  Future<GlobeUser> getCurrentUserPin({required String userId});
  Future<GlobeData> getGlobeData({required String userId});
}

/// The network ("world") map's reads.
///
/// With a [WorldMapSnapshotSource] (the app) the network pins come from the
/// server-built hourly snapshot: one doc read per open (owner decision
/// 2026-10-20). The client assembly below is the FALLBACK, used only when
/// the snapshot can not be fetched (and by the tests of the shared rules).
///
/// Client assembly: per open, all bounded and in ONE
/// parallel round trip, then the profiles in parallel `whereIn` batches:
///
///  * own profile (1 doc, shared with [getCurrentUserPin]);
///  * own block list (`profiles/{uid}/blocked_users`, <= 1000);
///  * following: `user_business_following/{uid}/businesses`, newest
///    [kGlobeFollowingCap] by `createdAt` (auto single-field index);
///  * followers: `business_followers/{uid}/followers`, newest
///    [kGlobeFollowersCap] by `createdAt` (auto single-field index);
///  * chats: the inbox query (`conversations` where userId1|userId2 == uid,
///    `lastMessageAt` desc - the existing composite indexes), newest
///    [kGlobeChatsCap];
///  * profiles of the distinct accounts (<= 900), 30 per `whereIn`, reused
///    from a short session cache on a reopen / refresh.
class GlobeRemoteDataSourceImpl implements GlobeRemoteDataSource {

  GlobeRemoteDataSourceImpl({
    required this.firestore,
    this.snapshotSource,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final FirebaseFirestore firestore;

  /// Server snapshot of the network pins; null = always assemble on the
  /// device.
  final WorldMapSnapshotSource? snapshotSource;
  final DateTime Function() _now;

  static const int _whereInChunk = 30;

  /// How long a fetched profile is reused by later opens of the map.
  static const Duration profileTtl = Duration(minutes: 5);

  /// Bound of the session profile cache (oldest evicted).
  static const int profileCacheSize = 1500;

  final Map<String, ({Map<String, dynamic>? data, DateTime at})> _profiles =
      {};
  String? _cacheOwner;
  (String, Future<GlobeUser>)? _currentUserLoad;

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
    // Own pin: exact private location (security P1-4).
    final userData = (await ownRawViewLoaded(userId, userDoc.data()))!;
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
    final source = snapshotSource;
    if (source != null) {
      try {
        final results = await Future.wait<Object>([
          getCurrentUserPin(userId: userId),
          source.load(userId),
        ]);
        return GlobeData(
          currentUser: results[0] as GlobeUser,
          matchedUsers: results[1] as List<GlobeUser>,
          discoveryUsers: const [],
        );
      } catch (_) {
        // Fall through: assemble on the device (own-pin failures rethrow
        // from there as before).
      }
    }
    return _assembleOnDevice(userId);
  }

  /// The pre-snapshot path: reads the relations and profiles and applies
  /// [assembleNetworkPins] here.
  Future<GlobeData> _assembleOnDevice(String userId) async {
    if (_cacheOwner != userId) {
      _profiles.clear();
      _cacheOwner = userId;
    }
    final results = await Future.wait<Object?>([
      getCurrentUserPin(userId: userId),
      _safe(firestore
          .collection('profiles')
          .doc(userId)
          .collection('blocked_users')
          .limit(1000)
          .get()),
      _newestEdges(
          firestore
              .collection('user_business_following')
              .doc(userId)
              .collection('businesses'),
          kGlobeFollowingCap),
      _newestEdges(
          firestore
              .collection('business_followers')
              .doc(userId)
              .collection('followers'),
          kGlobeFollowersCap),
      _recentChats(userId),
    ]);

    final currentUser = results[0]! as GlobeUser;
    final blocked = <String>{
      ...?(results[1] as QuerySnapshot<Map<String, dynamic>>?)
          ?.docs
          .map((d) => d.id),
    };
    final followingDocs =
        results[2]! as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
    final followerDocs =
        results[3]! as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
    final chats = results[4]! as List<String>;

    final following = <GlobeFollowEdge>[
      for (final d in followingDocs)
        (id: d.id, isStore: d.data()['isStore'] == true),
    ];
    final followers = [for (final d in followerDocs) d.id];

    final ids = <String>{
      ...chats,
      ...following.map((e) => e.id),
      ...followers,
    }..removeAll({userId, ...blocked});
    final profiles = await _profilesFor(ids.toList());

    return GlobeData(
      currentUser: currentUser,
      matchedUsers: assembleNetworkPins(
        userId: userId,
        following: following,
        followers: followers,
        chats: chats,
        profiles: profiles,
        blocked: blocked,
      ),
      discoveryUsers: const [],
    );
  }

  static Future<T?> _safe<T>(Future<T> f) async {
    try {
      return await f;
    } catch (_) {
      return null;
    }
  }

  /// Newest [cap] edge docs of a follow subcollection; an unreadable list
  /// (offline / rules) is empty, never a failed map.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _newestEdges(
      CollectionReference<Map<String, dynamic>> col, int cap) async {
    try {
      return (await col.orderBy('createdAt', descending: true).limit(cap).get())
          .docs;
    } catch (_) {
      final snap = await _safe(col.limit(cap).get());
      return snap?.docs ?? const [];
    }
  }

  /// Partners of the user's most recent 1:1 chats (with a message), newest
  /// first - the inbox's own query and indexes.
  Future<List<String>> _recentChats(String userId) async {
    final base = firestore.collection('conversations').where(Filter.or(
          Filter('userId1', isEqualTo: userId),
          Filter('userId2', isEqualTo: userId),
        ));
    final snap = await _safe(base
            .orderBy('lastMessageAt', descending: true)
            .limit(kGlobeChatsCap)
            .get()) ??
        await _safe(base.limit(kGlobeChatsCap).get());
    final out = <String>[];
    final seen = <String>{};
    for (final d in snap?.docs ??
        const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      final other = chatPartnerOf(d.data(), userId);
      if (other != null && seen.add(other)) out.add(other);
    }
    return out;
  }

  /// Raw public profiles of [ids]: cached ones (younger than [profileTtl])
  /// are reused, the rest read in parallel `whereIn` batches of 30. A
  /// missing doc is remembered as null (deleted account); a failed batch is
  /// simply retried on the next open.
  Future<Map<String, Map<String, dynamic>>> _profilesFor(
      List<String> ids) async {
    final now = _now();
    final toFetch = [
      for (final id in ids)
        if (_profiles[id] == null ||
            now.difference(_profiles[id]!.at) >= profileTtl)
          id,
    ];
    if (toFetch.isNotEmpty) {
      final chunks = <List<String>>[
        for (var i = 0; i < toFetch.length; i += _whereInChunk)
          toFetch.sublist(i, min(i + _whereInChunk, toFetch.length)),
      ];
      await Future.wait(chunks.map((c) async {
        final snap = await _safe(firestore
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: c)
            .get());
        if (snap == null) return;
        final byId = {for (final d in snap.docs) d.id: d.data()};
        for (final id in c) {
          _profiles.remove(id);
          _profiles[id] = (data: byId[id], at: now);
        }
      }));
      while (_profiles.length > profileCacheSize) {
        _profiles.remove(_profiles.keys.first);
      }
    }
    return {
      for (final id in ids)
        if (_profiles[id]?.data != null) id: _profiles[id]!.data!,
    };
  }
}
