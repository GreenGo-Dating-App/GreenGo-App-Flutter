import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/profile/data/models/profile_model.dart'
    show normalizeCountryName;
import '../../features/profile/domain/entities/location.dart';

/// Location helpers for the web/PWA build.
///
/// The `geocoding` plugin declares only `android` and `ios` platforms, so
/// `placemarkFromCoordinates` throws `MissingPluginException` on web — even when
/// the browser hands back a perfectly good position. These helpers cover that
/// gap: Nominatim for reverse geocoding (the web "Update current location"
/// button and onboarding) and forward geocoding (a hand-typed event
/// location), and ipwho.is for a rough fix when the browser gives us no
/// coordinates at all.
///
/// NOTE: both are free public endpoints with no key and no contractual rate
/// limit. They run during web onboarding, on a manual web location update and
/// when the web session location refresh detects a move of more than
/// kLocationChangeThresholdKm (never for an unchanged position), so the volume
/// is low — but if that changes, move them behind a Cloud Function with a paid
/// geocoder.
class WebLocationFallback {
  WebLocationFallback._();

  static const Duration _timeout = Duration(seconds: 8);

  /// Reverse-geocode [latitude]/[longitude] into a city + country via Nominatim.
  ///
  /// Returns null when the lookup fails so the caller can fall back to a
  /// coordinate-only location rather than losing the position entirely.
  static Future<Location?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=$latitude&lon=$longitude'
        '&zoom=10&addressdetails=1',
      );
      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final addr = (data['address'] as Map<String, dynamic>?) ?? {};
      final city = _firstNonEmpty([
        addr['city'],
        addr['town'],
        addr['village'],
        addr['municipality'],
        addr['county'],
        addr['state'],
      ]);
      final country = normalizeCountryName((addr['country'] ?? '').toString());
      if (city.isEmpty && country.isEmpty) return null;

      return Location(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
        displayAddress: _display(city, country, latitude, longitude),
      );
    } catch (_) {
      return null;
    }
  }

  /// Forward-geocode a free-text place ([query]: a venue, street address or
  /// city) into coordinates + city/country via Nominatim search.
  ///
  /// Used when an event organiser types the location by hand. Returns null on
  /// an empty query, no match or any failure, so the caller can keep the typed
  /// text without coordinates.
  static Future<Location?> forwardGeocode(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': q,
        'limit': '1',
        'addressdetails': '1',
      });
      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      return parseSearchResponse(resp.body);
    } catch (_) {
      return null;
    }
  }

  /// Parse a Nominatim `/search?format=jsonv2` response body (a JSON array)
  /// into the first result's [Location]. Returns null for an empty array,
  /// malformed JSON or a result without usable coordinates. Public for tests.
  static Location? parseSearchResponse(String body) {
    try {
      final data = jsonDecode(body);
      if (data is! List || data.isEmpty) return null;
      final first = data.first;
      if (first is! Map) return null;
      final latitude = double.tryParse('${first['lat'] ?? ''}');
      final longitude = double.tryParse('${first['lon'] ?? ''}');
      if (latitude == null || longitude == null) return null;
      if (latitude.abs() > 90 || longitude.abs() > 180) return null;

      final addr = first['address'] is Map
          ? Map<String, dynamic>.from(first['address'] as Map)
          : const <String, dynamic>{};
      final city = _firstNonEmpty([
        addr['city'],
        addr['town'],
        addr['village'],
        addr['municipality'],
        addr['county'],
        addr['state'],
      ]);
      final country = normalizeCountryName((addr['country'] ?? '').toString());
      final displayName = (first['display_name'] ?? '').toString().trim();

      return Location(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
        displayAddress: displayName.isNotEmpty
            ? displayName
            : _display(city, country, latitude, longitude),
      );
    } catch (_) {
      return null;
    }
  }

  /// Approximate the user's location from their IP address via ipwho.is.
  ///
  /// City-level at best and wrong behind a VPN, so treat it as a starting point
  /// the user can correct — never as a precise fix. Returns null on any failure.
  static Future<Location?> fromIpAddress() async {
    try {
      final uri = Uri.parse(
        'https://ipwho.is/?fields=success,city,country,latitude,longitude',
      );
      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['success'] != true) return null;

      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return null;

      final city = (data['city'] ?? '').toString().trim();
      final country = normalizeCountryName((data['country'] ?? '').toString());
      if (city.isEmpty && country.isEmpty) return null;

      return Location(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
        displayAddress: _display(city, country, latitude, longitude),
      );
    } catch (_) {
      return null;
    }
  }

  /// Human-readable label, degrading to coordinates when nothing resolved.
  static String _display(
    String city,
    String country,
    double latitude,
    double longitude,
  ) {
    final parts = [city, country].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = (v ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }
}
