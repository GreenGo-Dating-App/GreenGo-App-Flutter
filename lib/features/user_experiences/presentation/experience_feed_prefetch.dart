import 'dart:async';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/geo_query.dart';
import '../../events/data/services/events_location.dart';
import '../domain/entities/user_experience.dart';
import '../domain/repositories/user_experiences_repository.dart';
import 'experience_first_page_cache.dart';

/// Background warm-up of the community side of Events → Experiences → "All"
/// (the tab's default view), so opening the tab paints at once.
///
/// It runs EXACTLY the first page the feed would (nearest-first community
/// feed around the Events anchor, no query), records it in the
/// [ExperienceFirstPageCache] under the feed's key and keeps the pager in
/// memory; the feed adopts it via [take] and keeps paging from there, so
/// nothing is read twice. (The partner side is warmed by
/// ExternalEventsPreloader.) Bounded: one page of the community pager.
/// Never throws; at most once per session.
class ExperienceFeedPrefetch {
  ExperienceFeedPrefetch._();

  /// A warmed page older than this is re-queried by the feed instead.
  static const Duration _maxAge = Duration(minutes: 5);

  static Future<void>? _job;
  static bool _claimed = false;
  static int _epoch = 0;
  static ({
    double? lat,
    double? lng,
    ExperienceFeedPager pager,
    List<UserExperience> items,
    DateTime at,
  })? _warm;

  /// [ExperienceFirstPageCache] key of the "All" feed's community first page,
  /// bucketed to the viewer's ~5 km geohash cell.
  static String allFeedKey(double? lat, double? lng) {
    final cell =
        (lat != null && lng != null) ? GeoQuery.encode(lat, lng, 5) : 'none';
    return 'uexp_all_$cell';
  }

  static Future<void> warm({double? lat, double? lng}) {
    if (_job != null || _claimed) return _job ?? Future.value();
    final epoch = _epoch;
    return _job = () async {
      try {
        final pager = di
            .sl<UserExperiencesRepository>()
            .communityFeed(lat: lat, lng: lng);
        final items = await pager.next();
        if (epoch != _epoch) return;
        _warm = (
          lat: lat,
          lng: lng,
          pager: pager,
          items: items,
          at: DateTime.now(),
        );
        unawaited(const ExperienceFirstPageCache()
            .save(allFeedKey(lat, lng), items));
      } catch (_) {/* best-effort */}
    }();
  }

  /// The warmed pager + first page when built for the same anchor and still
  /// fresh (waits for an in-flight warm); null otherwise. Hands ownership to
  /// the caller.
  static Future<({ExperienceFeedPager pager, List<UserExperience> items})?>
      take({double? lat, double? lng}) async {
    _claimed = true;
    final job = _job;
    if (job != null) await job;
    final w = _warm;
    _warm = null;
    if (w == null) return null;
    if (DateTime.now().difference(w.at) > _maxAge) return null;
    final sameAnchor = (w.lat == null || w.lng == null)
        ? lat == null && lng == null
        : lat != null &&
            lng != null &&
            !EventsLocation.movedFar((lat: w.lat!, lng: w.lng!), lat, lng);
    return sameAnchor ? (pager: w.pager, items: w.items) : null;
  }

  /// The warmed first page without claiming it (image warm-up only).
  static List<UserExperience> peek() => _warm?.items ?? const [];

  /// Forget everything (sign-out / account switch).
  static void reset() {
    _epoch++;
    _job = null;
    _claimed = false;
    _warm = null;
  }
}
