import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../profile/data/private_profile.dart';
import '../../domain/entities/globe_user.dart';
import '../country_centroids.dart';

class GlobeUserModel extends GlobeUser {
  const GlobeUserModel({
    required super.userId,
    required super.displayName,
    required super.pinLatitude, required super.pinLongitude, required super.country, required super.city, required super.pinType, super.photoUrl,
    super.isOnline,
    super.isTravelerActive,
    super.travelerCountry,
    super.matchId,
    super.discoverability,
    super.realCountryLatitude,
    super.realCountryLongitude,
  });

  factory GlobeUserModel.fromFirestore({
    required Map<String, dynamic> data,
    required String odcId,
    required GlobePinType pinType,
    String? matchId,
    Random? random,
  }) {
    final rng = random ?? Random();

    final displayName = data['displayName'] as String? ?? 'Unknown';
    final photoUrls = data['photoUrls'] as List?;
    final photoUrl = (photoUrls != null && photoUrls.isNotEmpty)
        ? photoUrls[0] as String
        : null;

    // Parse location
    final locationData = data['location'] as Map<String, dynamic>?;
    final lat = (locationData?['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (locationData?['longitude'] as num?)?.toDouble() ?? 0.0;
    final city = locationData?['city'] as String? ?? 'Unknown';
    final country = locationData?['country'] as String? ?? 'Unknown';

    // Parse traveler status
    final isTraveler = data['isTraveler'] as bool? ?? false;
    final travelerExpiryTs = data['travelerExpiry'] as Timestamp?;
    final now = DateTime.now();
    final isTravelerActive = isTraveler &&
        travelerExpiryTs != null &&
        travelerExpiryTs.toDate().isAfter(now);

    // Traveler location
    final travelerLocationData =
        data['travelerLocation'] as Map<String, dynamic>?;
    final travelerLat =
        (travelerLocationData?['latitude'] as num?)?.toDouble();
    final travelerLng =
        (travelerLocationData?['longitude'] as num?)?.toDouble();
    final travelerCountry =
        travelerLocationData?['country'] as String?;

    // Effective location (traveler-aware)
    final effectiveLat = isTravelerActive && travelerLat != null
        ? travelerLat
        : lat;
    final effectiveLng = isTravelerActive && travelerLng != null
        ? travelerLng
        : lng;
    final effectiveCountry = isTravelerActive && travelerCountry != null
        ? travelerCountry
        : country;

    // Online status
    final isOnline = data['isOnline'] as bool? ?? false;

    // Globe discoverability
    final discoverabilityStr =
        data['globeDiscoverability'] as String? ?? 'approximate';
    final discoverability = _parseDiscoverability(discoverabilityStr);

    // Compute pin coordinates based on pin type and discoverability
    List<double> pinCoords;
    double? realCountryLat;
    double? realCountryLng;

    // Everyone (own pin included) is shown at their discoverability level.
    // 'exact' = the server-published ±100 m preciseLocation, as is.
    pinCoords = pinCoordsFor(
      discoverability, effectiveLat, effectiveLng, effectiveCountry, rng,
      precise: preciseCoordsOf(data),
    );

    // Compute real country centroid for traveler flight path arc
    if (isTravelerActive && travelerCountry != null) {
      final realCentroid = countryCentroids[country] ?? [0.0, 0.0];
      realCountryLat = realCentroid[0];
      realCountryLng = realCentroid[1];
    }

    return GlobeUserModel(
      userId: odcId,
      displayName: displayName,
      photoUrl: photoUrl,
      pinLatitude: pinCoords[0],
      pinLongitude: pinCoords[1],
      country: effectiveCountry,
      city: city,
      pinType: pinType,
      isOnline: isOnline,
      isTravelerActive: isTravelerActive,
      travelerCountry: isTravelerActive ? travelerCountry : null,
      matchId: matchId,
      discoverability: discoverability,
      realCountryLatitude: realCountryLat,
      realCountryLongitude: realCountryLng,
    );
  }

  static GlobeDiscoverability _parseDiscoverability(String? value) {
    switch (value) {
      case 'exact':
        return GlobeDiscoverability.exact;
      case 'approximate':
        return GlobeDiscoverability.approximate;
      case 'hidden':
        return GlobeDiscoverability.hidden;
      case 'country':
      default:
        return GlobeDiscoverability.country;
    }
  }

  /// Pin position for [discoverability]. 'exact' uses [precise] (the
  /// profile's server-published `preciseLocation`, already within 100 m and
  /// offset per user) with NO extra client jitter; without it (not computed
  /// yet) it falls back to the legacy jitter around [lat]/[lng].
  static List<double> pinCoordsFor(
    GlobeDiscoverability discoverability,
    double lat,
    double lng,
    String country,
    Random rng, {
    (double, double)? precise,
  }) {
    switch (discoverability) {
      case GlobeDiscoverability.exact:
        if (precise != null) return [precise.$1, precise.$2];
        return getExactJittered(lat, lng, random: rng);
      case GlobeDiscoverability.approximate:
        return getHilbertCentroid(lat, lng, random: rng);
      case GlobeDiscoverability.country:
      case GlobeDiscoverability.hidden:
        return getJitteredCentroid(country, random: rng);
    }
  }
}
