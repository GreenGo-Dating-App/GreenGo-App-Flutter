import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/profile/data/models/profile_model.dart'
    show normalizeCountryName;

/// Silently refreshes the current user's GPS location in Firestore.
///
/// Used on pull-to-refresh in discovery so distance sorting and country
/// filtering always reflect the user's real position.
class LocationRefreshService {

  LocationRefreshService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  /// Attempt to refresh the user's location. Returns silently on any failure
  /// (no permission, GPS off, timeout, etc.) — this is best-effort.
  ///
  /// When [isTravelerActive] is true the user has a virtual traveler location
  /// that overrides their real position for discovery. In that case we skip
  /// the GPS refresh entirely — `effectiveLocation` already points to the
  /// traveler location, and the real `location` will be refreshed once
  /// traveler mode expires.
  Future<void> refreshIfAllowed(String userId, {bool isTravelerActive = false}) async {
    if (isTravelerActive) {
      debugPrint('[LocationRefresh] Skipped — traveler mode active');
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final permission = await Geolocator.checkPermission();
      // Only proceed if already granted — never prompt from pull-to-refresh
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 8), onTimeout: () {
        throw Exception('GPS timeout');
      });

      // Reverse-geocode to get city + country
      var city = '';
      var country = '';
      var displayAddress = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality ??
              place.subLocality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              '';
          country = normalizeCountryName(place.country ?? '');
          displayAddress =
              city.isNotEmpty ? '$city, $country' : country;
        }
      } catch (_) {
        // Geocoding failed — still update lat/lng
      }

      // Build update map — always update coordinates
      final update = <String, dynamic>{
        'location.latitude': position.latitude,
        'location.longitude': position.longitude,
      };
      if (city.isNotEmpty) update['location.city'] = city;
      if (country.isNotEmpty) {
        update['location.country'] = country;
        update['location.countryLower'] = country.toLowerCase();
      }
      if (displayAddress.isNotEmpty) {
        update['location.displayAddress'] = displayAddress;
      }

      await _firestore.collection('profiles').doc(userId).update(update);
      debugPrint('[LocationRefresh] Updated $userId → $city, $country '
          '(${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)})');
    } catch (e) {
      debugPrint('[LocationRefresh] Skipped: $e');
    }
  }
}
