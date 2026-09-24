import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/cache/last_result_cache.dart';
import '../../../../core/services/location_share_service.dart';
import '../../../../core/utils/geo_query.dart';

/// Where the Events tab (and its prefetch) centres its nearest-first queries.
///
/// A fresh GPS fix takes seconds, so nothing waits for one. [quick] answers
/// immediately from, in order: the anchor already used this session, the OS's
/// last known fix, the anchor persisted last session, then the profile's stored
/// location (local cache first). Screens render against that and call
/// [remember] when a fresh fix arrives; they re-query only when it [movedFar].
///
/// The prefetch and the tab share this, so both compute the SAME query and the
/// tab can adopt what the prefetch downloaded.
class EventsLocation {
  EventsLocation._();

  static const String _anchorKey = 'events_anchor_v1';

  /// Past this, results anchored elsewhere are no longer "nearby" enough.
  static const double refreshDistanceM = 5000;

  static ({double lat, double lng})? _current;

  /// The anchor in use this session, if resolved (synchronous).
  static ({double lat, double lng})? get current => _current;

  static Future<({double lat, double lng})?>? _resolving;

  /// Bumped by [reset] so a resolve started for the previous account can't
  /// install its anchor afterwards.
  static int _epoch = 0;

  /// Best instant anchor, or null when nothing at all is known. Never prompts
  /// for permission, never throws.
  static Future<({double lat, double lng})?> quick(String userId) {
    if (_current != null) return Future.value(_current);
    return _resolving ??=
        _resolve(userId).whenComplete(() => _resolving = null);
  }

  static Future<({double lat, double lng})?> _resolve(String userId) async {
    final epoch = _epoch;
    ({double lat, double lng})? adopt(({double lat, double lng})? p) {
      if (epoch != _epoch) return null;
      return _current ??= p;
    }

    final last = await const LocationShareService().getLastKnownPositionFast();
    if (last != null) return adopt((lat: last.latitude, lng: last.longitude));
    final saved = await LastResultCache.loadJson(_anchorKey,
        maxAge: const Duration(days: 30));
    if (saved is Map) {
      final la = (saved['lat'] as num?)?.toDouble();
      final ln = (saved['lng'] as num?)?.toDouble();
      if (la != null && ln != null) return adopt((lat: la, lng: ln));
    }
    final profile = await _profileLocation(userId);
    return profile != null
        ? adopt(profile)
        : (epoch == _epoch ? _current : null);
  }

  /// profiles/{uid}.location, from the local cache when possible.
  static Future<({double lat, double lng})?> _profileLocation(
      String userId) async {
    if (userId.isEmpty) return null;
    final ref = FirebaseFirestore.instance.collection('profiles').doc(userId);
    DocumentSnapshot<Map<String, dynamic>>? snap;
    try {
      snap = await ref.get(const GetOptions(source: Source.cache));
    } catch (_) {/* not cached */}
    try {
      if (snap == null || !snap.exists) {
        snap = await ref.get().timeout(const Duration(seconds: 4));
      }
    } catch (_) {
      return null;
    }
    final loc = snap.data()?['location'];
    if (loc is! Map) return null;
    final la = (loc['latitude'] as num?)?.toDouble();
    final ln = (loc['longitude'] as num?)?.toDouble();
    // 0,0 is the model's "unset" default, not a real location.
    if (la == null || ln == null || (la == 0 && ln == 0)) return null;
    return (lat: la, lng: ln);
  }

  /// Adopt a fresh fix as the anchor (and persist it for the next launch).
  static void remember(double lat, double lng) {
    _current = (lat: lat, lng: lng);
    unawaited(LastResultCache.saveJson(_anchorKey, {'lat': lat, 'lng': lng}));
  }

  /// Forget the session anchor (sign-out / account switch). The persisted one
  /// is per-user in LastResultCache already.
  static void reset() {
    _epoch++;
    _current = null;
    _resolving = null;
  }

  /// True when [b] is far enough from [a] that nearby results must reload.
  static bool movedFar(({double lat, double lng})? a, double lat, double lng) =>
      a == null ||
      GeoQuery.distanceMeters(a.lat, a.lng, lat, lng) > refreshDistanceM;
}
