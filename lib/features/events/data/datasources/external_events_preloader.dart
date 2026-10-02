import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/external_event.dart';
import '../services/events_location.dart';
import 'external_events_pager.dart';

/// Warms the Events tab's external sub-tabs — Live (ticketmaster) and
/// Experiences (viator) — in the background, so opening them shows data
/// instantly.
///
/// It runs EXACTLY the first page the tab would (distance sort, no category,
/// anchored on [EventsLocation]), records it in the LastResultCache and keeps
/// the pager in memory. ExperiencesTab adopts the warmed pager via [take] and
/// keeps paging from where the preload left off, so nothing is read twice.
class ExternalEventsPreloader {
  ExternalEventsPreloader._();
  static final ExternalEventsPreloader instance = ExternalEventsPreloader._();

  /// Warmed views: Live (ticketmaster, distance), Experiences (viator,
  /// distance) and the partner side of Events "All" (ticketmaster by date,
  /// narrowed to the profile's country when known).
  static const List<({String key, String source, String sort})> _views = [
    (key: 'ticketmaster', source: 'ticketmaster', sort: 'distance'),
    (key: 'viator', source: 'viator', sort: 'distance'),
    (key: 'ticketmaster:date', source: 'ticketmaster', sort: 'date'),
  ];

  /// Job key of a view (distance views keep their bare source name).
  static String keyFor(String source, String sort) =>
      sort == 'distance' ? source : '$source:$sort';

  /// A warmed page older than this is re-queried by the tab instead.
  static const Duration _maxAge = Duration(minutes: 5);

  final Map<String, Future<void>> _jobs = {};
  final Map<String,
          ({ExternalEventsPager pager, List<ExternalEvent> items, DateTime at})>
      _warm = {};

  /// Sources a tab already loaded itself this session — warming them later
  /// would be wasted reads.
  final Set<String> _claimed = {};

  /// Bumped by [reset]; a warm started for a previous account drops its result.
  int _epoch = 0;

  /// Fire-and-forget; each source runs at most once per session. Never throws.
  Future<void> warm([String? userId]) async {
    final todo = _views
        .where((v) => !_jobs.containsKey(v.key) && !_claimed.contains(v.key))
        .toList();
    if (todo.isEmpty) return;
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final anchorFuture = EventsLocation.quick(uid);
    final epoch = _epoch;
    for (final view in todo) {
      final key = view.key;
      _jobs[key] = () async {
        try {
          final anchor = await anchorFuture;
          final place = view.sort == 'date'
              ? await EventsLocation.profilePlace(uid)
              : null;
          // Claims are honoured only BEFORE the read starts; once started, the
          // result is always stored so a tab waiting in [take] receives it.
          if (_claimed.contains(key) || epoch != _epoch) return;
          final pager = ExternalEventsPager(
            source: view.source,
            sort: view.sort,
            userLat: anchor?.lat,
            userLng: anchor?.lng,
            liveChunks: true,
            country: place?.country,
          );
          final first = await pager.next();
          if (epoch != _epoch) return;
          _warm[key] = (pager: pager, items: first, at: DateTime.now());
          unawaited(pager.saveFirstPage(first));
        } catch (_) {/* best-effort */}
      }();
    }
    await Future.wait(_jobs.values);
  }

  /// The warmed pager + first page for [source] if it was built for the same
  /// anchor ([lat]/[lng]) and is still fresh; waits for an in-flight warm of
  /// that source. Null otherwise. Handing it over transfers ownership, and
  /// marks the source claimed either way.
  ///
  /// [sort] 'date' takes the soonest-first view; it is anchor-free, so only
  /// the [country] it was narrowed to must match.
  Future<({ExternalEventsPager pager, List<ExternalEvent> items})?> take(
      String source,
      {double? lat,
      double? lng,
      String sort = 'distance',
      String? country}) async {
    final key = keyFor(source, sort);
    _claimed.add(key);
    final job = _jobs[key];
    if (job != null) await job;
    final w = _warm.remove(key);
    if (w == null) return null;
    if (DateTime.now().difference(w.at) > _maxAge) return null;
    if (sort != 'distance') {
      return (w.pager.country ?? '') == (country ?? '')
          ? (pager: w.pager, items: w.items)
          : null;
    }
    final pLat = w.pager.userLat, pLng = w.pager.userLng;
    final sameAnchor = (pLat == null || pLng == null)
        ? lat == null && lng == null
        : lat != null &&
            lng != null &&
            !EventsLocation.movedFar((lat: pLat, lng: pLng), lat, lng);
    return sameAnchor ? (pager: w.pager, items: w.items) : null;
  }

  /// Forget everything warmed or claimed (sign-out / account switch).
  void reset() {
    _epoch++;
    _jobs.clear();
    _warm.clear();
    _claimed.clear();
  }
}
