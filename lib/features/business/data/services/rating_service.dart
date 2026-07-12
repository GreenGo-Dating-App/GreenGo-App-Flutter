import 'package:cloud_firestore/cloud_firestore.dart';

/// Business Rating service.
///
/// Lets a user rate a public business account 1–5 stars on its storefront and
/// exposes the denormalized average + count for the header. Designed to scale to
/// millions of ratings without any aggregate/count query:
///
///  * Each user's rating is stored ONCE at
///    `business_ratings/{businessId}/ratings/{raterId} = {stars, updatedAt}`.
///    One doc per (user, business) → a rating is inherently "one per user",
///    and re-rating simply overwrites that doc.
///  * The aggregate is denormalized onto the business profile:
///      - `profiles/{businessId}.ratingSum`   (Σ of every user's stars)
///      - `profiles/{businessId}.ratingCount` (# of distinct raters)
///    maintained transactionally alongside the rating write, so the storefront
///    shows `avg = ratingSum / ratingCount` with ONE cheap doc read — no
///    fan-out over the ratings sub-collection, no composite index.
///
/// A business can never rate itself (`raterId == businessId` is rejected).
class RatingService {
  RatingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ratingDoc(
    String businessId,
    String raterId,
  ) =>
      _firestore
          .collection('business_ratings')
          .doc(businessId)
          .collection('ratings')
          .doc(raterId);

  DocumentReference<Map<String, dynamic>> _businessProfile(String businessId) =>
      _firestore.collection('profiles').doc(businessId);

  /// The current star value [raterId] gave [businessId], or `null` if none.
  /// A single-doc stream — cheap and index-free.
  Stream<int?> myRating({
    required String businessId,
    required String raterId,
  }) =>
      _ratingDoc(businessId, raterId).snapshots().map(
            (d) => (d.data()?['stars'] as num?)?.toInt(),
          );

  /// Live denormalized aggregate for [businessId]: the average star value and
  /// the number of raters. `(avg: 0, count: 0)` when the business has no ratings.
  Stream<({double avg, int count})> aggregate(String businessId) =>
      _businessProfile(businessId).snapshots().map((d) {
        final data = d.data();
        final sum = (data?['ratingSum'] as num?)?.toDouble() ?? 0;
        final count = (data?['ratingCount'] as num?)?.toInt() ?? 0;
        return (avg: count > 0 ? sum / count : 0.0, count: count);
      });

  /// One-off aggregate (for non-streaming callers).
  Future<({double avg, int count})> getAggregate(String businessId) async {
    final doc = await _businessProfile(businessId).get();
    final data = doc.data();
    final sum = (data?['ratingSum'] as num?)?.toDouble() ?? 0;
    final count = (data?['ratingCount'] as num?)?.toInt() ?? 0;
    return (avg: count > 0 ? sum / count : 0.0, count: count);
  }

  /// Upsert [raterId]'s [stars] (clamped 1..5) rating for [businessId] and keep
  /// the denormalized aggregate on `profiles/{businessId}` correct — all in ONE
  /// transaction so `ratingSum`/`ratingCount` never drift from the raw docs:
  ///
  ///  * NEW rating  → ratingSum += stars,            ratingCount += 1
  ///  * RE-rating   → ratingSum += (stars - oldStars), ratingCount unchanged
  ///  * No-op       → identical stars: nothing written (idempotent, no churn)
  ///
  /// A self-rating (`raterId == businessId`) is rejected — a business owner
  /// cannot rate their own business.
  Future<void> rateBusiness({
    required String businessId,
    required String raterId,
    required int stars,
  }) async {
    if (raterId == businessId) return; // owner cannot rate self
    final clamped = stars.clamp(1, 5);
    final ratingRef = _ratingDoc(businessId, raterId);
    final profileRef = _businessProfile(businessId);

    await _firestore.runTransaction((txn) async {
      final existing = await txn.get(ratingRef);
      final oldStars = (existing.data()?['stars'] as num?)?.toInt();

      if (oldStars == clamped) return; // unchanged — avoid a pointless write

      final now = FieldValue.serverTimestamp();
      txn.set(
        ratingRef,
        {'stars': clamped, 'updatedAt': now},
        SetOptions(merge: true),
      );

      final Map<String, Object?> aggUpdate;
      if (oldStars == null) {
        // First time this user rates the business.
        aggUpdate = {
          'ratingSum': FieldValue.increment(clamped),
          'ratingCount': FieldValue.increment(1),
        };
      } else {
        // Re-rating: shift the sum by the delta, count stays the same.
        aggUpdate = {
          'ratingSum': FieldValue.increment(clamped - oldStars),
        };
      }
      txn.set(profileRef, aggUpdate, SetOptions(merge: true));
    });
  }
}
