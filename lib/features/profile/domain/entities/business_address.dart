import 'package:equatable/equatable.dart';

import '../../../../core/services/place_search_service.dart';
import '../../../../core/utils/geo_query.dart';

/// The PUBLIC street address of a business storefront (owner rule
/// 2026-10-14: "business location must be set up using address and maps like
/// events"). Chosen with the same search + map picker as events
/// ([PickedPlace]) and shown on the storefront with a map.
///
/// Deliberately separate from the owner's personal `Profile.location`, which
/// stays private (exact coordinates only in profiles_private, public copy
/// offset by up to 1.5 km): a business address is meant to be found.
class BusinessAddress extends Equatable {
  const BusinessAddress({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.country = '',
    this.placeId,
  });

  factory BusinessAddress.fromPicked(PickedPlace p) => BusinessAddress(
        address: p.address,
        latitude: p.lat,
        longitude: p.lng,
        city: p.city,
        country: p.country,
        placeId: p.placeId,
      );

  /// Null when [m] is not a usable address (missing or invalid coordinates).
  static BusinessAddress? fromMap(Object? m) {
    if (m is! Map) return null;
    final lat = m['latitude'], lng = m['longitude'];
    if (lat is! num || lng is! num) return null;
    if (lat.abs() > 90 || lng.abs() > 180 || (lat == 0 && lng == 0)) return null;
    final address = '${m['address'] ?? ''}'.trim();
    if (address.isEmpty) return null;
    final placeId = '${m['placeId'] ?? ''}'.trim();
    return BusinessAddress(
      address: address,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      city: '${m['city'] ?? ''}'.trim(),
      country: '${m['country'] ?? ''}'.trim(),
      placeId: placeId.isEmpty ? null : placeId,
    );
  }

  final String address;
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String? placeId;

  /// Firestore shape; `geohash` (precision 9, like events) lets a future
  /// "businesses near me" query run nearest-first.
  Map<String, dynamic> toMap() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'country': country,
        if (placeId != null) 'placeId': placeId,
        'geohash': GeoQuery.encode(latitude, longitude),
      };

  /// "Street 1, City" for one-line summaries (no duplicated city).
  String get summary {
    final low = address.toLowerCase();
    return city.isNotEmpty && !low.contains(city.toLowerCase()) ? '$address, $city' : address;
  }

  @override
  List<Object?> get props => [address, latitude, longitude, city, country, placeId];
}
