import 'package:cloud_firestore/cloud_firestore.dart';

/// Business Follow service.
///
/// Follows/unfollows a public business account. Designed to scale to millions:
///
///  * Membership is stored TWICE (denormalized) so every read is a single,
///    index-free document lookup — no fan-out query, no composite index:
///      - `business_followers/{businessId}/followers/{uid}`  (who follows a business)
///      - `user_business_following/{uid}/businesses/{businessId}` (who a user follows)
///  * The follower COUNT is denormalized onto `profiles/{businessId}.followerCount`
///    and maintained transactionally alongside the membership write, so the
///    storefront can show a follower count with one cheap read instead of an
///    aggregate/count query.
///
/// TODO(follow-fanout): when a business publishes a new event, a Cloud Function
/// should fan out a notification to `business_followers/{businessId}/followers/*`
/// (batched, paginated) so followers are told about it. Keep the fan-out
/// server-side — never iterate followers on the client.
class FollowService {
  FollowService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _followerDoc(
    String businessId,
    String uid,
  ) =>
      _firestore
          .collection('business_followers')
          .doc(businessId)
          .collection('followers')
          .doc(uid);

  DocumentReference<Map<String, dynamic>> _followingDoc(
    String uid,
    String businessId,
  ) =>
      _firestore
          .collection('user_business_following')
          .doc(uid)
          .collection('businesses')
          .doc(businessId);

  DocumentReference<Map<String, dynamic>> _businessProfile(String businessId) =>
      _firestore.collection('profiles').doc(businessId);

  /// Live follow-state for [uid] against [businessId]. Emits `true` while the
  /// follower doc exists. A single-doc stream — cheap and index-free.
  Stream<bool> isFollowing({
    required String businessId,
    required String uid,
  }) =>
      _followerDoc(businessId, uid).snapshots().map((d) => d.exists);

  /// Live denormalized follower count for [businessId] (0 when absent).
  Stream<int> followerCount(String businessId) =>
      _businessProfile(businessId).snapshots().map(
            (d) => (d.data()?['followerCount'] as num?)?.toInt() ?? 0,
          );

  /// One-off follower count (for non-streaming callers).
  Future<int> getFollowerCount(String businessId) async {
    final doc = await _businessProfile(businessId).get();
    return (doc.data()?['followerCount'] as num?)?.toInt() ?? 0;
  }

  /// Follow [businessId] as [uid]. Idempotent: if already following, does
  /// nothing (and does NOT double-increment the count). A self-follow is a
  /// no-op. Writes both membership docs + the denormalized count atomically.
  Future<void> follow({
    required String businessId,
    required String uid,
  }) async {
    if (businessId == uid) return; // a business cannot follow itself
    final followerRef = _followerDoc(businessId, uid);
    final followingRef = _followingDoc(uid, businessId);
    final profileRef = _businessProfile(businessId);

    await _firestore.runTransaction((txn) async {
      final existing = await txn.get(followerRef);
      if (existing.exists) return; // already following — keep count stable
      final now = FieldValue.serverTimestamp();
      txn.set(followerRef, {'createdAt': now});
      txn.set(followingRef, {'createdAt': now});
      txn.set(
        profileRef,
        {'followerCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    });
  }

  /// Unfollow [businessId] as [uid]. Idempotent: if not following, does nothing
  /// (and does NOT decrement below the real count). Removes both membership
  /// docs + the denormalized count atomically.
  Future<void> unfollow({
    required String businessId,
    required String uid,
  }) async {
    final followerRef = _followerDoc(businessId, uid);
    final followingRef = _followingDoc(uid, businessId);
    final profileRef = _businessProfile(businessId);

    await _firestore.runTransaction((txn) async {
      final existing = await txn.get(followerRef);
      if (!existing.exists) return; // not following — nothing to remove
      txn.delete(followerRef);
      txn.delete(followingRef);
      txn.set(
        profileRef,
        {'followerCount': FieldValue.increment(-1)},
        SetOptions(merge: true),
      );
    });
  }

  /// Toggle follow state and return the resulting state (`true` = now
  /// following). Convenience for the follow button.
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
