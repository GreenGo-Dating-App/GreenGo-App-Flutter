import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/map_user.dart';

/// Abstract repository for the Explore Map feature.
abstract class ExploreMapRepository {
  /// Fetch nearby users within [radiusKm] of the given coordinates.
  ///
  /// Only returns users where `showOnMap` is `true`.
  /// Coordinates are snapped to 3 decimal places for privacy.
  Future<Either<Failure, List<MapUser>>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
  });

  /// Get the current user's map visibility settings.
  Future<Either<Failure, bool>> getUserMapSettings(String userId);

  /// Update the current user's `showOnMap` preference.
  Future<Either<Failure, void>> updateShowOnMap({
    required String userId,
    required bool showOnMap,
  });
}
