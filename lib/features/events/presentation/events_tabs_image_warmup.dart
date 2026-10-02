import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../../../core/utils/display_image.dart';
import '../../attractions/data/attractions_prefetch.dart';
import '../../attractions/data/datasources/attractions_datasource.dart';
import '../../user_experiences/presentation/experience_feed_prefetch.dart';
import '../data/datasources/external_events_preloader.dart';
import '../data/services/events_location.dart';
import '../data/services/events_prefetch.dart';

/// Decodes the images of the FIRST visible row of each Events-page tab
/// (Events "All", Attractions, Experiences "All") from what [EventsPrefetch]
/// warmed, so a tab opens with its pictures already painted.
///
/// Non-blocking and bounded: runs after the prefetch (itself after the first
/// paint), at most [perSource] images per source, once per account per
/// session. Images are decoded at the grid tile's width (the tabs' default
/// layout) through the same provider the tiles use, so the warmed ImageCache
/// entry is the one they paint; anything else still lands in the disk cache.
class EventsTabsImageWarmup {
  EventsTabsImageWarmup._();

  static const int perSource = 3;
  static String? _doneFor;

  /// Must match the Events-page grids (events / partner / attraction tiles).
  static int gridMemCacheWidth(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final cols = w >= 1100 ? 6 : (w >= 800 ? 4 : 3);
    return (w / cols * mq.devicePixelRatio).round().clamp(64, 4096);
  }

  /// The URLs to warm, in tab order. Pure apart from reading the warm-ups.
  static List<String> firstRowUrls() {
    final anchor = EventsLocation.current;
    final urls = <String>[];
    void add(String? url) {
      if (DisplayImage.isUsableUrl(url) && !urls.contains(url)) urls.add(url!);
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
        .forEach((e) => add(e.mainPhotoUrl));
    ExternalEventsPreloader.instance
        .peek('viator')
        .take(perSource)
        .forEach((e) => add(e.imageUrl));
    return urls;
  }

  /// Fire-and-forget. Never throws.
  static void run(BuildContext context, String userId) {
    if (_doneFor == userId || !context.mounted) return;
    _doneFor = userId;
    try {
      final memW = gridMemCacheWidth(context);
      for (final url in firstRowUrls()) {
        unawaited(precacheImage(
          ResizeImage.resizeIfNeeded(
              memW, null, CachedNetworkImageProvider(url)),
          context,
          onError: (_, __) {/* the tile shows its own fallback */},
        ).catchError((Object _) {}));
      }
    } catch (_) {/* best-effort */}
  }

  /// Sign-out / account switch.
  static void reset() => _doneFor = null;
}
