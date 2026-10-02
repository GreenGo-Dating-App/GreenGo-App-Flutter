import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/geo_query.dart';
import '../domain/country_resolver.dart';
import '../domain/entities/attraction.dart';
import 'datasources/attractions_datasource.dart';

/// Background warm-up of the Events page's Attractions tab.
///
/// Called from [EventsPrefetch] once the first screen has painted. It runs the
/// SAME reads the tab's bootstrap needs — the storage bucket, the published
/// countries, the geo config and the profile (all cache-first) — resolves the
/// country the tab will open on (the same layered [CountryResolver], traveler
/// mode first, then the device anchor, then `primaryOrigin`) and loads that
/// country's shard. Everything lands in [AttractionsDataSource]'s session
/// memo, so opening the tab is a memo hit instead of 4 + 1 serial reads.
///
/// Bounded: at most one shard query for one country. Never throws;
/// deduplicated per session.
class AttractionsPrefetch {
  AttractionsPrefetch._();

  static Future<void>? _job;
  static String? _userId;
  static int _epoch = 0;
  static String? _iso;

  /// The country the warm-up resolved (null until it has). The tab starts
  /// loading it in parallel with its own bootstrap reads.
  static String? get likelyIso => _iso;

  /// Fire-and-forget. [lat]/[lng] = the Events anchor (EventsLocation).
  static Future<void> warm(String userId, {double? lat, double? lng}) {
    if (userId.isEmpty) return Future.value();
    if (_userId == userId && _job != null) return _job!;
    if (_userId != null && _userId != userId) reset();
    _userId = userId;
    return _job = _run(userId, lat, lng, _epoch).catchError((Object _) {});
  }

  static Future<void> _run(
      String userId, double? lat, double? lng, int epoch) async {
    final ds = AttractionsDataSource();
    final reads = await Future.wait<Object>([
      ds.bucket(),
      ds.publishedCountries(),
      _profile(userId),
      ds.geoIndex(),
    ]);
    if (epoch != _epoch) return;
    final countries = reads[1] as List<AttractionCountry>;
    if (countries.isEmpty) return;
    final profile = reads[2] as Map<String, dynamic>;
    final geo = reads[3] as List<Map<String, dynamic>>;

    final published = countries.map((c) => c.iso2).toSet();
    final home = (profile['primaryOrigin'] as String?)?.toUpperCase();
    final validHome = home != null && published.contains(home) ? home : null;

    // Mirrors AttractionsTab: traveler location > device anchor > profile.
    final anchor = profileAnchor(profile);
    var aLat = anchor?.lat, aLng = anchor?.lng;
    if (!(anchor?.traveler ?? false) && lat != null && lng != null) {
      aLat = lat;
      aLng = lng;
    }
    final iso = CountryResolver.resolve(
          candidates: candidatesFromGeo(geo),
          countryName: anchor?.country,
          lat: aLat,
          lng: aLng,
        ) ??
        validHome ??
        countries.first.iso2;
    if (epoch != _epoch) return;
    _iso = iso;
    await ds.forCountry(iso);
  }

  /// `Profile.effectiveLocation` as the tab reads it: the traveler location
  /// while Traveler mode is active and unexpired, else the profile location.
  static ({double lat, double lng, String? country, bool traveler})?
      profileAnchor(Map<String, dynamic> d) {
    final expiryRaw = d['travelerExpiry'];
    DateTime? expiry;
    if (expiryRaw is Timestamp) expiry = expiryRaw.toDate();
    if (expiryRaw is String) expiry = DateTime.tryParse(expiryRaw);
    final active = d['isTraveler'] == true &&
        expiry != null &&
        expiry.isAfter(DateTime.now());
    final chosen = ((active ? d['travelerLocation'] : d['location']) as Map?) ??
        (d['location'] as Map?);
    if (chosen == null) return null;
    final la = (chosen['latitude'] as num?)?.toDouble();
    final ln = (chosen['longitude'] as num?)?.toDouble();
    if (la == null || ln == null) return null;
    return (
      lat: la,
      lng: ln,
      country: chosen['country'] as String?,
      traveler: active,
    );
  }

  /// [AttractionsDataSource.geoIndex] rows as resolver candidates.
  static List<CountryCandidate> candidatesFromGeo(
          List<Map<String, dynamic>> geo) =>
      geo.map((m) {
        final iso = (m['iso2'] ?? '').toString().toUpperCase();
        final bboxRaw = m['bbox'];
        return CountryCandidate(
          iso2: iso,
          name: (m['name'] ?? iso).toString(),
          bbox: bboxRaw is List
              ? bboxRaw.map((e) => (e as num).toDouble()).toList()
              : null,
          cities: ((m['cities'] as List?) ?? const [])
              .map<(double, double)>((c) =>
                  ((c[0] as num).toDouble(), (c[1] as num).toDouble()))
              .toList(),
        );
      }).toList();

  /// profiles/{uid} from the local cache (warmed at startup), else the server.
  static Future<Map<String, dynamic>> _profile(String uid) async {
    final ref = FirebaseFirestore.instance.collection('profiles').doc(uid);
    try {
      final c = await ref.get(const GetOptions(source: Source.cache));
      if (c.exists) return c.data() ?? const {};
    } catch (_) {/* not cached */}
    try {
      return (await ref.get()).data() ?? const {};
    } catch (_) {
      return const {};
    }
  }

  /// The tab's default first row (nearest first when an anchor is known, else
  /// best GreenGo Score) for image warm-up; empty until the warm-up loaded.
  static List<Attraction> firstItems(int n, {double? lat, double? lng}) {
    final iso = _iso;
    if (iso == null) return const [];
    final list = AttractionsDataSource.cachedCountry(iso);
    if (list == null || list.isEmpty) return const [];
    final sorted = [...list];
    if (lat != null && lng != null) {
      double d(Attraction a) => (a.lat == null || a.lng == null)
          ? double.maxFinite
          : GeoQuery.distanceMeters(lat, lng, a.lat!, a.lng!);
      sorted.sort((a, b) => d(a).compareTo(d(b)));
    } else {
      sorted.sort((a, b) => b.greengoScore.compareTo(a.greengoScore));
    }
    return sorted.take(n).toList();
  }

  /// Forget the per-account warm-up (sign-out / account switch).
  static void reset() {
    _epoch++;
    _job = null;
    _userId = null;
    _iso = null;
  }
}
