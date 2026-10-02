import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/cache/last_result_cache.dart';
import '../../../core/services/user_directory_service.dart';
import '../../../core/utils/geo_query.dart';
import '../../events/data/datasources/external_events_pager.dart';
import '../../events/domain/entities/external_event.dart';
import '../../user_experiences/data/datasources/user_experiences_remote_datasource.dart';
import '../../user_experiences/data/models/user_experience_model.dart';
import '../../user_experiences/domain/entities/user_experience.dart';
import '../../user_experiences/presentation/widgets/experience_widgets.dart';
import '../domain/top_experiences.dart';

/// Loads Explore "Top experiences" ([buildTopExperiences] does the ranking).
///
/// Bounded reads per load:
///  - featured: ONE query, `status == published && isFeatured == true &&
///    featuredUntil > now`, newest expiry first, limit [kTopExperiencesLimit]
///    (index: status ASC, isFeatured ASC, featuredUntil DESC);
///  - community: with a location, the existing nearest-first
///    [UserExperiencesRemoteDataSource.communityFeed] pager, at most
///    [_communityPages] pages of 20 (≤ 40 docs); without one, ONE query
///    `status == published` by `ratingCount` desc, limit 40 (index: status ASC,
///    ratingCount DESC) — re-ranked client-side by the weighted rating;
///  - partner: only when slots remain — the Viator [ExternalEventsPager]
///    (nearest-first rings with a location, else by rating; image-only), at
///    most [_partnerPages] pages.
/// Never throws: a failing source just contributes nothing.
class TopExperiencesLoader {
  TopExperiencesLoader({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String cacheKey = 'explore_top_experiences_v1';
  static const int _communityPool = 40;
  static const int _communityPages = 2;
  static const int _partnerPages = 3;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(UserExperiencesRemoteDataSource.collection);

  static double? _km(double? lat, double? lng, UserExperience e) {
    if (lat == null || lng == null || !e.hasCoordinates) return null;
    return GeoQuery.distanceMeters(lat, lng, e.lat!, e.lng!) / 1000;
  }

  /// Server load. [blocked] = the viewer's (bidirectional) block list.
  Future<List<TopExperienceItem>> load({
    required double? lat,
    required double? lng,
    required Set<String> blocked,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final hasLoc = lat != null && lng != null;

    final reads = await Future.wait<List<UserExperience>>([
      _featured(at),
      hasLoc ? _nearbyCommunity(lat, lng) : _ratedCommunity(),
    ]);
    final members = await _visible([...reads[0], ...reads[1]], blocked);
    final featured =
        members.where((e) => e.isCurrentlyFeaturedAt(at)).toList();

    var items = buildTopExperiences(featured, members, const [],
        now: at, distanceKm: hasLoc ? (e) => _km(lat, lng, e) : null);
    if (items.length < kTopExperiencesLimit) {
      final partner =
          await _partner(lat, lng, kTopExperiencesLimit - items.length);
      items = buildTopExperiences(featured, members, partner,
          now: at, distanceKm: hasLoc ? (e) => _km(lat, lng, e) : null);
    }
    unawaited(LastResultCache.saveJson(
        cacheKey, [for (final i in items) i.key]));
    return items;
  }

  /// What the last server load showed, read by id from the LOCAL Firestore
  /// cache only (no network), re-checked: published, not blocked / banned,
  /// featured flag re-evaluated against [now]; partner items need an image.
  /// Empty when nothing usable is cached. Never throws.
  Future<List<TopExperienceItem>> loadCached({
    required Set<String> blocked,
    DateTime? now,
  }) async {
    try {
      final at = now ?? DateTime.now();
      final raw = await LastResultCache.loadJson(cacheKey);
      if (raw is! List || raw.isEmpty) return const [];
      const cacheOnly = GetOptions(source: Source.cache);
      final items = await Future.wait(
          raw.whereType<String>().map((ref) async {
        try {
          final id = ref.substring(2);
          if (id.isEmpty) return null;
          if (ref.startsWith('u:')) {
            final doc = await _col.doc(id).get(cacheOnly);
            if (!doc.exists) return null;
            final e = UserExperienceModel.fromDoc(doc);
            if (!e.isPublished ||
                blocked.contains(e.hostId) ||
                ExperienceCard.isHostHidden(e.hostId)) {
              return null;
            }
            return TopExperienceItem.community(e,
                featured: e.isCurrentlyFeaturedAt(at));
          }
          if (ref.startsWith('x:')) {
            final doc = await _db
                .collection('external_events')
                .doc(id)
                .get(cacheOnly);
            final data = doc.data();
            if (data == null) return null;
            final p = ExternalEvent.fromMap(doc.id, data);
            final img = p.imageUrl;
            return img == null || img.trim().isEmpty
                ? null
                : TopExperienceItem.partner(p);
          }
        } catch (_) {
          // not in the local cache
        }
        return null;
      }));
      return items.whereType<TopExperienceItem>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<UserExperience>> _featured(DateTime at) async {
    try {
      final snap = await _col
          .where('status', isEqualTo: 'published')
          .where('isFeatured', isEqualTo: true)
          .where('featuredUntil', isGreaterThan: Timestamp.fromDate(at))
          .orderBy('featuredUntil', descending: true)
          .limit(kTopExperiencesLimit)
          .get();
      return snap.docs.map(UserExperienceModel.fromDoc).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<UserExperience>> _nearbyCommunity(double lat, double lng) async {
    try {
      final pager = UserExperiencesRemoteDataSource(firestore: _db)
          .communityFeed(lat: lat, lng: lng);
      final out = <UserExperience>[];
      for (var i = 0;
          i < _communityPages &&
              pager.hasMore &&
              out.length < _communityPool;
          i++) {
        out.addAll(await pager.next());
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<List<UserExperience>> _ratedCommunity() async {
    try {
      final snap = await _col
          .where('status', isEqualTo: 'published')
          .orderBy('ratingCount', descending: true)
          .limit(_communityPool)
          .get();
      return snap.docs.map(UserExperienceModel.fromDoc).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<ExternalEvent>> _partner(
      double? lat, double? lng, int wanted) async {
    try {
      final pager = ExternalEventsPager(
        source: 'viator',
        sort: lat != null && lng != null ? 'distance' : 'rating',
        userLat: lat,
        userLng: lng,
        firestore: _db,
      );
      final out = <ExternalEvent>[];
      for (var i = 0;
          i < _partnerPages && pager.hasMore && out.length < wanted;
          i++) {
        out.addAll(await pager.next());
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Drops blocked hosts and banned / suspended / deleted ones (host briefs
  /// resolved in ONE batched directory call, bounded by a short timeout so a
  /// slow network never stalls the section).
  Future<List<UserExperience>> _visible(
      List<UserExperience> list, Set<String> blocked) async {
    final kept = list.where((e) => !blocked.contains(e.hostId)).toList();
    final hosts = {for (final e in kept) e.hostId}..remove('');
    if (hosts.isNotEmpty) {
      try {
        await UserDirectoryService.instance
            .resolve(hosts)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // Unresolved hosts stay visible; the card itself hides a banned
        // host once its brief arrives.
      }
    }
    return kept.where((e) => !ExperienceCard.isHostHidden(e.hostId)).toList();
  }
}
