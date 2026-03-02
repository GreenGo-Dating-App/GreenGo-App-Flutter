import '../../domain/entities/spot.dart';
import '../../domain/entities/spot_review.dart';

/// States for the Spots BLoC.
abstract class SpotsState {
  const SpotsState();
}

/// Initial state before any data is loaded.
class SpotsInitial extends SpotsState {
  const SpotsInitial();
}

/// Loading spots or spot detail.
class SpotsLoading extends SpotsState {
  const SpotsLoading();
}

/// Successfully loaded a list of spots.
class SpotsLoaded extends SpotsState {
  final List<Spot> spots;
  final String city;
  final SpotCategory? selectedCategory;

  const SpotsLoaded({
    required this.spots,
    required this.city,
    this.selectedCategory,
  });
}

/// Successfully loaded a spot detail with its reviews.
class SpotDetailLoaded extends SpotsState {
  final Spot spot;
  final List<SpotReview> reviews;

  const SpotDetailLoaded({
    required this.spot,
    required this.reviews,
  });
}

/// A spot was successfully created.
class SpotCreated extends SpotsState {
  final Spot spot;

  const SpotCreated({required this.spot});
}

/// A review was successfully added.
class ReviewAdded extends SpotsState {
  final SpotReview review;

  const ReviewAdded({required this.review});
}

/// Error state.
class SpotsError extends SpotsState {
  final String message;

  const SpotsError(this.message);
}
