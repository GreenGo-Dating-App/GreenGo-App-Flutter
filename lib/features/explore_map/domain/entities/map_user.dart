import 'package:equatable/equatable.dart';

/// Represents a user visible on the nearby map/list.
///
/// Coordinates are snapped to a ~500m grid (3 decimal places) for privacy,
/// so the displayed location is approximate.
class MapUser extends Equatable {
  final String userId;
  final double approximateLatitude;
  final double approximateLongitude;
  final int matchPercentage;
  final List<String> languagesShared;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? displayName;
  final String? photoUrl;
  final double? distanceKm;

  const MapUser({
    required this.userId,
    required this.approximateLatitude,
    required this.approximateLongitude,
    required this.matchPercentage,
    required this.languagesShared,
    required this.isOnline,
    this.lastSeen,
    this.displayName,
    this.photoUrl,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
        userId,
        approximateLatitude,
        approximateLongitude,
        matchPercentage,
        languagesShared,
        isOnline,
        lastSeen,
        displayName,
        photoUrl,
        distanceKm,
      ];
}
