import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/spot.dart';
import '../models/spot_model.dart';
import '../models/spot_review_model.dart';

/// Remote data source for the Cultural Spots feature.
///
/// Collections:
/// - `spots` — top-level collection for spot documents
/// - `spots/{spotId}/reviews` — subcollection for reviews
///
/// On review add, the aggregate `rating` and `reviewCount` fields on the
/// parent spot are recalculated.
abstract class SpotsRemoteDataSource {
  /// Get spots filtered by [city] and optionally by [category].
  Future<List<SpotModel>> getSpots({
    required String city,
    SpotCategory? category,
  });

  /// Get a single spot by its [id].
  Future<SpotModel> getSpotById(String id);

  /// Create a new spot. Returns the created spot with its Firestore ID.
  Future<SpotModel> createSpot(SpotModel spot);

  /// Get all reviews for a spot, ordered by most recent first.
  Future<List<SpotReviewModel>> getReviews(String spotId);

  /// Add a review to a spot and update the aggregate rating.
  Future<SpotReviewModel> addReview(SpotReviewModel review);
}

class SpotsRemoteDataSourceImpl implements SpotsRemoteDataSource {
  final FirebaseFirestore firestore;

  SpotsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<SpotModel>> getSpots({
    required String city,
    SpotCategory? category,
  }) async {
    try {
      Query query = firestore
          .collection('spots')
          .where('city', isEqualTo: city);

      if (category != null) {
        query = query.where('category', isEqualTo: category.firestoreValue);
      }

      final querySnapshot = await query.limit(200).get();

      final spots = querySnapshot.docs
          .map((doc) => SpotModel.fromFirestore(doc))
          .toList();

      // Sort by rating descending (client-side to avoid composite index)
      spots.sort((a, b) => b.rating.compareTo(a.rating));

      debugPrint('[Spots] Found ${spots.length} spots in $city'
          '${category != null ? ' (${category.displayName})' : ''}');

      return spots;
    } catch (e) {
      debugPrint('[Spots] Error fetching spots: $e');
      rethrow;
    }
  }

  @override
  Future<SpotModel> getSpotById(String id) async {
    final doc = await firestore.collection('spots').doc(id).get();
    if (!doc.exists) {
      throw Exception('Spot not found');
    }
    return SpotModel.fromFirestore(doc);
  }

  @override
  Future<SpotModel> createSpot(SpotModel spot) async {
    final docRef = firestore.collection('spots').doc();
    final data = spot.toJson();
    await docRef.set(data);

    debugPrint('[Spots] Created spot: ${spot.name} (${docRef.id})');

    // Return the spot with its new Firestore ID
    return SpotModel(
      id: docRef.id,
      name: spot.name,
      description: spot.description,
      category: spot.category,
      latitude: spot.latitude,
      longitude: spot.longitude,
      city: spot.city,
      country: spot.country,
      rating: spot.rating,
      reviewCount: spot.reviewCount,
      photos: spot.photos,
      createdByUserId: spot.createdByUserId,
      createdByName: spot.createdByName,
      createdAt: spot.createdAt ?? DateTime.now(),
    );
  }

  @override
  Future<List<SpotReviewModel>> getReviews(String spotId) async {
    try {
      final querySnapshot = await firestore
          .collection('spots')
          .doc(spotId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs
          .map((doc) => SpotReviewModel.fromFirestore(doc, spotId))
          .toList();
    } catch (e) {
      debugPrint('[Spots] Error fetching reviews for $spotId: $e');
      rethrow;
    }
  }

  @override
  Future<SpotReviewModel> addReview(SpotReviewModel review) async {
    final spotRef = firestore.collection('spots').doc(review.spotId);
    final reviewsRef = spotRef.collection('reviews');

    // Add the review document
    final docRef = reviewsRef.doc();
    await docRef.set(review.toJson());

    // Recalculate aggregate rating on the spot
    await _updateAggregateRating(review.spotId);

    debugPrint(
        '[Spots] Added review by ${review.userName} to spot ${review.spotId} (rating: ${review.rating})');

    return SpotReviewModel(
      id: docRef.id,
      spotId: review.spotId,
      userId: review.userId,
      userName: review.userName,
      userPhotoUrl: review.userPhotoUrl,
      rating: review.rating,
      text: review.text,
      createdAt: review.createdAt,
    );
  }

  /// Recalculate and update the aggregate rating and review count on a spot.
  Future<void> _updateAggregateRating(String spotId) async {
    try {
      final reviewsSnapshot = await firestore
          .collection('spots')
          .doc(spotId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      final totalRating = reviewsSnapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['rating'] as num?)?.toInt() ?? 0),
      );

      final count = reviewsSnapshot.docs.length;
      final avgRating = totalRating / count;

      await firestore.collection('spots').doc(spotId).update({
        'rating': double.parse(avgRating.toStringAsFixed(1)),
        'reviewCount': count,
      });

      debugPrint(
          '[Spots] Updated aggregate rating for $spotId: $avgRating ($count reviews)');
    } catch (e) {
      debugPrint('[Spots] Error updating aggregate rating: $e');
    }
  }
}
