import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Attraction page-view counter (unique viewers per day) and the signed-in
/// user's own rating (`attraction_ratings/{id}/ratings/{uid}`).
///
/// Attractions come from a static catalogue, so stats live separately in
/// `attraction_stats/{attractionId}` { viewCount, updatedAt }. `viewCount` is
/// written ONLY by the `onAttractionViewRecorded` Cloud Function; the client
/// just creates `attraction_stats/{id}/daily_viewers/{YYYYMMDD}_{uid}` (UTC
/// date) when the page opens. Bounded: at most one tiny create per
/// user/day/attraction — repeat opens in the same session skip the write, and
/// a repeat on another session is refused by the rules (create-only).
class AttractionStatsService {
  AttractionStatsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// "{attractionId}_{YYYYMMDD}_{uid}" already recorded in this process.
  static final Set<String> _recorded = {};

  /// UTC day key, e.g. 20261001.
  @visibleForTesting
  static String dayKey(DateTime now) {
    final u = now.toUtc();
    return (u.year * 10000 + u.month * 100 + u.day).toString();
  }

  DocumentReference<Map<String, dynamic>> _stats(int attractionId) =>
      _db.collection('attraction_stats').doc('$attractionId');

  /// One-off read of the public unique-viewer count (0 when none yet).
  Future<int> viewCount(int attractionId) async {
    try {
      final snap = await _stats(attractionId).get();
      final v = (snap.data()?['viewCount'] as num?)?.toInt() ?? 0;
      return v < 0 ? 0 : v;
    } catch (_) {
      return 0;
    }
  }

  /// Live `attraction_stats/{id}` (viewCount + the rating aggregate). Used by
  /// the detail page only, so the user's own rating reconciles as soon as the
  /// aggregate trigger has run. Errors end the stream silently.
  Stream<Map<String, dynamic>?> watchStats(int attractionId) => _stats(attractionId)
      .snapshots()
      .map((s) => s.data())
      .handleError((_) {});

  DocumentReference<Map<String, dynamic>> _myRating(int attractionId, String uid) =>
      _db
          .collection('attraction_ratings')
          .doc('$attractionId')
          .collection('ratings')
          .doc(uid);

  String? get _uid {
    final u = (_auth ?? FirebaseAuth.instance).currentUser?.uid;
    return (u == null || u.isEmpty) ? null : u;
  }

  /// The signed-in user's own rating doc, live (null data = not rated).
  Stream<DocumentSnapshot<Map<String, dynamic>>>? watchMyRating(int attractionId) {
    final uid = _uid;
    if (uid == null) return null;
    return _myRating(attractionId, uid)
        .snapshots(includeMetadataChanges: true)
        .handleError((_) {});
  }

  /// Rate [attractionId] with [stars] (1..5) as the signed-in user. [existed]
  /// says whether the user already had a rating doc: a first rating creates it
  /// (createdAt + updatedAt), a change only touches stars + updatedAt (the
  /// rules keep createdAt immutable). The aggregate on attraction_stats is
  /// server-owned (onAttractionRatingWritten). Throws on failure.
  Future<void> rate(int attractionId, int stars, {required bool existed}) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    if (stars < 1 || stars > 5) throw ArgumentError.value(stars, 'stars');
    final ref = _myRating(attractionId, uid);
    if (existed) {
      await ref.update({'stars': stars, 'updatedAt': FieldValue.serverTimestamp()});
    } else {
      await ref.set({
        'stars': stars,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Remove the signed-in user's rating. Throws on failure.
  Future<void> removeRating(int attractionId) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    await _myRating(attractionId, uid).delete();
  }

  /// Record that the signed-in user viewed [attractionId] today. Returns true
  /// when THIS call created today's viewer doc (i.e. a new unique view).
  /// Never throws.
  Future<bool> recordView(int attractionId) async {
    final uid = (_auth ?? FirebaseAuth.instance).currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;
    final now = DateTime.now();
    final day = dayKey(now);
    final key = '${attractionId}_${day}_$uid';
    if (!_recorded.add(key)) return false;
    try {
      await _stats(attractionId)
          .collection('daily_viewers')
          .doc('${day}_$uid')
          .set({
        'at': FieldValue.serverTimestamp(),
        // Lets a Firestore TTL policy on `expireAt` reap old viewer docs.
        'expireAt': Timestamp.fromDate(now.toUtc().add(const Duration(days: 3))),
      });
      return true;
    } catch (_) {
      // Already viewed today (the rules refuse the overwrite) or offline.
      return false;
    }
  }
}
