import 'package:geolocator/geolocator.dart';

import '../../domain/entities/external_event.dart';
import 'external_events_pager.dart';

/// Warms attractions (geoapify) and experiences (viator) in the background as
/// soon as the user enters the app, so opening Events shows them instantly.
///
/// It runs the same server-ordered first page the tab would (nearest-first via
/// geohash, using the last-known location), and keeps the pager + first page in
/// memory. ExperiencesTab adopts the warmed pager for the default view, so it
/// renders immediately and keeps paging from where the preload left off.
class ExternalEventsPreloader {
  ExternalEventsPreloader._();
  static final ExternalEventsPreloader instance = ExternalEventsPreloader._();

  static const List<String> _sources = ['geoapify', 'viator'];

  final Map<String, ExternalEventsPager> _pagers = {};
  final Map<String, List<ExternalEvent>> _firstPage = {};
  bool _started = false;

  /// Fire-and-forget; runs once per session.
  Future<void> warm() async {
    if (_started) return;
    _started = true;
    double? lat, lng;
    try {
      final pos = await Geolocator.getLastKnownPosition();
      lat = pos?.latitude;
      lng = pos?.longitude;
    } catch (_) {/* no location → warm by default order */}
    for (final source in _sources) {
      try {
        final pager = ExternalEventsPager(
          source: source,
          sort: 'distance',
          userLat: lat,
          userLng: lng,
        );
        final first = await pager.next();
        _pagers[source] = pager;
        _firstPage[source] = first;
      } catch (_) {/* best-effort */}
    }
  }

  /// Returns the warmed pager + first page for [source] to adopt (once), or null
  /// if not warmed. Removing it hands ownership to the caller.
  ({ExternalEventsPager pager, List<ExternalEvent> items})? take(String source) {
    final pager = _pagers.remove(source);
    final items = _firstPage.remove(source);
    if (pager == null) return null;
    return (pager: pager, items: items ?? const []);
  }

  void reset() {
    _started = false;
    _pagers.clear();
    _firstPage.clear();
  }
}
