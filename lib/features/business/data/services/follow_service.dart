import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/blocked_users_service.dart';
import '../../../../core/utils/follow_name_normalizer.dart';
import 'follow_count_overlay.dart';

export 'follow_count_overlay.dart' show FollowCountOverlay, FollowCounter;

/// Thrown when a follow is refused because one of the two users blocked the
/// other.
class FollowBlockedException implements Exception {
  const FollowBlockedException();
}

/// Follower / following / stores counts of an account, from the owner-only
/// `follow_counts/{uid}` (only the account itself can read it; the stores
/// count is private, owner rule 2026-10-17). Other viewers read the public
/// [PublicFollowCounts] instead.
class FollowCounts {
  const FollowCounts({this.followers = 0, this.following = 0, this.stores = 0});

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
      stores: read('storesCount'),
    );
  }

  /// The private counters plus any LEGACY value still on the own public
  /// profile (until functions scripts/move-follow-counts-private.ts moved
  /// it: the private doc then only holds the changes since the deploy, and
  /// the move adds the public value to it and deletes it atomically).
  factory FollowCounts.merged(
      Map<String, dynamic>? private, Map<String, dynamic>? legacyPublic) {
    final p = FollowCounts.fromProfileData(private);
    final l = FollowCounts.fromProfileData(legacyPublic);
    return FollowCounts(
      followers: p.followers + l.followers,
      following: p.following + l.following,
      stores: p.stores,
    );
  }

  static const FollowCounts zero = FollowCounts();

  final int followers;
  final int following;

  /// Business accounts this account follows (own-profile "Stores").
  final int stores;
}

/// PUBLIC follower / following counts of any account (owner decisions
/// 2026-10-19), from `follower_counts_public/{uid}`. Never the stores count.
class PublicFollowCounts {
  const PublicFollowCounts({this.followers = 0, this.following = 0});

  factory PublicFollowCounts.fromData(Map<String, dynamic>? data) {
    int read(String k) {
      final v = (data?[k] as num?)?.toInt() ?? 0;
      return v < 0 ? 0 : v;
    }

    return PublicFollowCounts(
      followers: read('followersCount'),
      following: read('followingCount'),
    );
  }

  final int followers;
  final int following;

  PublicFollowCounts adjusted({int followers = 0, int following = 0}) {
    final f = this.followers + followers;
    final g = this.following + following;
    return PublicFollowCounts(followers: f < 0 ? 0 : f, following: g < 0 ? 0 : g);
  }
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
///    `onUserFollowDeleted` triggers into the OWNER-ONLY
///    `follow_counts/{id}` (`followersCount`, `followingCount`,
///    `storesCount`), which no client can write. The client only writes its
///    own edge docs.
///  * PUBLIC lists (owner decision 2026-10-19, replacing the private-follows
///    rule of 2026-10-17): any signed-in user may page / name-search the
///    followers and the following of ANY account (rules: get + list for
///    signed-in users; edges and their server fields stay un-forgeable).
///    Counts: [counts] (owner-only `follow_counts`, incl. stores) is only
///    called for the signed-in uid; everyone else reads
///    [publicFollowCounts] (`follower_counts_public`, followers + following,
///    never stores).
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

  /// Owner-only counters doc (functions social/followCounters.ts).
  static const String countsCollection = 'follow_counts';

  DocumentReference<Map<String, dynamic>> _countsDoc(String uid) =>
      _firestore.collection(countsCollection).doc(uid);

  /// PUBLIC follow counts (owner decisions 2026-10-19): the NUMBER of
  /// followers and of followed accounts of every user and business is public
  /// (the stores count stays private). `{followersCount, followingCount,
  /// updatedAt}` only, written by the same server triggers as
  /// [countsCollection]; any signed-in user may GET one doc (never list).
  static const String publicCountsCollection = 'follower_counts_public';

  /// How long a fetched public count is reused (profile pages are reopened
  /// often; one `get` per profile per [publicCountTtl], not a listener).
  static const Duration publicCountTtl = Duration(minutes: 5);

  /// Bound of the in-memory public-count cache (oldest entries evicted).
  static const int publicCountCacheSize = 300;

  final Map<String, ({PublicFollowCounts counts, DateTime at})> _publicCounts =
      {};
  final Map<String, Future<PublicFollowCounts?>> _publicInFlight = {};

  /// Public follower / following counts of [uid] (any account): ONE `get`
  /// of `follower_counts_public/{uid}`, cached for [publicCountTtl] and
  /// de-duplicated while in flight. A missing doc / field is 0; null when it
  /// could not be read (offline / signed out). [refresh] skips the cache.
  Future<PublicFollowCounts?> publicFollowCounts(String uid,
      {bool refresh = false}) {
    if (uid.isEmpty) return Future.value(const PublicFollowCounts());
    final hit = _publicCounts[uid];
    if (!refresh &&
        hit != null &&
        DateTime.now().difference(hit.at) < publicCountTtl) {
      return Future.value(hit.counts);
    }
    final pending = _publicInFlight[uid];
    if (pending != null) return pending;
    final f = _fetchPublicCounts(uid);
    _publicInFlight[uid] = f;
    // Block body: never return the stored future from its own callback.
    f.whenComplete(() {
      _publicInFlight.remove(uid);
    });
    return f;
  }

  /// Public follower count of [uid] ([publicFollowCounts].followers).
  Future<int?> publicFollowerCount(String uid, {bool refresh = false}) async =>
      (await publicFollowCounts(uid, refresh: refresh))?.followers;

  Future<PublicFollowCounts?> _fetchPublicCounts(String uid) async {
    try {
      final d =
          await _firestore.collection(publicCountsCollection).doc(uid).get();
      final counts = PublicFollowCounts.fromData(d.data());
      _cachePublicCounts(uid, counts);
      return counts;
    } catch (_) {
      return null;
    }
  }

  void _cachePublicCounts(String uid, PublicFollowCounts counts) {
    _publicCounts.remove(uid); // re-insert = most recent
    _publicCounts[uid] = (counts: counts, at: DateTime.now());
    while (_publicCounts.length > publicCountCacheSize) {
      _publicCounts.remove(_publicCounts.keys.first);
    }
  }

  /// This device's own committed follow (+1) / unfollow (-1): move the
  /// cached public counts (the followee's followers, the follower's
  /// following) so a reopened profile reflects it before the server trigger
  /// has counted it.
  void _adjustCachedPublicCounts(
      {required String followeeId, required String followerId, required int delta}) {
    final a = _publicCounts[followeeId];
    if (a != null) {
      _publicCounts[followeeId] =
          (counts: a.counts.adjusted(followers: delta), at: a.at);
    }
    final b = _publicCounts[followerId];
    if (b != null) {
      _publicCounts[followerId] =
          (counts: b.counts.adjusted(following: delta), at: b.at);
    }
  }

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
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? privSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? pubSub;
    StreamSubscription<String>? overlaySub;
    Map<String, dynamic>? priv;
    Map<String, dynamic>? pub;
    var privSeen = false;
    var pubSeen = false;
    late final StreamController<FollowCounts> out;

    void publish() {
      if (!privSeen || !pubSeen || out.isClosed) return;
      final s = FollowCounts.merged(priv, pub);
      out.add(FollowCounts(
        followers: _overlay.apply(uid, FollowCounter.followers, s.followers),
        following: _overlay.apply(uid, FollowCounter.following, s.following),
        stores: s.stores,
      ));
    }

    void serverChanged() {
      if (!privSeen || !pubSeen) return;
      final s = FollowCounts.merged(priv, pub);
      _overlay
        ..observeServer(uid, FollowCounter.followers, s.followers)
        ..observeServer(uid, FollowCounter.following, s.following);
      publish();
    }

    out = StreamController<FollowCounts>(
      onListen: () {
        privSub = _countsDoc(uid).snapshots().listen(
          (d) {
            priv = d.data();
            privSeen = true;
            serverChanged();
          },
          onError: out.addError,
        );
        // Legacy public values (own profile only; removed by the server).
        pubSub = _profile(uid).snapshots().listen(
          (d) {
            pub = d.data();
            pubSeen = true;
            serverChanged();
          },
          onError: (Object _) {
            pubSeen = true;
            serverChanged();
          },
        );
        overlaySub =
            _overlay.changes.where((u) => u == uid).listen((_) => publish());
      },
      onCancel: () async {
        await privSub?.cancel();
        await pubSub?.cancel();
        await overlaySub?.cancel();
      },
    );
    return out.stream;
  }

  /// Current server counters of [uid] - ONLY readable for the signed-in
  /// account itself (null when unreadable).
  Future<FollowCounts?> _readOwnCounts(String uid) async {
    try {
      final r = await Future.wait([_countsDoc(uid).get(), _profile(uid).get()]);
      return FollowCounts.merged(r[0].data(), r[1].data());
    } catch (_) {
      return null;
    }
  }

  /// Record a committed follow (+1) / unfollow (-1) on the FOLLOWER's own
  /// "following" (the followee's counts are private to the followee).
  void _recordChange({
    required String followerId,
    required int delta,
    required FollowCounts? before,
  }) {
    _overlay.record(followerId, FollowCounter.following, delta,
        serverBefore: before?.following);
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
    // Counter baseline (own, private) is read in parallel with the block
    // check, BEFORE the write, so it can never already include this follow.
    final beforeF = _readOwnCounts(followerId);
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
      _recordChange(followerId: followerId, delta: 1, before: before);
      _adjustCachedPublicCounts(
          followeeId: followeeId, followerId: followerId, delta: 1);
    }
  }

  /// Unfollow [followeeId] as [followerId]. Idempotent.
  Future<void> unfollowUser({
    required String followeeId,
    required String followerId,
  }) async {
    if (followeeId.isEmpty || followerId.isEmpty) return;
    final before = await _readOwnCounts(followerId);
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
      _recordChange(followerId: followerId, delta: -1, before: before);
      _adjustCachedPublicCounts(
          followeeId: followeeId, followerId: followerId, delta: -1);
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

  /// Mirror flag the server stamps on a follow of a BUSINESS
  /// (functions followCounters.ts MIRROR_STORE_FLAG).
  static const String storeFlagField = 'isStore';

  /// Page of the business accounts [uid] follows (own "Stores" list), by id.
  /// Equality + document-id order: automatic single-field index.
  Future<FollowPage> followedStoresPage(
    String uid, {
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = pageSize,
  }) async {
    Query<Map<String, dynamic>> q = _followingCol(uid)
        .where(storeFlagField, isEqualTo: true)
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (after != null) q = q.startAfterDocument(after);
    final snap = await q.get();
    return FollowPage(
      userIds: [for (final d in snap.docs) d.id],
      cursor: snap.docs.isEmpty ? after : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

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

  // ── search ─────────────────────────────────────────────────────────────

  /// Searchable-name fields, written ONLY by the server (functions
  /// social/followNames.ts) — normalized with [normalizeFollowName].
  static const String followerNameField = 'followerNameLower';
  static const String followeeNameField = 'followeeNameLower';

  /// Page size for the followers / following search.
  static const int searchPageSize = 20;

  /// Prefix search over ALL of [uid]'s followers by name (server-side, not
  /// just the loaded rows): one ordered, bounded query per page inside the
  /// subcollection (automatic single-field index). [query] is normalized
  /// here with [normalizeFollowName] (same as the server). Edges without a
  /// name yet (pre-backfill) are not matched; they still list normally.
  Future<FollowPage> searchFollowers(
    String uid,
    String query, {
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = searchPageSize,
  }) =>
      _search(_followersCol(uid), followerNameField, query,
          after: after, limit: limit);

  /// Prefix search over ALL the accounts [uid] follows, by name.
  Future<FollowPage> searchFollowing(
    String uid,
    String query, {
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = searchPageSize,
  }) =>
      _search(_followingCol(uid), followeeNameField, query,
          after: after, limit: limit);

  Future<FollowPage> _search(
    CollectionReference<Map<String, dynamic>> col,
    String field,
    String rawQuery, {
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    final query = normalizeFollowName(rawQuery);
    if (query.isEmpty) {
      return FollowPage(userIds: const [], cursor: after, hasMore: false);
    }
    Query<Map<String, dynamic>> q = col.orderBy(field);
    q = after != null ? q.startAfterDocument(after) : q.startAt([query]);
    q = q.endAt([query + String.fromCharCode(0xF8FF)]).limit(limit);
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

  /// Live follower count of the signed-in business ITSELF (private: only the
  /// owner can read it).
  Stream<int> followerCount(String businessId) =>
      counts(businessId).map((c) => c.followers);

  /// One-off follower count of the signed-in business itself.
  Future<int> getFollowerCount(String businessId) async =>
      (await _readOwnCounts(businessId))?.followers ?? 0;

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
