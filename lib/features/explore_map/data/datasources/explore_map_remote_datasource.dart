import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/cache/last_result_cache.dart';
import '../../../../core/utils/geo_query.dart';
import '../models/map_user_model.dart';

/// Remote data source for the Explore Map feature.
///
/// Queries Firestore for profiles with `showOnMap == true`,
/// snaps coordinates to 3 decimal places (~110m) for privacy,
/// and calculates distances using the Haversine formula.
abstract class ExploreMapRemoteDataSource {
  /// Fetch nearby users within [radiusKm] of ([latitude], [longitude]).
  Future<List<MapUserModel>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
    List<String> currentUserLanguages,
  });

  /// The users last shown (saved after each server load), rebuilt from the
  /// LOCAL Firestore cache only, with the same filters. Empty when nothing
  /// usable is cached. Never throws.
  Future<List<MapUserModel>> getCachedNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
    List<String> currentUserLanguages,
  });

  /// Returns the `showOnMap` setting for [userId].
  Future<bool> getUserMapSettings(String userId);

  /// Updates the `showOnMap` field on the user's profile.
  Future<void> updateShowOnMap({
    required String userId,
    required bool showOnMap,
  });
}

class ExploreMapRemoteDataSourceImpl implements ExploreMapRemoteDataSource {

  ExploreMapRemoteDataSourceImpl({required this.firestore});
  final FirebaseFirestore firestore;

  static const String _cacheKey = 'explore_map_users_v1';

  /// Per geohash-range read size (up to 9 ranges, in parallel).
  static const int _geoPerRange = 100;

  /// Below this many geo hits the area is treated as thin (or not geohashed
  /// yet) and the country / legacy queries pad it.
  static const int _geoEnough = 30;

  /// Above this radius a geohash scan is no better than the fallbacks.
  static const double _geoMaxRadiusKm = 2000;

  /// Viewer's profile doc, shared by [getUserMapSettings] and the country
  /// fallback of [getNearbyUsers] (they run in parallel on load).
  (String, DateTime, Future<DocumentSnapshot<Map<String, dynamic>>>)? _viewer;

  Future<DocumentSnapshot<Map<String, dynamic>>> _viewerDoc(String userId) {
    final v = _viewer;
    if (v != null &&
        v.$1 == userId &&
        DateTime.now().difference(v.$2) < const Duration(seconds: 30)) {
      return v.$3;
    }
    final f = firestore.collection('profiles').doc(userId).get();
    _viewer = (userId, DateTime.now(), f);
    // A failed read must not stay memoised.
    f.then<void>((_) {}, onError: (Object _) {
      if (identical(_viewer?.$3, f)) _viewer = null;
    }).ignore();
    return f;
  }

  /// LOCATION-FIRST candidate docs:
  ///  1. `geohash` ranges around the viewer (GeoQuery.queryBounds), with
  ///     `showOnMap == true` server-side (index profiles(showOnMap, geohash));
  ///     if that is rejected, the same ranges without it (single-field
  ///     index) and showOnMap checked here;
  ///  2. when that is thin (profiles not geohashed yet / sparse area):
  ///     `showOnMap == true && location.country == viewer country`, limit 200;
  ///  3. no country known or that failed: the previous worldwide
  ///     `showOnMap == true` limit 500 read.
  /// The radius / visibility filters below run on every path.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _candidateDocs({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
  }) async {
    final profiles = firestore.collection('profiles');
    final seen = <String>{};
    final out = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    void addAll(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
      for (final d in docs) {
        if (d.data()['showOnMap'] != true) continue;
        if (seen.add(d.id)) out.add(d);
      }
    }

    final validCenter = latitude.isFinite &&
        longitude.isFinite &&
        !(latitude == 0 && longitude == 0);
    if (validCenter && radiusKm > 0 && radiusKm <= _geoMaxRadiusKm) {
      final bounds = GeoQuery.queryBounds(latitude, longitude, radiusKm * 1000);
      Future<List<QuerySnapshot<Map<String, dynamic>>>> run(
              bool withFlag) =>
          Future.wait(bounds.map((b) {
            Query<Map<String, dynamic>> q = profiles;
            if (withFlag) q = q.where('showOnMap', isEqualTo: true);
            return q
                .orderBy('geohash')
                .startAt([b[0]])
                .endAt([b[1]])
                .limit(_geoPerRange)
                .get();
          }));
      try {
        List<QuerySnapshot<Map<String, dynamic>>> snaps;
        try {
          snaps = await run(true);
        } catch (_) {
          snaps = await run(false); // composite index not deployed yet
        }
        for (final s in snaps) {
          addAll(s.docs);
        }
      } catch (e) {
        debugPrint('[ExploreMap] Geo query unavailable: $e');
      }
      if (out.length >= _geoEnough) return out;
    }

    String? country;
    try {
      final loc = (await _viewerDoc(currentUserId)).data()?['location'];
      if (loc is Map && loc['country'] is String) {
        final c = (loc['country'] as String).trim();
        if (c.isNotEmpty && c != 'Unknown') country = c;
      }
    } catch (_) {}

    if (country != null) {
      try {
        final snap = await profiles
            .where('showOnMap', isEqualTo: true)
            .where('location.country', isEqualTo: country)
            .limit(200)
            .get();
        addAll(snap.docs);
        return out;
      } catch (e) {
        debugPrint('[ExploreMap] Country query failed: $e');
      }
    }

    final snap = await profiles
        .where('showOnMap', isEqualTo: true)
        .limit(500)
        .get();
    addAll(snap.docs);
    return out;
  }

  /// The visible user for [doc], or null when filtered out (self, incognito,
  /// inactive, outside the radius).
  MapUserModel? _toMapUser(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
    required List<String> currentUserLanguages,
  }) {
    // Skip the current user
    if (doc.id == currentUserId) return null;

    final data = doc.data();
    if (data == null) return null;
    if (data['showOnMap'] != true) return null;

    // Skip incognito users
    final isIncognito = data['isIncognito'] as bool? ?? false;
    if (isIncognito) {
      final incognitoExpiryTs = data['incognitoExpiry'] as Timestamp?;
      if (incognitoExpiryTs == null ||
          incognitoExpiryTs.toDate().isAfter(DateTime.now())) {
        return null;
      }
    }

    // Skip inactive accounts
    final accountStatus = data['accountStatus'] as String? ?? 'active';
    if (accountStatus != 'active') return null;

    // Parse the user model from Firestore
    final mapUser = MapUserModel.fromFirestore(doc);

    // Calculate distance using Haversine
    final distance = _haversineDistance(
      latitude,
      longitude,
      mapUser.approximateLatitude,
      mapUser.approximateLongitude,
    );

    // Filter by radius
    if (distance > radiusKm) return null;

    // Calculate shared languages
    final userLanguages = data['languages'] != null
        ? List<String>.from(data['languages'] as List)
        : <String>[];
    final shared = userLanguages
        .where((lang) => currentUserLanguages.contains(lang))
        .toList();

    // Calculate a simple match percentage based on shared languages
    // and other factors. This is a basic implementation.
    final matchPct = _calculateMatchPercentage(
      sharedLanguages: shared,
      totalUserLanguages: currentUserLanguages.length,
      isOnline: mapUser.isOnline,
    );

    return mapUser.copyWith(
      distanceKm: double.parse(distance.toStringAsFixed(1)),
      languagesShared: shared,
      matchPercentage: matchPct,
    );
  }

  List<MapUserModel> _build(
    Iterable<DocumentSnapshot<Map<String, dynamic>>> docs, {
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
    required List<String> currentUserLanguages,
  }) {
    final users = <MapUserModel>[];
    for (final doc in docs) {
      try {
        final u = _toMapUser(doc,
            latitude: latitude,
            longitude: longitude,
            radiusKm: radiusKm,
            currentUserId: currentUserId,
            currentUserLanguages: currentUserLanguages);
        if (u != null) users.add(u);
      } catch (_) {
        // Skip malformed profiles.
      }
    }
    // Sort by distance (closest first)
    users.sort((a, b) => (a.distanceKm ?? double.infinity)
        .compareTo(b.distanceKm ?? double.infinity));
    return users;
  }

  @override
  Future<List<MapUserModel>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
    List<String> currentUserLanguages = const [],
  }) async {
    try {
      final docs = await _candidateDocs(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        currentUserId: currentUserId,
      );
      final nearbyUsers = _build(docs,
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          currentUserId: currentUserId,
          currentUserLanguages: currentUserLanguages);

      debugPrint(
          '[ExploreMap] Found ${nearbyUsers.length} nearby users within ${radiusKm}km');
      unawaited(LastResultCache.saveIds(
          _cacheKey, nearbyUsers.map((u) => u.userId)));

      return nearbyUsers;
    } catch (e) {
      debugPrint('[ExploreMap] Error fetching nearby users: $e');
      rethrow;
    }
  }

  @override
  Future<List<MapUserModel>> getCachedNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
    List<String> currentUserLanguages = const [],
  }) async {
    try {
      final docs = await LastResultCache.loadDocs(
          _cacheKey, firestore.collection('profiles'));
      if (docs.isEmpty) return const [];
      return _build(docs,
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          currentUserId: currentUserId,
          currentUserLanguages: currentUserLanguages);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> getUserMapSettings(String userId) async {
    final doc = await _viewerDoc(userId);
    if (!doc.exists) return true; // Default to visible
    return doc.data()?['showOnMap'] as bool? ?? true;
  }

  @override
  Future<void> updateShowOnMap({
    required String userId,
    required bool showOnMap,
  }) async {
    await firestore.collection('profiles').doc(userId).update({
      'showOnMap': showOnMap,
    });
    _viewer = null; // the memoised doc is now stale
  }

  /// Haversine formula to calculate distance between two points in km.
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Simple match percentage based on shared languages and online status.
  int _calculateMatchPercentage({
    required List<String> sharedLanguages,
    required int totalUserLanguages,
    required bool isOnline,
  }) {
    if (totalUserLanguages == 0) return 50; // Default when no languages set

    // Base score from shared languages (0-70%)
    final languageScore =
        (sharedLanguages.length / totalUserLanguages * 70).round().clamp(0, 70);

    // Online bonus (up to 15%)
    final onlineBonus = isOnline ? 15 : 0;

    // Base compatibility (15%)
    const baseScore = 15;

    return (baseScore + languageScore + onlineBonus).clamp(0, 100);
  }
}
