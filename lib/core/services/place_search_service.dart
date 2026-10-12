import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../features/profile/data/models/profile_model.dart'
    show normalizeCountryName;
import '../../features/profile/domain/entities/location.dart';

/// What a search is for: any address/place, or cities only.
enum PlaceSearchMode { address, city }

/// One row of the as-you-type suggestion list.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.id,
    required this.primary,
    required this.secondary,
    this.lat,
    this.lng,
    this.city = '',
    this.country = '',
    this.countryCode = '',
    this.placeId,
  });

  factory PlaceSuggestion.fromMap(Map<String, dynamic> m) => PlaceSuggestion(
        id: '${m['id'] ?? ''}',
        primary: '${m['primary'] ?? ''}'.trim(),
        secondary: '${m['secondary'] ?? ''}'.trim(),
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        city: '${m['city'] ?? ''}'.trim(),
        country: normalizeCountryName('${m['country'] ?? ''}'.trim()),
        countryCode: '${m['countryCode'] ?? ''}',
        placeId: m['placeId'] as String?,
      );

  final String id;
  final String primary;
  final String secondary;

  /// Null for providers that need [PlaceSearchRepository.resolve] first.
  final double? lat;
  final double? lng;
  final String city;
  final String country;
  final String countryCode;
  final String? placeId;

  bool get hasCoordinates => lat != null && lng != null;

  /// One-line label: "Piazza Navona, 00186 Rome, Italy".
  String get fullText =>
      [primary, secondary].where((s) => s.isNotEmpty).join(', ');

  PickedPlace? toPlace() => hasCoordinates
      ? PickedPlace(
          address: fullText,
          lat: lat!,
          lng: lng!,
          city: city,
          country: country,
          placeId: placeId,
        )
      : null;
}

/// The location picker's result.
class PickedPlace {
  const PickedPlace({
    required this.address,
    required this.lat,
    required this.lng,
    this.city = '',
    this.country = '',
    this.placeId,
  });

  factory PickedPlace.fromMap(Map<String, dynamic> m) => PickedPlace(
        address: '${m['address'] ?? ''}'.trim(),
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        city: '${m['city'] ?? ''}'.trim(),
        country: normalizeCountryName('${m['country'] ?? ''}'.trim()),
        placeId: (m['placeId'] as String?)?.trim().isEmpty ?? true
            ? null
            : m['placeId'] as String,
      );

  final String address;
  final double lat;
  final double lng;
  final String city;
  final String country;
  final String? placeId;

  PickedPlace copyWith({String? address, double? lat, double? lng}) =>
      PickedPlace(
        address: address ?? this.address,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        city: city,
        country: country,
        placeId: placeId,
      );

  /// The app's [Location] entity (events, experiences, profile).
  Location toLocation() => Location(
        latitude: lat,
        longitude: lng,
        city: city,
        country: country,
        displayAddress: address.isNotEmpty
            ? address
            : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      );
}

/// Why a search produced no list.
enum PlaceSearchFailure { offline, rateLimited, unavailable }

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.failure);
  final PlaceSearchFailure failure;
  @override
  String toString() => 'PlaceSearchException($failure)';
}

/// Address search, place details and reverse geocoding.
///
/// Everything goes through our own Cloud Functions (`searchAddress`,
/// `resolvePlace`, `reverseGeocode`): no third party sees the user's IP, no
/// key ships in the app, and the server caches and rate-limits for everyone.
abstract class PlaceSearchRepository {
  /// The app-wide instance. Tests replace it with a fake.
  static PlaceSearchRepository instance = CallablePlaceSearchRepository();

  Future<List<PlaceSuggestion>> search(
    String query, {
    required String lang,
    PlaceSearchMode mode = PlaceSearchMode.address,
    double? biasLat,
    double? biasLng,
    String? sessionToken,
  });

  /// Coordinates for a suggestion without them (Google).
  Future<PickedPlace?> resolve(String placeId, {String? sessionToken});

  /// The address at a pin. Null when nothing resolves (the pin still counts).
  Future<PickedPlace?> reverse(double lat, double lng, {required String lang});
}

/// A new billing session token (Google bills a whole typing session plus
/// its place details as one request when they share it).
String newPlaceSessionToken([Random? random]) {
  final r = random ?? Random.secure();
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  return List.generate(32, (_) => chars[r.nextInt(chars.length)]).join();
}

class CallablePlaceSearchRepository implements PlaceSearchRepository {
  CallablePlaceSearchRepository({
    @visibleForTesting
    Future<Map<String, dynamic>> Function(
            String name, Map<String, dynamic> data)?
        call,
  }) : _call = call ?? _callFunction;

  final Future<Map<String, dynamic>> Function(
      String name, Map<String, dynamic> data) _call;

  static const Duration _timeout = Duration(seconds: 10);

  static Future<Map<String, dynamic>> _callFunction(
      String name, Map<String, dynamic> data) async {
    final res = await FirebaseFunctions.instance
        .httpsCallable(name, options: HttpsCallableOptions(timeout: _timeout))
        .call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> _guarded(
      String name, Map<String, dynamic> data) async {
    try {
      return await _call(name, data);
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'resource-exhausted':
          throw const PlaceSearchException(PlaceSearchFailure.rateLimited);
        case 'unavailable':
        case 'deadline-exceeded':
        case 'internal':
          // The callable SDK reports "no network" as unavailable/internal.
          throw const PlaceSearchException(PlaceSearchFailure.unavailable);
        default:
          throw const PlaceSearchException(PlaceSearchFailure.unavailable);
      }
    } on PlaceSearchException {
      rethrow;
    } catch (_) {
      throw const PlaceSearchException(PlaceSearchFailure.offline);
    }
  }

  @override
  Future<List<PlaceSuggestion>> search(
    String query, {
    required String lang,
    PlaceSearchMode mode = PlaceSearchMode.address,
    double? biasLat,
    double? biasLng,
    String? sessionToken,
  }) async {
    final data = await _guarded('searchAddress', {
      'query': query,
      'lang': lang,
      'mode': mode.name,
      if (biasLat != null && biasLng != null) ...{
        'lat': biasLat,
        'lng': biasLng,
      },
      if (sessionToken != null) 'sessionToken': sessionToken,
    });
    final list = data['suggestions'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => PlaceSuggestion.fromMap(Map<String, dynamic>.from(m)))
        .where((s) => s.primary.isNotEmpty)
        .toList();
  }

  @override
  Future<PickedPlace?> resolve(String placeId, {String? sessionToken}) async {
    final data = await _guarded('resolvePlace', {
      'placeId': placeId,
      if (sessionToken != null) 'sessionToken': sessionToken,
    });
    final p = data['place'];
    return p is Map ? PickedPlace.fromMap(Map<String, dynamic>.from(p)) : null;
  }

  @override
  Future<PickedPlace?> reverse(double lat, double lng,
      {required String lang}) async {
    final data =
        await _guarded('reverseGeocode', {'lat': lat, 'lng': lng, 'lang': lang});
    final p = data['place'];
    return p is Map ? PickedPlace.fromMap(Map<String, dynamic>.from(p)) : null;
  }
}
