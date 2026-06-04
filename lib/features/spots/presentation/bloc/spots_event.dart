import '../../domain/entities/spot.dart';
import '../../domain/entities/spot_review.dart';

/// Events for the Spots BLoC.
abstract class SpotsEvent {
  const SpotsEvent();
}

/// Load spots for a city, optionally filtered by category.
class LoadSpots extends SpotsEvent {

  const LoadSpots({
    required this.city,
    this.category,
  });
  final String city;
  final SpotCategory? category;
}

/// Load a single spot by ID (with its reviews).
class LoadSpotById extends SpotsEvent {

  const LoadSpotById({required this.spotId});
  final String spotId;
}

/// Create a new spot.
class CreateSpot extends SpotsEvent {

  const CreateSpot({required this.spot});
  final Spot spot;
}

/// Add a review to a spot.
class AddReview extends SpotsEvent {

  const AddReview({required this.review});
  final SpotReview review;
}
