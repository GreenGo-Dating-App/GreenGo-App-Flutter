import 'dart:async';

import '../../../attractions/data/attractions_prefetch.dart';
import '../../../user_experiences/presentation/experience_feed_prefetch.dart';
import '../../domain/entities/event.dart';
import '../datasources/events_remote_datasource.dart';
import '../datasources/external_events_preloader.dart';
import 'events_cache_service.dart';
import 'events_location.dart';

/// Background prefetch for the Events tab.
///
/// Called by MainNavigationScreen once the first tab has painted. It warms
/// EXACTLY the queries the Events page runs on open — the Community feed
/// (closest [communityLimit] around [EventsLocation]), the first partner
/// pages ([ExternalEventsPreloader]), the Attractions tab's country
/// ([AttractionsPrefetch]) and the Experiences "All" community page
/// ([ExperienceFeedPrefetch]) — writing the LastResultCache so each tab
/// paints instantly, and handing the results over so nothing is re-read.
/// All of them run in parallel. Never throws; deduplicated per session.
class EventsPrefetch {
  EventsPrefetch._();

  /// The Community tab's default list size (shared so both run one query).
  static const int communityLimit = 100;

  /// A prefetched feed older than this is re-queried by the tab instead.
  static const Duration _maxAge = Duration(minutes: 5);

  static String? _userId;
  static Future<void>? _job;
  static Future<void>? _communityJob;

  /// Set once the tab asked for the feed: a prefetch that has not STARTED its
  /// read by then skips it (the tab runs its own). One already running always
  /// stores its result for the waiting tab.
  static bool _communityClaimed = false;

  /// Bumped by [reset]; work started for a previous account drops its result.
  static int _epoch = 0;
  static ({
    double lat,
    double lng,
    DateTime at,
    List<Event> events
  })? _community;

  static Future<void> warm(String userId) {
    if (userId.isEmpty) return Future.value();
    if (_userId == userId && _job != null) return _job!;
    // A different account: start clean. (Claims made before the first warm
    // belong to this account and are kept, so the tab's query isn't repeated.)
    if (_userId != null && _userId != userId) reset();
    _userId = userId;
    return _job = _run(userId, _epoch).catchError((Object _) {});
  }

  static Future<void> _run(String userId, int epoch) async {
    final live = ExternalEventsPreloader.instance.warm(userId);
    final anchor = await EventsLocation.quick(userId);
    if (epoch != _epoch) return;
    if (anchor != null && !_communityClaimed) {
      _communityJob = _warmCommunity(anchor.lat, anchor.lng, epoch);
    }
    // The other two tabs of the Events page (built lazily by its TabBarView,
    // so without this their first open always waited for the network).
    final attractions =
        AttractionsPrefetch.warm(userId, lat: anchor?.lat, lng: anchor?.lng);
    final experiences =
        ExperienceFeedPrefetch.warm(lat: anchor?.lat, lng: anchor?.lng);
    await Future.wait([
      live,
      attractions,
      experiences,
      if (_communityJob != null) _communityJob!,
    ]);
  }

  static Future<void> _warmCommunity(double lat, double lng, int epoch) async {
    final events = await EventsRemoteDataSourceImpl()
        .getNearbyCommunityEvents(lat: lat, lng: lng, limit: communityLimit);
    if (epoch != _epoch) return;
    _community = (lat: lat, lng: lng, at: DateTime.now(), events: events);
    await const EventsCacheService().saveCommunity(events);
  }

  /// The prefetched Community feed if it was computed around [lat]/[lng] and
  /// is still fresh (waits for an in-flight prefetch); null otherwise. Hands
  /// ownership to the caller — a later [warm] won't query it again.
  static Future<List<Event>?> takeCommunity(double lat, double lng) async {
    _communityClaimed = true;
    final job = _communityJob;
    if (job != null) await job.catchError((Object _) {});
    final c = _community;
    _community = null;
    if (c == null) return null;
    if (DateTime.now().difference(c.at) > _maxAge) return null;
    if (EventsLocation.movedFar((lat: c.lat, lng: c.lng), lat, lng)) {
      return null;
    }
    return c.events;
  }

  /// The prefetched Community feed without claiming it (image warm-up only).
  static List<Event> peekCommunity() => _community?.events ?? const [];

  /// Forget all per-account prefetch state — this, [ExternalEventsPreloader],
  /// the Attractions / Experiences warm-ups and the [EventsLocation] anchor
  /// (sign-out / account switch).
  static void reset() {
    _epoch++;
    _userId = null;
    _job = null;
    _communityJob = null;
    _communityClaimed = false;
    _community = null;
    ExternalEventsPreloader.instance.reset();
    AttractionsPrefetch.reset();
    ExperienceFeedPrefetch.reset();
    EventsLocation.reset();
  }
}
