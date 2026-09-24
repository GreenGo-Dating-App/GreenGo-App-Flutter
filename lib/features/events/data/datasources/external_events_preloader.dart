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

  static const List<String> _sources = ['ticketmaster', 'viator'];

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
    final todo = _sources
        .where((s) => !_jobs.containsKey(s) && !_claimed.contains(s))
        .toList();
    if (todo.isEmpty) return;
    final anchorFuture = EventsLocation.quick(
        userId ?? FirebaseAuth.instance.currentUser?.uid ?? '');
    final epoch = _epoch;
    for (final source in todo) {
      _jobs[source] = () async {
        try {
          final anchor = await anchorFuture;
          // Claims are honoured only BEFORE the read starts; once started, the
          // result is always stored so a tab waiting in [take] receives it.
          if (_claimed.contains(source) || epoch != _epoch) return;
          final pager = ExternalEventsPager(
            source: source,
            sort: 'distance',
            userLat: anchor?.lat,
            userLng: anchor?.lng,
          );
          final first = await pager.next();
          if (epoch != _epoch) return;
          _warm[source] = (pager: pager, items: first, at: DateTime.now());
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
  Future<({ExternalEventsPager pager, List<ExternalEvent> items})?> take(
      String source,
      {double? lat,
      double? lng}) async {
    _claimed.add(source);
    final job = _jobs[source];
    if (job != null) await job;
    final w = _warm.remove(source);
    if (w == null) return null;
    if (DateTime.now().difference(w.at) > _maxAge) return null;
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
