import '../../../../core/services/place_search_service.dart';
import '../../../profile/domain/entities/location.dart';

/// Forward-geocodes a location an organiser TYPED by hand into coordinates
/// (+ city/country), so a manually entered event can still land in the
/// nearest-first / geohash lists.
///
/// Same path on Android, iOS and web: the server's `searchAddress` (top
/// match), then `resolvePlace` when that provider returns no coordinates. No
/// geocoder is called from the device, and the typed text stays the display
/// address.
///
/// Returns null when nothing resolves; the caller then saves the typed text
/// with NO coordinates (the event stays valid, just not geo-indexed).
class EventGeocoder {
  EventGeocoder._();

  static Future<Location?> geocode(
    String query, {
    String lang = 'en',
    PlaceSearchRepository? repository,
  }) async {
    final q = query.trim();
    if (q.length < 2) return null;
    final repo = repository ?? PlaceSearchRepository.instance;
    try {
      final token = newPlaceSessionToken();
      final results = await repo.search(q, lang: lang, sessionToken: token);
      if (results.isEmpty) return null;
      final top = results.first;
      var place = top.toPlace();
      if (place == null && top.placeId != null) {
        place = await repo.resolve(top.placeId!, sessionToken: token);
      }
      if (place == null) return null;
      return Location(
        latitude: place.lat,
        longitude: place.lng,
        city: place.city,
        country: place.country,
        displayAddress: q,
      );
    } catch (_) {
      return null;
    }
  }
}
