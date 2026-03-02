import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/map_user.dart';

/// Firestore-backed model for [MapUser].
class MapUserModel extends MapUser {
  const MapUserModel({
    required super.userId,
    required super.approximateLatitude,
    required super.approximateLongitude,
    required super.matchPercentage,
    required super.languagesShared,
    required super.isOnline,
    super.lastSeen,
    super.displayName,
    super.photoUrl,
    super.distanceKm,
  });

  /// Create a [MapUserModel] from a Firestore document snapshot.
  ///
  /// Expects the document to come from the `profiles` collection.
  /// Coordinates are snapped to 3 decimal places (~110m) for privacy.
  factory MapUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>?;

    // Use effectiveLocation (traveler location) if available, else regular location
    final effectiveLocation =
        data['travelerLocation'] as Map<String, dynamic>?;
    final isTraveler = data['isTraveler'] as bool? ?? false;
    final travelerExpiryTs = data['travelerExpiry'] as Timestamp?;
    final isTravelerActive = isTraveler &&
        travelerExpiryTs != null &&
        travelerExpiryTs.toDate().isAfter(DateTime.now());

    final locSource =
        (isTravelerActive && effectiveLocation != null)
            ? effectiveLocation
            : location;

    final rawLat = (locSource?['latitude'] as num?)?.toDouble() ?? 0.0;
    final rawLng = (locSource?['longitude'] as num?)?.toDouble() ?? 0.0;

    // Snap to 3 decimal places for privacy (~110m grid)
    final snappedLat = _snapCoordinate(rawLat);
    final snappedLng = _snapCoordinate(rawLng);

    final languages = data['languages'] != null
        ? List<String>.from(data['languages'] as List)
        : <String>[];

    final photoUrls = data['photoUrls'] != null
        ? List<String>.from(data['photoUrls'] as List)
        : <String>[];

    final lastSeenTs = data['lastSeen'] as Timestamp?;

    return MapUserModel(
      userId: doc.id,
      approximateLatitude: snappedLat,
      approximateLongitude: snappedLng,
      matchPercentage: 0, // Calculated separately
      languagesShared: languages,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: lastSeenTs?.toDate(),
      displayName: data['displayName'] as String?,
      photoUrl: photoUrls.isNotEmpty ? photoUrls.first : null,
      distanceKm: null, // Calculated separately via Haversine
    );
  }

  /// Convert to JSON (for caching or API calls).
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'approximateLatitude': approximateLatitude,
      'approximateLongitude': approximateLongitude,
      'matchPercentage': matchPercentage,
      'languagesShared': languagesShared,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'displayName': displayName,
      'photoUrl': photoUrl,
      'distanceKm': distanceKm,
    };
  }

  /// Create a copy with updated fields.
  MapUserModel copyWith({
    String? userId,
    double? approximateLatitude,
    double? approximateLongitude,
    int? matchPercentage,
    List<String>? languagesShared,
    bool? isOnline,
    DateTime? lastSeen,
    String? displayName,
    String? photoUrl,
    double? distanceKm,
  }) {
    return MapUserModel(
      userId: userId ?? this.userId,
      approximateLatitude: approximateLatitude ?? this.approximateLatitude,
      approximateLongitude: approximateLongitude ?? this.approximateLongitude,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      languagesShared: languagesShared ?? this.languagesShared,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  /// Snap a coordinate to 3 decimal places (~110m precision).
  static double _snapCoordinate(double value) {
    return (value * 1000).roundToDouble() / 1000;
  }
}
