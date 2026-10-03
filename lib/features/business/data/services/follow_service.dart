import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/blocked_users_service.dart';
import 'follow_count_overlay.dart';

export 'follow_count_overlay.dart' show FollowCountOverlay, FollowCounter;

/// Thrown when a follow is refused because one of the two users blocked the
/// other.
class FollowBlockedException implements Exception {
  const FollowBlockedException();
}

/// Follower / following counts read from a profile.
class FollowCounts {
  const FollowCounts({this.followers = 0, this.following = 0});

  /// Parses the SERVER-maintained counters (`followersCount` /
  /// `followingCount`). The legacy client-writable `followerCount` is
  /// deliberately ignored: any signed-in user could change it, so it is not
  /// trustworthy.
  factory FollowCounts.fromProfileData(Map<String, dynamic>? data) {
    int read(String k) {
      final v = (data?[k] as num?)?.toInt() ?? 0;
      return v < 0 ? 0 : v;
    }

    return FollowCounts(
      followers: read('followersCount'),
      following: read('followingCount'),
    );
  }

  static const FollowCounts zero = FollowCounts();

  final int followers;
  final int following;
}

/// One page of a followers / following list (newest first).
class FollowPage {
  const FollowPage({required this.userIds, required this.cursor, required this.hasMore});

  final List<String> userIds;

  /// Pass back as `after:` to load the next page.
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

/// Follow service — ONE follow graph for every account (business or not).
///
/// Designed to scale to millions:
///
///  * Membership is stored TWICE (denormalized) so every read is a single,
///    index-free lookup or an ordered single-collection page:
///      - `business_followers/{followeeId}/followers/{followerId}` — who follows
///        an account (canonical edge; the name predates user follows)
///      - `user_business_following/{followerId}/businesses/{followeeId}` — who an
///        account follows (mirror)
///  * Counts are maintained SERVER-SIDE by the `onUserFollowCreated` /
///    `onUserFollowDeleted` triggers into `profiles/{id}.followersCount` and
///    `.followingCount`, which no client can write. The client only writes its
///    own edge docs.
///  * Because the triggers can lag (cold start), [counts] overlays this
///    device's committed-but-not-yet-counted changes ([FollowCountOverlay]) on
///    BOTH sides - the followee's followers and the follower's own following -
///    until the server value catches up.
///
/// TODO(follow-fanout): when a business publishes a new event, a Cloud Function
/// fans out a notification to `business_followers/{businessId}/followers/*`
/// (batched, paginated) — keep it server-side, never iterate followers here.
class FollowService {
  FollowService({
    FirebaseFirestore? firestore,
    BlockedUsersService? blockedUsersService,
    FollowCountOverlay? overlay,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _blocked = blockedUsersService,
        _overlay = overlay ?? FollowCountOverlay.shared;

  final FirebaseFirestore _firestore;
  final BlockedUsersService? _blocked;
  final FollowCountOverlay _overlay;

  /// Page size for the followers / following lists.
  static const int pageSize = 30;

  CollectionReference<Map<String, dynamic>> _followersCol(String followeeId) =>
      _firestore
          .collection('business_followers')
          .doc(followeeId)
          .collection('followers');

  CollectionReference<Map<String, dynamic>> _followingCol(String followerId) =>
      _firestore
          .collection('user_business_following')
          .doc(followerId)
          .collection('businesses');

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _firestore.collection('profiles').doc(uid);

  // ── state ──────────────────────────────────────────────────────────────

  /// Live follow-state of [followerId] → [followeeId]. Single-doc stream.
  Stream<bool> isFollowingUser({
    required String followeeId,
    required String followerId,
  }) =>
      _followersCol(followeeId).doc(followerId).snapshots().map((d) => d.exists);

  /// Live follower/following counts of [uid]: the server-maintained
  /// counters plus any change this device made that the server has not
  /// counted yet (so a follow / unfollow shows on both profiles immediately).
  Stream<FollowCounts> counts(String uid) {
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;
    StreamSubscription<String>? overlaySub;
    FollowCounts? server;
    late final StreamController<FollowCounts> out;

    void publish() {
      final s = server;
      if (s == null || out.isClosed) return;
      out.add(FollowCounts(
        followers: _overlay.apply(uid, FollowCounter.followers, s.followers),
        following: _overlay.apply(uid, FollowCounter.following, s.following),
      ));
    }

    out = StreamController<FollowCounts>(
      onListen: () {
        docSub = _profile(uid).snapshots().listen(
          (d) {
            final s = FollowCounts.fromProfileData(d.data());
            _overlay
              ..observeServer(uid, FollowCounter.followers, s.followers)
              ..observeServer(uid, FollowCounter.following, s.following);
            server = s;
            publish();
          },
          onError: out.addError,
        );
        overlaySub =
            _overlay.changes.where((u) => u == uid).listen((_) => publish());
      },
      onCancel: () async {
        await docSub?.cancel();
        await overlaySub?.cancel();
      },
    );
    return out.stream;
  }

  /// Current server counters of [uid] (null when unreadable).
  Future<FollowCounts?> _readServerCounts(String uid) async {
    try {
      final d = await _profile(uid).get();
      return FollowCounts.fromProfileData(d.data());
    } catch (_) {
      return null;
    }
  }

  /// Record a committed follow (+1) / unfollow (-1) on both sides.
  void _recordChange({
    required String followeeId,
    required String followerId,
    required int delta,
    required List<FollowCounts?> before,
  }) {
    _overlay
      ..record(followeeId, FollowCounter.followers, delta,
          serverBefore: before[0]?.followers)
      ..record(followerId, FollowCounter.following, delta,
          serverBefore: before[1]?.following);
  }

  /// True when [a] and [b] blocked each other in either direction.
  Future<bool> isBlockedPair(String a, String b) async {
    final blocked = _blocked;
    if (blocked == null) return false;
    final ids = await blocked.getBlockedUserIds(a);
    return ids.contains(b);
  }

  // ── mutations ──────────────────────────────────────────────────────────

  /// Follow [followeeId] as [followerId]. Idempotent (already following → no
  /// write); a self-follow is a no-op. Throws [FollowBlockedException] when
  /// either user blocked the other. Counts are NOT written here — the server
  /// trigger maintains them.
  Future<void> followUser({
    required String followeeId,
    required String followerId,
  }) async {
    if (followeeId.isEmpty || followerId.isEmpty) return;
    if (followeeId == followerId) return;
    // Counter baselines are read in parallel with the block check, BEFORE the
    // write, so they can never already include this follow.
    final beforeF = Future.wait([
      _readServerCounts(followeeId),
      _readServerCounts(followerId),
    ]);
    if (await isBlockedPair(followerId, followeeId)) {
      throw const FollowBlockedException();
    }
    final before = await beforeF;
    final edge = _followersCol(followeeId).doc(followerId);
    final mirror = _followingCol(followerId).doc(followeeId);
    var wrote = false;
    await _firestore.runTransaction((txn) async {
      wrote = false; // the handler may re-run
      final existing = await txn.get(edge);
      if (existing.exists) return;
      // A stray mirror (edge removed server-side) must not be re-set: the
      // rules allow create/delete only, so a set() over it would be refused.
      final staleMirror = await txn.get(mirror);
      final now = FieldValue.serverTimestamp();
      txn.set(edge, {'createdAt': now});
      if (!staleMirror.exists) txn.set(mirror, {'createdAt': now});
      wrote = true;
    });
    if (wrote) {
      _recordChange(
          followeeId: followeeId, followerId: followerId, delta: 1, before: before);
    }
  }

  /// Unfollow [followeeId] as [followerId]. Idempotent.
  Future<void> unfollowUser({
    required String followeeId,
    required String followerId,
  }) async {
    if (followeeId.isEmpty || followerId.isEmpty) return;
    final before = await Future.wait([
      _readServerCounts(followeeId),
      _readServerCounts(followerId),
    ]);
    final edge = _followersCol(followeeId).doc(followerId);
    final mirror = _followingCol(followerId).doc(followeeId);
    var deleted = false;
    await _firestore.runTransaction((txn) async {
      deleted = false; // the handler may re-run
      final existing = await txn.get(edge);
      if (!existing.exists) return;
      // Deleting the canonical edge is what fires onUserFollowDeleted, which
      // decrements BOTH the followee's followersCount and the follower's
      // followingCount.
      txn.delete(edge);
      txn.delete(mirror);
      deleted = true;
    });
    if (deleted) {
      _recordChange(
          followeeId: followeeId, followerId: followerId, delta: -1, before: before);
    }
  }

  // ── lists ──────────────────────────────────────────────────────────────

  /// Page of the users who follow [uid], newest first.
  Future<FollowPage> followersPage(
    String uid, {
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = pageSize,
  }) =>
      _page(_followersCol(uid), after: after, limit: limit);

  /// Page of the users [uid] follows, newest first.
  Future<FollowPage> followingPage(
    String uid, {
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = pageSize,
  }) =>
      _page(_followingCol(uid), after: after, limit: limit);

  Future<FollowPage> _page(
    CollectionReference<Map<String, dynamic>> col, {
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    // Single-field (auto) index on createdAt — no composite index needed.
    Query<Map<String, dynamic>> q =
        col.orderBy('createdAt', descending: true).limit(limit);
    if (after != null) q = q.startAfterDocument(after);
    final snap = await q.get();
    return FollowPage(
      userIds: [for (final d in snap.docs) d.id],
      cursor: snap.docs.isEmpty ? after : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  // ── business-follow API (kept for existing callers) ───────────────────

  /// Live follow-state for [uid] against [businessId].
  Stream<bool> isFollowing({
    required String businessId,
    required String uid,
  }) =>
      isFollowingUser(followeeId: businessId, followerId: uid);

  /// Live follower count for [businessId] (server-maintained, 0 when absent).
  Stream<int> followerCount(String businessId) =>
      counts(businessId).map((c) => c.followers);

  /// One-off follower count (for non-streaming callers).
  Future<int> getFollowerCount(String businessId) async {
    final doc = await _profile(businessId).get();
    return FollowCounts.fromProfileData(doc.data()).followers;
  }

  Future<void> follow({required String businessId, required String uid}) =>
      followUser(followeeId: businessId, followerId: uid);

  Future<void> unfollow({required String businessId, required String uid}) =>
      unfollowUser(followeeId: businessId, followerId: uid);

  /// Toggle follow state and return the resulting state (`true` = following).
  Future<bool> toggle({
    required String businessId,
    required String uid,
    required bool currentlyFollowing,
  }) async {
    if (currentlyFollowing) {
      await unfollow(businessId: businessId, uid: uid);
      return false;
    }
    await follow(businessId: businessId, uid: uid);
    return true;
  }
}
