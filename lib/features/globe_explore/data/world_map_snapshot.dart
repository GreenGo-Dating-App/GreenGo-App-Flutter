import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/entities/globe_user.dart';

/// Server-built pins of the network ("My world") map (owner decision
/// 2026-10-20: "updated with batches, not in real time; every hour data is
/// refreshed and must be able to have quick fetch from server").
///
/// `world_map_snapshots/{uid}` is built by the functions
/// (src/globe/worldMapSnapshot.ts) with the same rules as
/// [assembleNetworkPins] - parity pinned by the shared fixture
/// functions/__tests__/fixtures/world_map_pin_cases.json - and refreshed
/// hourly for users who open the map. An open is ONE doc read (+ chunk docs
/// for a very large network); only a missing / older than 1 h snapshot goes
/// through the `getWorldMapSnapshot` callable, which builds it once.
///
/// No "updated ..." text is shown anywhere (owner: "Do not show any message
/// on the my world map").
const String kWorldMapSnapshots = 'world_map_snapshots';
const int kWorldMapSnapshotSchema = 1;

/// The callable (`getWorldMapSnapshot`); returns its JSON result.
typedef WorldMapSnapshotCall = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> payload);

Future<Map<String, dynamic>> _callServer(Map<String, dynamic> payload) async {
  final res = await FirebaseFunctions.instance
      .httpsCallable('getWorldMapSnapshot',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 45)))
      .call<Object?>(payload);
  final data = deepStringKeys(res.data);
  return data is Map<String, dynamic> ? data : const {};
}

/// Callable results arrive as `Map<Object?, Object?>`; JSON-like copy with
/// string keys.
Object? deepStringKeys(Object? v) {
  if (v is Map) {
    return <String, dynamic>{
      for (final e in v.entries) '${e.key}': deepStringKeys(e.value),
    };
  }
  if (v is List) return [for (final x in v) deepStringKeys(x)];
  return v;
}

const Map<String, GlobeRelation> _badges = {
  'following': GlobeRelation.following,
  'follower': GlobeRelation.follower,
  'chat': GlobeRelation.chatted,
};

GlobeDiscoverability _disc(Object? v) => switch (v) {
      'exact' => GlobeDiscoverability.exact,
      'approximate' => GlobeDiscoverability.approximate,
      _ => GlobeDiscoverability.country,
    };

/// One stored pin as a map pin, or null when it is unusable (no id, bad
/// coordinates, no known relation).
GlobeUser? parseWorldMapPin(Object? raw) {
  if (raw is! Map) return null;
  final id = raw['id'];
  final lat = raw['lat'], lng = raw['lng'];
  if (id is! String || id.isEmpty) return null;
  if (lat is! num || lng is! num) return null;
  if (!lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) {
    return null;
  }
  final badges = raw['badges'];
  final relations = <GlobeRelation>{
    if (badges is List)
      for (final b in badges)
        if (_badges[b] != null) _badges[b]!,
  };
  if (relations.isEmpty) return null;
  String text(Object? v) => v is String && v.isNotEmpty ? v : 'Unknown';
  final photo = raw['photo'];
  final isBusiness = raw['kind'] == 'business';
  final traveler = raw['traveler'];
  final travelerCountry =
      traveler is Map && traveler['country'] is String ? traveler['country'] as String : null;
  return GlobeUser(
    userId: id,
    // i18n-ignore: data placeholder, shown localized by GlobeScreen
    displayName: raw['name'] is String ? raw['name'] as String : 'Unknown',
    photoUrl: photo is String && photo.isNotEmpty ? photo : null,
    pinLatitude: lat.toDouble(),
    pinLongitude: lng.toDouble(),
    country: text(raw['country']),
    city: text(raw['city']),
    pinType: isBusiness ? GlobePinType.business : GlobePinType.matched,
    isOnline: raw['isOnlineAtBuild'] == true,
    isTravelerActive: !isBusiness && travelerCountry != null,
    travelerCountry: isBusiness ? null : travelerCountry,
    discoverability:
        isBusiness ? GlobeDiscoverability.exact : _disc(raw['disc']),
    realCountryLatitude: travelerCountry != null && traveler is Map
        ? (traveler['homeLat'] as num?)?.toDouble()
        : null,
    realCountryLongitude: travelerCountry != null && traveler is Map
        ? (traveler['homeLng'] as num?)?.toDouble()
        : null,
    relations: Set.unmodifiable(relations),
    isBusiness: isBusiness,
  );
}

/// All usable pins of a snapshot, one per account.
List<GlobeUser> parseWorldMapPins(Object? pins) {
  if (pins is! List) return const [];
  final seen = <String>{};
  return [
    for (final p in pins)
      if (parseWorldMapPin(p) case final GlobeUser u when seen.add(u.userId)) u,
  ];
}

DateTime? _time(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  return null;
}

/// Loads the signed-in user's snapshot: the stored doc when it is fresh,
/// else the callable (which builds it). Throws when neither works - the map
/// then falls back to the client assembler.
class WorldMapSnapshotSource {
  WorldMapSnapshotSource({
    required this.firestore,
    WorldMapSnapshotCall? call,
    DateTime Function()? now,
  })  : _call = call ?? _callServer,
        _now = now ?? DateTime.now;

  final FirebaseFirestore firestore;
  final WorldMapSnapshotCall _call;
  final DateTime Function() _now;

  /// Older than this -> rebuilt through the callable.
  static const Duration ttl = Duration(hours: 6); // = server SNAPSHOT_TTL_MS (6 h)

  /// The "opened the map" marker that keeps the hourly batch going is
  /// refreshed (in the background) when older than this.
  static const Duration markerEvery = Duration(days: 1);

  bool isFresh(Map<String, dynamic> doc) {
    if (doc['schema'] != kWorldMapSnapshotSchema) return false;
    final builtAt = _time(doc['builtAt']);
    return builtAt != null && _now().difference(builtAt) < ttl;
  }

  bool _markerStale(Map<String, dynamic> doc) {
    final last = _time(doc['lastOpenedAt']);
    return doc['active'] != true ||
        last == null ||
        _now().difference(last) >= markerEvery;
  }

  /// Pins of a stored doc (+ its chunks), or null when a chunk belongs to
  /// another build (a rebuild raced this read).
  Future<List<Object?>?> _storedPins(
      String userId, Map<String, dynamic> doc) async {
    final n = doc['chunkCount'];
    if (n is! int || n <= 0) {
      final pins = doc['pins'];
      return pins is List ? pins : const [];
    }
    final ref = firestore.collection(kWorldMapSnapshots).doc(userId);
    final chunks = await Future.wait([
      for (var i = 0; i < n; i++) ref.collection('chunks').doc('$i').get(),
    ]);
    final out = <Object?>[];
    for (final c in chunks) {
      final d = c.data();
      if (d == null || d['buildId'] != doc['buildId']) return null;
      final pins = d['pins'];
      if (pins is List) out.addAll(pins);
    }
    return out;
  }

  Future<List<GlobeUser>> load(String userId) async {
    Map<String, dynamic>? doc;
    try {
      doc = (await firestore.collection(kWorldMapSnapshots).doc(userId).get())
          .data();
    } catch (_) {
      doc = null; // offline / not deployed yet: the callable decides
    }
    if (doc != null && isFresh(doc)) {
      final pins = await _storedPins(userId, doc).catchError((_) => null);
      if (pins != null) {
        if (_markerStale(doc)) {
          unawaited(_call(const {'touchOnly': true})
              .then((_) {}, onError: (_) {}));
        }
        return parseWorldMapPins(pins);
      }
    }
    try {
      final res = await _call(const {});
      if (res['pins'] is! List) throw StateError('no pins in snapshot result');
      return parseWorldMapPins(res['pins']);
    } catch (_) {
      // An older snapshot still beats rebuilding the network on the device.
      if (doc != null && doc['schema'] == kWorldMapSnapshotSchema) {
        final pins = await _storedPins(userId, doc).catchError((_) => null);
        if (pins != null) return parseWorldMapPins(pins);
      }
      rethrow;
    }
  }
}
