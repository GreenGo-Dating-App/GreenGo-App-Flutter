/// Events for the Explore Map BLoC.
abstract class ExploreMapEvent {
  const ExploreMapEvent();
}

/// Load nearby users within a given radius.
class LoadNearbyUsers extends ExploreMapEvent {
  final String userId;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final List<String> currentUserLanguages;

  const LoadNearbyUsers({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    this.currentUserLanguages = const [],
  });
}

/// Refresh the nearby users list (pull-to-refresh).
class RefreshMap extends ExploreMapEvent {
  final String userId;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final List<String> currentUserLanguages;

  const RefreshMap({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    this.currentUserLanguages = const [],
  });
}

/// Toggle the user's "Show me on map" preference.
class ToggleShowOnMap extends ExploreMapEvent {
  final String userId;
  final bool showOnMap;

  const ToggleShowOnMap({
    required this.userId,
    required this.showOnMap,
  });
}
