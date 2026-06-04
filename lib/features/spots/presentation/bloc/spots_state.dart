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

  const SpotsLoaded({
    required this.spots,
    required this.city,
    this.selectedCategory,
  });
  final List<Spot> spots;
  final String city;
  final SpotCategory? selectedCategory;
}

/// Successfully loaded a spot detail with its reviews.
class SpotDetailLoaded extends SpotsState {

  const SpotDetailLoaded({
    required this.spot,
    required this.reviews,
  });
  final Spot spot;
  final List<SpotReview> reviews;
}

/// A spot was successfully created.
class SpotCreated extends SpotsState {

  const SpotCreated({required this.spot});
  final Spot spot;
}

/// A review was successfully added.
class ReviewAdded extends SpotsState {

  const ReviewAdded({required this.review});
  final SpotReview review;
}

/// Error state.
class SpotsError extends SpotsState {

  const SpotsError(this.message);
  final String message;
}
