import '../../domain/entities/spot.dart';
import '../../domain/entities/spot_review.dart';

/// Events for the Spots BLoC.
abstract class SpotsEvent {
  const SpotsEvent();
}

/// Load spots for a city, optionally filtered by category.
class LoadSpots extends SpotsEvent {
  final String city;
  final SpotCategory? category;

  const LoadSpots({
    required this.city,
    this.category,
  });
}

/// Load a single spot by ID (with its reviews).
class LoadSpotById extends SpotsEvent {
  final String spotId;

  const LoadSpotById({required this.spotId});
}

/// Create a new spot.
class CreateSpot extends SpotsEvent {
  final Spot spot;

  const CreateSpot({required this.spot});
}

/// Add a review to a spot.
class AddReview extends SpotsEvent {
  final SpotReview review;

  const AddReview({required this.review});
}
