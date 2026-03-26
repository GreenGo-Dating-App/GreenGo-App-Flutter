import 'package:dio/dio.dart';
import 'api_key_service.dart';

/// Geocoding service using Google Maps REST API for web platform,
/// where the `geocoding` Flutter package has no implementation.
class WebGeocodingService {
  static String get _apiKey => ApiKeyService.googleMapsApiKey;
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static final _dio = Dio();

  static const _placesAutocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _placeDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Places Autocomplete: returns suggestions as user types (better UX than geocoding).
  static Future<List<PlaceAutocompleteSuggestion>> autocomplete(String input) async {
    if (input.trim().length < 2) return [];
    try {
      final response = await _dio.get(_placesAutocompleteUrl, queryParameters: {
        'input': input,
        'types': '(cities)',
        'key': _apiKey,
      });

      if (response.statusCode != 200) return [];

      final data = response.data;
      if (data['status'] != 'OK') return [];

      return (data['predictions'] as List)
          .take(5)
          .map((p) => PlaceAutocompleteSuggestion(
                placeId: p['place_id'] as String,
                description: p['description'] as String,
                mainText: p['structured_formatting']?['main_text'] as String? ?? p['description'] as String,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get place details (lat/lng + address components) from a place_id.
  static Future<WebGeocodingResult?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(_placeDetailsUrl, queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,address_components',
        'key': _apiKey,
      });

      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data['status'] != 'OK') return null;

      final result = data['result'];
      final location = result['geometry']['location'];
      final components = result['address_components'] as List;

      String city = '';
      String country = '';

      for (final comp in components) {
        final types = List<String>.from(comp['types']);
        if (types.contains('locality')) {
          city = comp['long_name'];
        } else if (city.isEmpty && types.contains('administrative_area_level_3')) {
          city = comp['long_name'];
        } else if (city.isEmpty && types.contains('administrative_area_level_2')) {
          city = comp['long_name'];
        } else if (city.isEmpty && types.contains('administrative_area_level_1')) {
          city = comp['long_name'];
        }
        if (types.contains('country')) {
          country = comp['long_name'];
        }
      }

      final displayAddress = city.isNotEmpty ? '$city, $country' : country;
      return WebGeocodingResult(
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
        city: city,
        country: country,
        displayAddress: displayAddress.isNotEmpty ? displayAddress : 'Unknown',
      );
    } catch (_) {
      return null;
    }
  }

  /// Forward geocode: address string -> list of results with lat/lng + address components.
  static Future<List<WebGeocodingResult>> searchAddress(String query) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'address': query,
        'key': _apiKey,
      });

      if (response.statusCode != 200) return [];

      final data = response.data;
      if (data['status'] != 'OK') return [];

      final results = <WebGeocodingResult>[];
      for (final item in (data['results'] as List).take(5)) {
        final location = item['geometry']['location'];
        final components = item['address_components'] as List;

        String city = '';
        String country = '';

        for (final comp in components) {
          final types = List<String>.from(comp['types']);
          if (types.contains('locality')) {
            city = comp['long_name'];
          } else if (city.isEmpty && types.contains('administrative_area_level_3')) {
            city = comp['long_name'];
          } else if (city.isEmpty && types.contains('administrative_area_level_2')) {
            city = comp['long_name'];
          } else if (city.isEmpty && types.contains('administrative_area_level_1')) {
            city = comp['long_name'];
          }
          if (types.contains('country')) {
            country = comp['long_name'];
          }
        }

        final displayAddress = city.isNotEmpty ? '$city, $country' : country;
        if (displayAddress.isNotEmpty) {
          results.add(WebGeocodingResult(
            latitude: (location['lat'] as num).toDouble(),
            longitude: (location['lng'] as num).toDouble(),
            city: city,
            country: country,
            displayAddress: displayAddress,
          ));
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  /// Reverse geocode: lat/lng -> address components.
  static Future<WebGeocodingResult?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'latlng': '$lat,$lng',
        'key': _apiKey,
      });

      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data['status'] != 'OK' || (data['results'] as List).isEmpty) return null;

      final item = data['results'][0];
      final components = item['address_components'] as List;

      String city = '';
      String country = '';

      for (final comp in components) {
        final types = List<String>.from(comp['types']);
        if (types.contains('locality')) {
          city = comp['long_name'];
        } else if (city.isEmpty && types.contains('administrative_area_level_3')) {
          city = comp['long_name'];
        } else if (city.isEmpty && types.contains('administrative_area_level_2')) {
          city = comp['long_name'];
        } else if (city.isEmpty && types.contains('administrative_area_level_1')) {
          city = comp['long_name'];
        }
        if (types.contains('country')) {
          country = comp['long_name'];
        }
      }

      if (city.isEmpty && country.isEmpty) return null;

      final displayAddress = city.isNotEmpty ? '$city, $country' : country;
      return WebGeocodingResult(
        latitude: lat,
        longitude: lng,
        city: city,
        country: country,
        displayAddress: displayAddress,
      );
    } catch (_) {
      return null;
    }
  }
}

class WebGeocodingResult {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String displayAddress;

  const WebGeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.displayAddress,
  });
}

class PlaceAutocompleteSuggestion {
  final String placeId;
  final String description;
  final String mainText;

  const PlaceAutocompleteSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
  });
}
