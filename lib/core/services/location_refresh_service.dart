import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/profile/data/models/profile_model.dart'
    show normalizeCountryName;
import '../../features/passport/data/services/passport_service.dart';
import '../../features/profile/data/profile_geohash.dart';
import 'location_change.dart';
import 'own_profile_store.dart';
import 'web_location_fallback.dart';

/// A resolved place for a coordinate (empty strings when unknown).
typedef ResolvedPlace = ({String city, String country});

/// Silently refreshes the current user's GPS location in Firestore.
///
/// Used:
///  * once per session right after sign-in / app open
///    ([startSessionRefresh]; Explore waits for it, bounded, via
///    [awaitSessionRefresh] so its first load uses the new position),
///  * on pull-to-refresh in Discovery and Explore.
///
/// The profile is only written when the position changed meaningfully (see
/// [isMeaningfulLocationChange]); `profiles.geohash` is written together with
/// the coordinates so it stays in step with the discoverable location.
class LocationRefreshService {
  LocationRefreshService({
    FirebaseFirestore? firestore,
    @visibleForTesting Future<Position?> Function(Duration timeout)? positionProvider,
    @visibleForTesting
    Future<ResolvedPlace?> Function(double lat, double lng)? reverseGeocoder,
    @visibleForTesting Future<Map<String, dynamic>?> Function(String uid)? profileReader,
  })  : _firestoreOverride = firestore,
        _positionProvider = positionProvider,
        _reverseGeocoder = reverseGeocoder,
        _profileReader = profileReader;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  final Future<Position?> Function(Duration timeout)? _positionProvider;
  final Future<ResolvedPlace?> Function(double lat, double lng)? _reverseGeocoder;
  final Future<Map<String, dynamic>?> Function(String uid)? _profileReader;

  // ── Shared (static) state: one refresh in flight per user, app-wide ──────
  static final Map<String, Future<LocationRefreshOutcome>> _inFlight = {};
  static final Map<String, (DateTime, LocationRefreshOutcome)> _last = {};

  // Session refresh (sign-in / app open).
  static String? _sessionUid;
  static Future<LocationRefreshOutcome>? _session;
  static DateTime? _sessionStartedAt;

  /// The browser location prompt is shown at most once per app session.
  static bool _promptedThisSession = false;
  static const String _kPromptDeclinedKey = 'location_auto_prompt_declined_v1';

  /// How long the first data-dependent page may wait (from the moment the
  /// session refresh started) for the new position. Web needs room for the
  /// browser permission prompt; mobile never blocks the first paint (the
  /// position lands in the background and Explore's listener reloads).
  static Duration get defaultSessionBudget =>
      kIsWeb ? const Duration(milliseconds: 4500) : Duration.zero;

  /// Starts the once-per-session location refresh for [userId] (idempotent).
  /// On web it may show the browser's location prompt ONCE per session, and
  /// never again after the user declined it.
  static Future<LocationRefreshOutcome> startSessionRefresh(String userId) {
    if (userId.isEmpty) return Future.value(LocationRefreshOutcome.skipped);
    if (_sessionUid == userId && _session != null) return _session!;
    _sessionUid = userId;
    _sessionStartedAt = DateTime.now();
    final run = LocationRefreshService().refreshIfAllowed(
      userId,
      allowPrompt: kIsWeb,
      fixTimeout: const Duration(seconds: 8),
    );
    _session = run;
    return run;
  }

  /// Waits for the session refresh of [userId], at most until [budget]
  /// (default [defaultSessionBudget]) has passed since it STARTED. Returns at
  /// once when no session refresh is running for [userId]. Never throws; the
  /// refresh keeps running after a timeout.
  static Future<void> awaitSessionRefresh(String userId,
      {Duration? budget}) async {
    final session = _session;
    final started = _sessionStartedAt;
    if (session == null || started == null || _sessionUid != userId) return;
    final remaining =
        (budget ?? defaultSessionBudget) - DateTime.now().difference(started);
    if (remaining <= Duration.zero) return;
    try {
      await session.timeout(remaining);
    } catch (_) {/* bounded wait: carry on with the stored location */}
  }

  /// Forget the per-session state (sign-out).
  static void resetSession() {
    _sessionUid = null;
    _session = null;
    _sessionStartedAt = null;
    _promptedThisSession = false;
    _inFlight.clear();
    _last.clear();
  }

  /// Attempt to refresh the user's location. Never throws: any failure (no
  /// permission, GPS off, timeout, ...) yields [LocationRefreshOutcome.skipped].
  ///
  /// When traveler mode is active ([isTravelerActive], or read from the
  /// stored profile when null) the GPS refresh is skipped entirely — the
  /// travel location is what people discover; the real `location` is
  /// refreshed once traveler mode ends.
  ///
  /// [allowPrompt]: when permission has not been decided yet, let the
  /// platform ask (used on web at session start only; never after a decline).
  /// [maxAge]: reuse a result younger than this instead of a new GPS read.
  /// Concurrent calls for the same user share one refresh.
  Future<LocationRefreshOutcome> refreshIfAllowed(
    String userId, {
    bool? isTravelerActive,
    bool allowPrompt = false,
    Duration fixTimeout = const Duration(seconds: 12),
    Duration? maxAge,
  }) {
    if (userId.isEmpty) return Future.value(LocationRefreshOutcome.skipped);
    final running = _inFlight[userId];
    if (running != null) return running;
    final last = _last[userId];
    if (maxAge != null &&
        last != null &&
        DateTime.now().difference(last.$1) < maxAge) {
      return Future.value(last.$2);
    }
    final run = _refresh(
      userId,
      isTravelerActive: isTravelerActive,
      allowPrompt: allowPrompt,
      fixTimeout: fixTimeout,
    );
    _inFlight[userId] = run;
    run.then((outcome) {
      _last[userId] = (DateTime.now(), outcome);
    }).whenComplete(() {
      if (identical(_inFlight[userId], run)) _inFlight.remove(userId);
    });
    return run;
  }

  Future<LocationRefreshOutcome> _refresh(
    String userId, {
    required bool? isTravelerActive,
    required bool allowPrompt,
    required Duration fixTimeout,
  }) async {
    try {
      final raw = await _storedProfile(userId);
      final travelling = isTravelerActive ?? _travelerActiveIn(raw);
      if (travelling) {
        debugPrint('[LocationRefresh] Skipped — traveler mode active');
        return LocationRefreshOutcome.skipped;
      }

      final position = await (_positionProvider?.call(fixTimeout) ??
          _readPosition(allowPrompt: allowPrompt, fixTimeout: fixTimeout));
      if (position == null) {
        debugPrint('[LocationRefresh] No position available');
        return LocationRefreshOutcome.skipped;
      }

      final stored = LocationPoint.fromMap(raw?['location'] as Map?);
      final fix =
          LocationPoint(lat: position.latitude, lng: position.longitude);
      // Same place (within the threshold): no reverse geocode, no write, no
      // reload anywhere.
      if (!isMeaningfulLocationChange(stored, fix)) {
        // Still repair a missing / stale discovery geohash (older profiles).
        final hash = raw == null ? null : profileGeohash(raw);
        if (hash != null && raw![kProfileGeohashField] != hash) {
          await _firestore
              .collection('profiles')
              .doc(userId)
              .update({kProfileGeohashField: hash});
        }
        debugPrint('[LocationRefresh] Unchanged for $userId');
        return LocationRefreshOutcome.unchanged;
      }

      // Reverse-geocode to get city + country (best effort).
      ResolvedPlace? place;
      try {
        place = await (_reverseGeocoder ?? _reverseGeocode)(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 6));
      } catch (_) {
        // Geocoding failed — still update lat/lng
      }
      final city = place?.city ?? '';
      final country = place?.country ?? '';
      final displayAddress = city.isNotEmpty ? '$city, $country' : country;

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
      // Keep the discovery geohash in step with the home location, unless an
      // active travel location is what people discover this profile at (or
      // the profile is unknown: the next profile save fixes it).
      if (raw != null) {
        final merged = <String, dynamic>{
          ...raw,
          'location': {
            ...((raw['location'] as Map?)?.cast<String, dynamic>() ?? const {}),
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        };
        final hash = profileGeohash(merged);
        if (hash != null) update[kProfileGeohashField] = hash;
      }

      await _firestore.collection('profiles').doc(userId).update(update);
      // A real (GPS) location — never Traveler mode — so it counts toward the
      // countries visited shown on Explore.
      if (country.isNotEmpty) {
        unawaited(PassportService(firestore: _firestore)
            .recordVisitedCountry(userId, country));
      }
      debugPrint('[LocationRefresh] Updated $userId → $city, $country '
          '(${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)})');
      return LocationRefreshOutcome.changed;
    } catch (e) {
      debugPrint('[LocationRefresh] Skipped: $e');
      return LocationRefreshOutcome.skipped;
    }
  }

  /// The stored own profile (raw map), from [OwnProfileStore] when it holds
  /// this user, else one shared read. Null when unknown.
  Future<Map<String, dynamic>?> _storedProfile(String userId) async {
    final reader = _profileReader;
    if (reader != null) return reader(userId);
    final store = OwnProfileStore.instance;
    if (store.uid != userId || store.raw == null) {
      try {
        await store.current(userId).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
    return store.uid == userId ? store.raw : null;
  }

  static bool _travelerActiveIn(Map<String, dynamic>? raw) {
    if (raw == null || raw['isTraveler'] != true) return false;
    final expiryRaw = raw['travelerExpiry'];
    final expiry = expiryRaw is Timestamp
        ? expiryRaw.toDate()
        : expiryRaw is DateTime
            ? expiryRaw
            : null;
    return expiry != null && expiry.isAfter(DateTime.now());
  }

  /// Device / browser position, or null. Prompts only when [allowPrompt] and
  /// the permission is still undecided, once per session, never after a
  /// decline.
  Future<Position?> _readPosition({
    required bool allowPrompt,
    required Duration fixTimeout,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) return null;
    var prompting = false;
    if (permission == LocationPermission.denied) {
      // On web `denied` means "not asked yet" (the browser's `prompt` state);
      // an explicit block is `deniedForever`.
      if (!allowPrompt || _promptedThisSession) return null;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kPromptDeclinedKey) ?? false) return null;
      _promptedThisSession = true;
      prompting = true;
      if (!kIsWeb) {
        final asked = await Geolocator.requestPermission();
        if (asked == LocationPermission.denied ||
            asked == LocationPermission.deniedForever) {
          await prefs.setBool(_kPromptDeclinedKey, true);
          return null;
        }
        prompting = false;
      }
    }

    // A fresh fix is preferred, but indoors or with a weak signal it can
    // take longer than a refresh should wait. Falling back to the last known
    // position (mobile only — web has none) keeps the coordinates moving.
    try {
      final fresh = Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        // On web the browser starts this clock only after the user answered
        // the prompt, so a pending prompt is not cut short.
        timeLimit: fixTimeout,
      );
      // While the browser prompt is open the Dart side must not time out:
      // callers bound their own wait and the refresh lands later.
      return prompting
          ? await fresh
          : await fresh.timeout(fixTimeout + const Duration(seconds: 2));
    } on PermissionDeniedException {
      if (prompting) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_kPromptDeclinedKey, true);
        } catch (_) {}
      }
      return null;
    } catch (_) {
      if (kIsWeb) return null;
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          debugPrint('[LocationRefresh] Fresh fix timed out — using last known');
        }
        return last;
      } catch (_) {
        return null;
      }
    }
  }

  /// City + country for a coordinate. The `geocoding` plugin has no web
  /// implementation, so web uses [WebLocationFallback] (Nominatim) — called
  /// only after a meaningful move, so the volume stays tiny.
  static Future<ResolvedPlace?> _reverseGeocode(double lat, double lng) async {
    if (kIsWeb) {
      final loc = await WebLocationFallback.reverseGeocode(lat, lng);
      if (loc == null) return null;
      return (city: loc.city, country: loc.country);
    }
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return null;
    final place = placemarks.first;
    // geocoding returns '' (not null) for missing fields: take the first
    // non-empty one.
    final city = [
      place.locality,
      place.subLocality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ].firstWhere((s) => s != null && s.trim().isNotEmpty, orElse: () => '')!;
    return (city: city, country: normalizeCountryName(place.country ?? ''));
  }
}
