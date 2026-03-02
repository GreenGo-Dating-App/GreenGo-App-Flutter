import '../../domain/entities/map_user.dart';

/// States for the Explore Map BLoC.
abstract class ExploreMapState {
  const ExploreMapState();
}

/// Initial state before any data is loaded.
class ExploreMapInitial extends ExploreMapState {
  const ExploreMapInitial();
}

/// Loading nearby users.
class ExploreMapLoading extends ExploreMapState {
  const ExploreMapLoading();
}

/// Successfully loaded nearby users.
class ExploreMapLoaded extends ExploreMapState {
  final List<MapUser> users;
  final double radiusKm;
  final bool showOnMap;

  const ExploreMapLoaded({
    required this.users,
    required this.radiusKm,
    this.showOnMap = true,
  });
}

/// Error loading nearby users.
class ExploreMapError extends ExploreMapState {
  final String message;

  const ExploreMapError(this.message);
}
