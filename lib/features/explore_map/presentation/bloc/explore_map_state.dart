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

  const ExploreMapLoaded({
    required this.users,
    required this.radiusKm,
    this.showOnMap = true,
  });
  final List<MapUser> users;
  final double radiusKm;
  final bool showOnMap;
}

/// Error loading nearby users.
class ExploreMapError extends ExploreMapState {

  const ExploreMapError(this.message);
  final String message;
}
