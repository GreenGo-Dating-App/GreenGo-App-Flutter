import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  /// Returns the `showOnMap` setting for [userId].
  Future<bool> getUserMapSettings(String userId);

  /// Updates the `showOnMap` field on the user's profile.
  Future<void> updateShowOnMap({
    required String userId,
    required bool showOnMap,
  });
}

class ExploreMapRemoteDataSourceImpl implements ExploreMapRemoteDataSource {
  final FirebaseFirestore firestore;

  ExploreMapRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<MapUserModel>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
    List<String> currentUserLanguages = const [],
  }) async {
    try {
      // Firestore doesn't support native geo-queries, so we fetch profiles
      // with showOnMap=true and filter by distance client-side.
      // For production scale, consider using GeoFlutterFire or geohashes.
      final querySnapshot = await firestore
          .collection('profiles')
          .where('showOnMap', isEqualTo: true)
          .limit(500)
          .get();

      final List<MapUserModel> nearbyUsers = [];

      for (final doc in querySnapshot.docs) {
        // Skip the current user
        if (doc.id == currentUserId) continue;

        final data = doc.data();

        // Skip incognito users
        final isIncognito = data['isIncognito'] as bool? ?? false;
        if (isIncognito) {
          final incognitoExpiryTs = data['incognitoExpiry'] as Timestamp?;
          if (incognitoExpiryTs == null ||
              incognitoExpiryTs.toDate().isAfter(DateTime.now())) {
            continue;
          }
        }

        // Skip inactive accounts
        final accountStatus = data['accountStatus'] as String? ?? 'active';
        if (accountStatus != 'active') continue;

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
        if (distance > radiusKm) continue;

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

        nearbyUsers.add(mapUser.copyWith(
          distanceKm: double.parse(distance.toStringAsFixed(1)),
          languagesShared: shared,
          matchPercentage: matchPct,
        ));
      }

      // Sort by distance (closest first)
      nearbyUsers.sort((a, b) =>
          (a.distanceKm ?? double.infinity)
              .compareTo(b.distanceKm ?? double.infinity));

      debugPrint(
          '[ExploreMap] Found ${nearbyUsers.length} nearby users within ${radiusKm}km');

      return nearbyUsers;
    } catch (e) {
      debugPrint('[ExploreMap] Error fetching nearby users: $e');
      rethrow;
    }
  }

  @override
  Future<bool> getUserMapSettings(String userId) async {
    final doc = await firestore.collection('profiles').doc(userId).get();
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
