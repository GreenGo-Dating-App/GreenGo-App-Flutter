import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/external_event.dart';

/// Reads cached third-party experiences from `external_events` (populated by the
/// scheduled ingester Cloud Functions). Cache-first via Firestore persistence,
/// so it's instant on repeat opens and scales to millions of users (no per-user
/// API calls). Falls back to a small built-in preview while empty.
///
/// `source` selects the provider: 'viator' (Experiences) or 'tiqets'
/// (Attractions). When [userLat]/[userLng] are provided, results are ordered by
/// distance from the user (nearest first) instead of rating.
class ExternalEventsDataSource {
  ExternalEventsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  List<ExternalEvent> _samplesFor(String source) {
    final s = ExternalEvent.samples.where((e) => e.source == source).toList();
    return s.isNotEmpty ? s : ExternalEvent.samples;
  }

  static double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void _sortByDistance(List<ExternalEvent> list, double lat, double lng) {
    list.sort((a, b) {
      final ad = (a.lat != null && a.lng != null)
          ? _distanceKm(lat, lng, a.lat!, a.lng!)
          : double.infinity;
      final bd = (b.lat != null && b.lng != null)
          ? _distanceKm(lat, lng, b.lat!, b.lng!)
          : double.infinity;
      return ad.compareTo(bd);
    });
  }

  /// One page for infinite scroll. Ordered by rating (or distance if location
  /// given), filtered by [source].
  Future<({List<ExternalEvent> items, DocumentSnapshot<Map<String, dynamic>>? cursor})>
      getExperiencesPage({
    required String source,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
    double? userLat,
    double? userLng,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('external_events')
          .where('source', isEqualTo: source)
          .orderBy('rating', descending: true)
          .limit(limit);
      if (startAfter != null) query = query.startAfterDocument(startAfter);
      final snap = await query.get();
      final items = snap.docs.map(ExternalEvent.fromFirestore).toList();
      if (items.isEmpty && startAfter == null) {
        return (items: _samplesFor(source), cursor: null);
      }
      if (userLat != null && userLng != null) {
        _sortByDistance(items, userLat, userLng);
      }
      return (
        items: items,
        cursor: snap.docs.isNotEmpty ? snap.docs.last : null,
      );
    } catch (_) {
      if (startAfter == null) return (items: _samplesFor(source), cursor: null);
      return (items: <ExternalEvent>[], cursor: null);
    }
  }

  /// Items for [source] ordered by distance from the user (closest first).
  /// Loads a bounded pool then sorts locally by distance (items carry city
  /// coordinates). Bounded read; cache-first after first load.
  Future<List<ExternalEvent>> getNearbyExperiences({
    required String source,
    required double userLat,
    required double userLng,
    int limit = 300,
  }) async {
    try {
      final snap = await _firestore
          .collection('external_events')
          .where('source', isEqualTo: source)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();
      final items = snap.docs.map(ExternalEvent.fromFirestore).toList();
      if (items.isEmpty) return _samplesFor(source);
      _sortByDistance(items, userLat, userLng);
      return items;
    } catch (_) {
      return _samplesFor(source);
    }
  }

  /// Top [limit] by review count among those rated above 4.5 stars, for [source].
  Future<List<ExternalEvent>> getPopularExperiences({
    required String source,
    int limit = 20,
  }) async {
    try {
      final snap = await _firestore
          .collection('external_events')
          .where('source', isEqualTo: source)
          .orderBy('reviewCount', descending: true)
          .limit(limit * 4)
          .get();
      final items = snap.docs
          .map(ExternalEvent.fromFirestore)
          .where((e) => (e.rating ?? 0) > 4.5)
          .take(limit)
          .toList();
      if (items.isEmpty) {
        return _samplesFor(source).where((e) => (e.rating ?? 0) > 4.5).toList();
      }
      return items;
    } catch (_) {
      return _samplesFor(source).where((e) => (e.rating ?? 0) > 4.5).toList();
    }
  }
}
