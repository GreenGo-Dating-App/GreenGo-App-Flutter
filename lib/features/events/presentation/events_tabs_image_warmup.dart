import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/utils/display_image.dart';
import '../../../core/utils/first_screen_gate.dart';
import '../../attractions/data/attractions_prefetch.dart';
import '../../attractions/data/datasources/attractions_datasource.dart';
import '../../user_experiences/presentation/experience_feed_prefetch.dart';
import '../../user_experiences/presentation/widgets/experience_widgets.dart';
import '../data/datasources/external_events_preloader.dart';
import '../data/services/events_location.dart';
import '../data/services/events_prefetch.dart';

/// Decodes the images of the FIRST visible rows of each Events-page tab
/// (Events "All", Attractions, Experiences "All") from what [EventsPrefetch]
/// warmed, so the tabs' first-screen gate ([FirstScreenGate]) usually finds
/// them decoded already and shows the first screen without waiting.
///
/// Non-blocking and bounded: runs after the prefetch (itself after the first
/// paint), at most [rowsPerSource] grid rows per source, once per account per
/// session. Images are decoded at the grid tile's size (the tabs' default
/// layout) through the same provider the tiles use, so the warmed ImageCache
/// entry is the one they paint; anything else still lands in the disk cache.
class EventsTabsImageWarmup {
  EventsTabsImageWarmup._();

  /// Grid rows warmed per source (a phone's first screen shows ~3-4 rows of
  /// a merged feed, shared by its two sources).
  static const int rowsPerSource = 2;
  static String? _doneFor;

  /// Columns of the Events-page grids (= `eventsGridColumns`).
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 1100 ? 6 : (w >= 800 ? 4 : 3);
  }

  /// Must match the Events-page grids (events / partner / attraction tiles).
  static int gridMemCacheWidth(BuildContext context) {
    final mq = MediaQuery.of(context);
    return (mq.size.width / gridColumns(context) * mq.devicePixelRatio)
        .round()
        .clamp(64, 4096);
  }

  /// The images to warm, in tab order: (url, member) where [member] marks a
  /// member-hosted experience photo (decoded at its grid CELL width, as
  /// `ExperienceImage` does). Pure apart from reading the warm-ups.
  static List<({String url, bool member})> firstRows(int perSource) {
    final anchor = EventsLocation.current;
    final out = <({String url, bool member})>[];
    final seen = <String>{};
    void add(String? url, {bool member = false}) {
      if (DisplayImage.isUsableUrl(url) && seen.add(url!)) {
        out.add((url: url, member: member));
      }
    }

    // Events → All (soonest first by default): community + partner (date).
    final community = [...EventsPrefetch.peekCommunity()]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    community.take(perSource).forEach((e) => add(e.imageUrl));
    ExternalEventsPreloader.instance
        .peek('ticketmaster', sort: 'date')
        .take(perSource)
        .forEach((e) => add(e.imageUrl));

    // Attractions (nearest first; 'thumb' is what the grid tile renders).
    final bucket = AttractionsDataSource.cachedBucket;
    if (bucket != null) {
      for (final a in AttractionsPrefetch.firstItems(perSource,
          lat: anchor?.lat, lng: anchor?.lng)) {
        add(a.imageUrl('thumb', bucket: bucket));
      }
    }

    // Experiences → All: member-hosted + partner (Viator).
    ExperienceFeedPrefetch.peek()
        .take(perSource)
        .forEach((e) => add(e.mainPhotoUrl, member: true));
    ExternalEventsPreloader.instance
        .peek('viator')
        .take(perSource)
        .forEach((e) => add(e.imageUrl));
    return out;
  }

  /// The URLs to warm, in tab order (see [firstRows]).
  static List<String> firstRowUrls({int perSource = 3}) =>
      [for (final r in firstRows(perSource)) r.url];

  /// Fire-and-forget. Never throws.
  static void run(BuildContext context, String userId) {
    if (_doneFor == userId || !context.mounted) return;
    _doneFor = userId;
    try {
      final cols = gridColumns(context);
      final memW = gridMemCacheWidth(context);
      final cellW = gridCellWidth(MediaQuery.of(context).size.width, cols);
      for (final r in firstRows(cols * rowsPerSource)) {
        final provider = r.member
            ? ExperienceImage.providerFor(context, r.url, cellW)
            : cachedNetworkImageProvider(r.url, memCacheWidth: memW);
        if (provider == null) continue;
        unawaited(precacheImage(
          provider,
          context,
          onError: (_, __) {/* the tile shows its own fallback */},
        ).catchError((Object _) {}));
      }
    } catch (_) {/* best-effort */}
  }

  /// Sign-out / account switch.
  static void reset() => _doneFor = null;
}
