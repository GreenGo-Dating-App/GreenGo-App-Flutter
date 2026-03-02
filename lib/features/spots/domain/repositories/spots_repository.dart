import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/spot.dart';
import '../entities/spot_review.dart';

/// Abstract repository for the Cultural Spots feature.
abstract class SpotsRepository {
  /// Get spots filtered by [city] and optionally by [category].
  Future<Either<Failure, List<Spot>>> getSpots({
    required String city,
    SpotCategory? category,
  });

  /// Get a single spot by its [id].
  Future<Either<Failure, Spot>> getSpotById(String id);

  /// Create a new spot. Returns the created spot with its Firestore ID.
  Future<Either<Failure, Spot>> createSpot(Spot spot);

  /// Get reviews for a spot.
  Future<Either<Failure, List<SpotReview>>> getReviews(String spotId);

  /// Add a review to a spot. Also updates the aggregate rating.
  Future<Either<Failure, SpotReview>> addReview(SpotReview review);
}
