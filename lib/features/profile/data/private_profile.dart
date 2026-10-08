import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/geo_query.dart';
import 'profile_geohash.dart';

/// Owner + admin only twin of `profiles/{uid}` (security audit C-07 / P1-4).
///
/// `profiles/{uid}` is readable by every signed-in user, so everything that
/// identifies or locates a person precisely lives here instead:
///  * exact coordinates: `location.{latitude,longitude}`,
///    `travelerLocation.{latitude,longitude}` and the 9-char `geohash`;
///  * `dateOfBirth`, `sexualOrientation`, `email`, `verificationPhone`,
///    `privatePhotoUrls`, `verificationPhotoPath` (a Storage PATH, never a
///    tokenised download URL).
///
/// The server keeps the PUBLIC profile's coarse fields in step (functions
/// src/profiles/privateProfile.ts, triggers on both documents):
///  * `geohash5` - precision-5 cell (~4.9 km), the nearest-first query key;
///  * `approxLocation` {lat, lng} - that cell's centre plus a stable per-user
///    offset of at most 1.5 km. What OTHER users' distances are computed from;
///  * `age` - integer, from the date of birth.
///
/// Old app versions still write the sensitive fields to the public profile;
/// the server mirrors those into this document. This app never writes them to
/// the public profile and never deletes them from it (the coordinator's strip
/// script does, after `minVersion`).
const String kPrivateProfilesCollection = 'profiles_private';
const String kGeohash5Field = 'geohash5';
const int kGeohash5Precision = 5;
const String kApproxLocationField = 'approxLocation';
const String kPublicAgeField = 'age';
const String kVerificationPhotoPathField = 'verificationPhotoPath';

/// In-memory marker on a raw profile map that already went through
/// [ownProfileView]. Never written to Firestore.
const String kOwnViewMarker = '__ownView';

/// Placeholder date of birth ProfileModel.fromJson uses when none is known.
final DateTime kUnknownDateOfBirth = DateTime(1990, 1, 1);

/// Top-level public fields that belong in `profiles_private` (plus the exact
/// coordinates inside `location` / `travelerLocation`).
const Set<String> kSensitiveTopLevelFields = {
  'dateOfBirth',
  'sexualOrientation',
  'email',
  'verificationPhone',
  'verificationPhotoUrl',
  'privatePhotoUrls',
  kProfileGeohashField,
};

/// The fields a client may write to `profiles_private` (mirrors the rules).
const Set<String> kOwnerWritablePrivateFields = {
  'location',
  'travelerLocation',
  kProfileGeohashField,
  'dateOfBirth',
  'sexualOrientation',
  'email',
  'verificationPhone',
  kVerificationPhotoPathField,
  'privatePhotoUrls',
  'updatedAt',
};

DocumentReference<Map<String, dynamic>> privateProfileRef(
        FirebaseFirestore firestore, String uid) =>
    firestore.collection(kPrivateProfilesCollection).doc(uid);

bool _valid(double? lat, double? lng) =>
    lat != null &&
    lng != null &&
    lat.isFinite &&
    lng.isFinite &&
    lat.abs() <= 90 &&
    lng.abs() <= 180 &&
    !(lat == 0 && lng == 0);

(double, double)? _coordsOf(Object? map, String latKey, String lngKey) {
  if (map is! Map) return null;
  final lat = (map[latKey] as num?)?.toDouble();
  final lng = (map[lngKey] as num?)?.toDouble();
  return _valid(lat, lng) ? (lat!, lng!) : null;
}

/// `approxLocation` of a public profile map, or null.
(double, double)? approxCoordsOf(Map<String, dynamic>? data) =>
    _coordsOf(data?[kApproxLocationField], 'lat', 'lng');

/// Valid `location` coordinates in a raw map, or null.
(double, double)? homeCoordsOf(Map<String, dynamic>? data) =>
    _coordsOf(data?['location'], 'latitude', 'longitude');

Map<String, dynamic> _withCoords(Object? base, double lat, double lng) => {
      ...(base is Map ? Map<String, dynamic>.from(base) : <String, dynamic>{}),
      'latitude': lat,
      'longitude': lng,
    };

/// How ANOTHER user's raw profile is shown: their exact coordinates (still
/// present on profiles written by old app versions) are replaced by the
/// coarse `approxLocation`, so every distance computed from the result is the
/// approximate one. Profiles the server has not processed yet (no
/// `approxLocation`) are returned as they are.
Map<String, dynamic> publicProfileView(Map<String, dynamic> data) {
  if (data[kOwnViewMarker] == true) return data;
  final approx = approxCoordsOf(data);
  if (approx == null) return data;
  final out = Map<String, dynamic>.from(data);
  out['location'] = _withCoords(data['location'], approx.$1, approx.$2);
  final travel = data['travelerLocation'];
  if (travel is Map) {
    out['travelerLocation'] = _withCoords(travel, approx.$1, approx.$2);
  }
  return out;
}

/// The signed-in user's OWN profile: the public map with the exact values
/// from [private] laid over it. Without private data the legacy public
/// coordinates are kept when present, else the approximate ones are used (a
/// new account before its private document loads).
Map<String, dynamic> ownProfileView(
    Map<String, dynamic> data, Map<String, dynamic>? private) {
  if (data[kOwnViewMarker] == true && private == null) return data;
  var out = Map<String, dynamic>.from(data);
  if (private != null) {
    final home = homeCoordsOf(private);
    if (home != null) {
      out['location'] = _withCoords(out['location'], home.$1, home.$2);
    }
    final travel =
        _coordsOf(private['travelerLocation'], 'latitude', 'longitude');
    if (travel != null && out['travelerLocation'] is Map) {
      out['travelerLocation'] =
          _withCoords(out['travelerLocation'], travel.$1, travel.$2);
    }
    for (final k in const [
      'dateOfBirth',
      'sexualOrientation',
      'email',
      'verificationPhone',
      'privatePhotoUrls',
      kVerificationPhotoPathField,
      kProfileGeohashField,
    ]) {
      final v = private[k];
      if (v != null) out[k] = v;
    }
    // Own age comes from the exact date of birth, not the server's copy
    // (which lags a just-edited birthday by one trigger run).
    if (private['dateOfBirth'] != null) out.remove(kPublicAgeField);
  }
  if (homeCoordsOf(out) == null) out = publicProfileView(out);
  out[kOwnViewMarker] = true;
  return out;
}

/// Age in whole years at [now].
int ageFromDateOfBirth(DateTime dob, {DateTime? now}) {
  final n = now ?? DateTime.now();
  var age = n.year - dob.year;
  if (n.month < dob.month || (n.month == dob.month && n.day < dob.day)) {
    age--;
  }
  return age;
}

/// A coordinate pair as the location pickers print it when no place name
/// resolved ("45.4642, 9.1900", "(45.46, 9.19)"): two decimals or more.
final RegExp _coordinatePair = RegExp(
    r'\(?\s*-?\d{1,3}\.\d{2,}\s*,\s*-?\d{1,3}\.\d{2,}\s*\)?');

/// [displayAddress] safe for the PUBLIC profile: a label that embeds exact
/// coordinates (the web browser-location fallback when Nominatim fails, or
/// the traveller picker when the address can't be resolved) would publish
/// the very position profiles_private hides. Such a label is replaced by
/// "city, country" (or whatever is left once the numbers are removed).
String publicDisplayAddress(String? displayAddress,
    {String? city, String? country}) {
  final raw = displayAddress ?? '';
  if (!_coordinatePair.hasMatch(raw)) return raw;
  final place = [city, country]
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(', ');
  if (place.isNotEmpty) return place;
  return raw
      .replaceAll(_coordinatePair, '')
      .split(RegExp(r'(^|\s+)[—-]\s+'))
      .first
      .replaceAll(RegExp(r'^[\s,;—-]+|[\s,;—-]+$'), '');
}

/// The public map without any sensitive value: top-level sensitive fields are
/// removed and `location` / `travelerLocation` lose their coordinates.
///
/// Nested maps are flattened to dotted paths when [forUpdate] is set, so a
/// Firestore `update()` changes only the city / country keys and never
/// replaces (= deletes) coordinates an old app version still relies on. With
/// `set(..., merge: true)` maps are deep-merged anyway, so they stay nested.
Map<String, dynamic> publicSafeProfileJson(Map<String, dynamic> json,
    {bool forUpdate = false}) {
  final out = Map<String, dynamic>.from(json)
    ..removeWhere((k, _) => kSensitiveTopLevelFields.contains(k))
    ..remove(kOwnViewMarker)
    // Server-computed; a client write would only be overwritten.
    ..remove(kGeohash5Field)
    ..remove(kApproxLocationField)
    ..remove(kPublicAgeField)
    ..remove(kVerificationPhotoPathField);
  for (final key in const ['location', 'travelerLocation']) {
    final v = out[key];
    if (v is! Map) continue;
    final stripped = Map<String, dynamic>.from(v)
      ..remove('latitude')
      ..remove('longitude');
    final label = stripped['displayAddress'];
    if (label is String) {
      stripped['displayAddress'] = publicDisplayAddress(label,
          city: stripped['city'] as String?,
          country: stripped['country'] as String?);
    }
    if (forUpdate) {
      out.remove(key);
      stripped.forEach((k, val) => out['$key.$k'] = val);
    } else {
      out[key] = stripped;
    }
  }
  return out;
}

bool _sameList(Object? a, Object? b) =>
    a is List && b is List && listEquals(a, b);

DateTime? _dateOf(Object? v) => v is Timestamp
    ? v.toDate()
    : v is DateTime
        ? v
        : null;

/// What to merge into `profiles_private/{uid}` for a full-profile save.
///
/// [json] is the full (unstripped) ProfileModel.toFirestoreJson output,
/// [current] the private document as last read (null = none / unknown) and
/// [publicData] the current public document (for its `approxLocation`).
///
/// Only values the user can actually have changed are written. Values that
/// are fallbacks of ProfileModel.fromJson for a field it could not see
/// (placeholder birth date, null, the approximate coordinates, (0, 0)) are
/// never written over real private data.
Map<String, dynamic> privateProfileWrite(
  Map<String, dynamic> json, {
  Map<String, dynamic>? current,
  Map<String, dynamic>? publicData,
}) {
  final out = <String, dynamic>{};
  final approx = approxCoordsOf(publicData);
  bool isApprox((double, double) c) =>
      approx != null &&
      (c.$1 - approx.$1).abs() < 1e-9 &&
      (c.$2 - approx.$2).abs() < 1e-9;

  final home = homeCoordsOf(json);
  if (home != null && !isApprox(home)) {
    if (homeCoordsOf(current) != home) {
      out['location'] = {'latitude': home.$1, 'longitude': home.$2};
    }
  }
  final travel = _coordsOf(json['travelerLocation'], 'latitude', 'longitude');
  if (json.containsKey('travelerLocation') &&
      json['travelerLocation'] == null) {
    if (current?['travelerLocation'] != null) {
      out['travelerLocation'] = FieldValue.delete();
    }
  } else if (travel != null && !isApprox(travel)) {
    if (_coordsOf(current?['travelerLocation'], 'latitude', 'longitude') !=
        travel) {
      out['travelerLocation'] = {'latitude': travel.$1, 'longitude': travel.$2};
    }
  }

  // The 9-char geohash of the discoverable location, from the exact values
  // that will be stored (this write laid over the current private data).
  final storedHome = out['location'] is Map
      ? homeCoordsOf(out)
      : (homeCoordsOf(current) ??
          (home != null && !isApprox(home) ? home : null));
  final travelOff =
      json.containsKey('travelerLocation') && json['travelerLocation'] == null;
  final storedTravel = travelOff
      ? null
      : out['travelerLocation'] is Map
          ? _coordsOf(out['travelerLocation'], 'latitude', 'longitude')
          : _coordsOf(current?['travelerLocation'], 'latitude', 'longitude');
  final exact = Map<String, dynamic>.from(json)
    ..['location'] = storedHome == null
        ? null
        : _withCoords(json['location'], storedHome.$1, storedHome.$2)
    ..['travelerLocation'] =
        (storedTravel == null || json['travelerLocation'] is! Map)
            ? null
            : _withCoords(
                json['travelerLocation'], storedTravel.$1, storedTravel.$2);
  final hash = profileGeohash(exact);
  if (hash != null && hash != current?[kProfileGeohashField]) {
    out[kProfileGeohashField] = hash;
  }

  final dob = _dateOf(json['dateOfBirth']);
  final currentDob = _dateOf(current?['dateOfBirth']);
  if (dob != null &&
      dob != currentDob &&
      !(dob == kUnknownDateOfBirth && currentDob != null)) {
    out['dateOfBirth'] = Timestamp.fromDate(dob);
  }

  for (final k in const ['sexualOrientation', 'verificationPhone', 'email']) {
    final v = json[k];
    if (v is String && v.isNotEmpty && v != current?[k]) out[k] = v;
  }
  final photos = json['privatePhotoUrls'];
  if (photos is List &&
      photos.isNotEmpty &&
      !_sameList(photos, current?['privatePhotoUrls'])) {
    out['privatePhotoUrls'] = List<String>.from(photos);
  }
  final path = json[kVerificationPhotoPathField];
  if (path is String &&
      path.isNotEmpty &&
      path != current?[kVerificationPhotoPathField]) {
    out[kVerificationPhotoPathField] = path;
  }
  if (out.isNotEmpty) out['updatedAt'] = FieldValue.serverTimestamp();
  return out;
}

/// Precision-5 geohash used for nearest-first queries on `profiles`.
String? geohash5For(double? lat, double? lng) =>
    _valid(lat, lng) ? GeoQuery.encode(lat!, lng!, kGeohash5Precision) : null;

/// The signed-in user's `profiles_private/{uid}` document, kept live while
/// the app runs (one listener, attached by OwnProfileStore).
class PrivateProfileCache {
  PrivateProfileCache._();

  static final PrivateProfileCache instance = PrivateProfileCache._();

  /// Bumped on every change; OwnProfileStore re-parses the own profile.
  final ValueNotifier<int> version = ValueNotifier<int>(0);

  String? _uid;
  Map<String, dynamic>? _data;
  bool _loaded = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Completer<void>? _firstLoad;
  String? _attached;

  @visibleForTesting
  FirebaseFirestore? firestoreOverride;

  FirebaseFirestore get _fs => firestoreOverride ?? FirebaseFirestore.instance;

  String? get uid => _uid;

  /// True once the document (or its absence) has been seen for [uid].
  bool get isLoaded => _loaded;

  /// Read-only private data for [userId] (null when unknown / other user).
  Map<String, dynamic>? dataFor(String? userId) =>
      (userId != null && userId == _uid && _data != null)
          ? Map<String, dynamic>.unmodifiable(_data!)
          : null;

  /// Whether [userId] is the user this cache belongs to.
  bool isOwn(String? userId) =>
      userId != null && userId.isNotEmpty && userId == _uid;

  /// Starts (or keeps) the live listener for [userId].
  void attach(String userId) {
    // Idempotent per user, including when listening failed (no Firebase in
    // tests, offline): re-attaching from a version change must not loop.
    if (userId.isEmpty || _attached == userId) return;
    reset();
    _uid = userId;
    _attached = userId;
    _firstLoad = Completer<void>();
    try {
      _sub = privateProfileRef(_fs, userId).snapshots().listen((snap) {
        if (_uid != userId) return;
        _data = snap.data();
        _markLoaded();
      }, onError: (Object e) {
        debugPrint('[PrivateProfileCache] listener failed: $e');
        _markLoaded();
      });
    } catch (e) {
      debugPrint('[PrivateProfileCache] could not listen: $e');
      _markLoaded();
    }
  }

  void _markLoaded() {
    _loaded = true;
    if (_firstLoad?.isCompleted == false) _firstLoad!.complete();
    version.value++;
  }

  /// Seeds the cache from a one-shot read or a just-made write.
  void seed(String userId, Map<String, dynamic>? data) {
    if (userId.isEmpty) return;
    if (_uid != userId) {
      reset();
      _uid = userId;
    }
    _data = data == null ? null : Map<String, dynamic>.from(data);
    _markLoaded();
  }

  /// The private data for [userId], waiting (bounded) for the first load or
  /// doing one read. Null when it doesn't exist or can't be read.
  Future<Map<String, dynamic>?> ensure(String userId,
      {Duration timeout = const Duration(seconds: 5)}) async {
    if (userId.isEmpty) return null;
    if (_uid == userId && _loaded) return dataFor(userId);
    if (_uid == userId && _firstLoad != null) {
      try {
        await _firstLoad!.future.timeout(timeout);
        return dataFor(userId);
      } catch (_) {}
    }
    try {
      final snap = await privateProfileRef(_fs, userId).get().timeout(timeout);
      if (_uid == null || _uid == userId) seed(userId, snap.data());
      return snap.data();
    } catch (e) {
      debugPrint('[PrivateProfileCache] read failed: $e');
      return dataFor(userId);
    }
  }

  /// Forget everything (sign-out / other account).
  void reset() {
    unawaited(_sub?.cancel());
    _sub = null;
    _uid = null;
    _data = null;
    _loaded = false;
    _firstLoad = null;
    _attached = null;
  }
}

/// Merges [update] into the own private document (creating it when missing).
/// The live [PrivateProfileCache] listener picks the change up locally.
Future<void> writePrivateProfile(
    FirebaseFirestore firestore, String uid, Map<String, dynamic> update,
    {WriteBatch? batch}) async {
  if (update.isEmpty) return;
  final ref = privateProfileRef(firestore, uid);
  if (batch != null) {
    batch.set(ref, update, SetOptions(merge: true));
  } else {
    await ref.set(update, SetOptions(merge: true));
  }
}

/// The view of a raw profile map the app should work with: the own profile
/// with its private values (see [ownProfileView]), anyone else's reduced to
/// the public approximate view (see [publicProfileView]).
Map<String, dynamic> profileViewFor(Map<String, dynamic> raw) {
  if (raw[kOwnViewMarker] == true) return raw;
  final uid = raw['userId'] as String?;
  final cache = PrivateProfileCache.instance;
  if (cache.isOwn(uid)) return ownProfileView(raw, cache.dataFor(uid));
  return publicProfileView(raw);
}

/// [profileViewFor] for a raw map whose doc id is [uid] (maps that don't
/// carry `userId`).
Map<String, dynamic> profileViewForDoc(String uid, Map<String, dynamic> raw) =>
    profileViewFor({...raw, 'userId': uid});

/// [ownProfileView] of a raw own-profile map read straight from Firestore,
/// with whatever private data is cached right now. Null in, null out.
Map<String, dynamic>? ownRawView(String uid, Map<String, dynamic>? data) =>
    data == null
        ? null
        : ownProfileView({...data, 'userId': uid},
            PrivateProfileCache.instance.dataFor(uid));

/// [ownRawView] after waiting (bounded) for the private document, for code
/// that needs the exact own location (nearby searches, distance origin).
Future<Map<String, dynamic>?> ownRawViewLoaded(
    String uid, Map<String, dynamic>? data) async {
  if (data == null) return null;
  await PrivateProfileCache.instance
      .ensure(uid, timeout: const Duration(seconds: 3));
  return ownRawView(uid, data);
}
