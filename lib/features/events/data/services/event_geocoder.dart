import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart' hide Location;

import '../../../../core/services/web_location_fallback.dart';
import '../../../profile/data/models/profile_model.dart'
    show normalizeCountryName;
import '../../../profile/domain/entities/location.dart';

/// Forward-geocodes a location an organiser TYPED by hand into coordinates
/// (+ city/country), so a manually entered event can still land in the
/// nearest-first / geohash lists.
///
/// Native: the `geocoding` plugin (`locationFromAddress`), then
/// `placemarkFromCoordinates` for city/country. Web (the plugin has no web
/// implementation) and any native failure: Nominatim via
/// [WebLocationFallback.forwardGeocode].
///
/// Returns null when nothing resolves; the caller then saves the typed text
/// with NO coordinates (the event stays valid, just not geo-indexed).
class EventGeocoder {
  EventGeocoder._();

  static const Duration _timeout = Duration(seconds: 8);

  static Future<Location?> geocode(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    if (!kIsWeb) {
      try {
        final locs = await locationFromAddress(q).timeout(_timeout);
        if (locs.isNotEmpty) {
          final lat = locs.first.latitude;
          final lng = locs.first.longitude;
          var city = '';
          var country = '';
          try {
            final placemarks =
                await placemarkFromCoordinates(lat, lng).timeout(_timeout);
            if (placemarks.isNotEmpty) {
              final pl = placemarks.first;
              city = pl.locality ?? pl.subAdministrativeArea ?? '';
              country = normalizeCountryName(pl.country ?? '');
            }
          } catch (_) {/* coordinates alone are still useful */}
          return Location(
            latitude: lat,
            longitude: lng,
            city: city,
            country: country,
            displayAddress: q,
          );
        }
      } catch (_) {
        // Plugin failure / no match — try the web fallback below.
      }
    }

    return WebLocationFallback.forwardGeocode(q);
  }
}
