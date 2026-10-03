import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/first_screen_gate.dart';
import '../../../../core/utils/geo_query.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/data/datasources/external_events_pager.dart';
import '../../../events/data/datasources/external_events_preloader.dart';
import '../../../events/domain/entities/external_event.dart';
import '../../../events/domain/feed_interleave.dart';
import '../../../events/presentation/widgets/attraction_menu_dialog.dart';
import '../../../events/presentation/widgets/external_event_tiles.dart';
import '../../../events/presentation/widgets/interleaved_feed_view.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';
import '../experience_feed_prefetch.dart';
import '../experience_first_page_cache.dart';
import '../screens/experience_detail_screen.dart';
import 'experience_widgets.dart';

/// One row of the merged Experiences feed: a member-hosted experience or a
/// partner (Viator) one.
class _ExpItem {
  _ExpItem.community(UserExperience this.community, this.distanceKm)
      : partner = null;
  _ExpItem.partner(ExternalEvent this.partner, this.distanceKm)
      : community = null;

  final UserExperience? community;
  final ExternalEvent? partner;
  final double? distanceKm;

  FeedSortKey get key => FeedSortKey(distanceKm: distanceKm);
}

/// Experiences → "All": published community experiences merged with the
/// partner (Viator) feed, both paged 20 at a time.
///
/// Ordering: with the viewer's location known and the Distance sort, both
/// sources arrive nearest-first (community geohash rings / Viator geohash
/// rings), so they are merged NEAREST-FIRST. Otherwise the two feeds have no
/// common key — community is newest-first while partner follows the chosen
/// Stars / Reviews / Date order — so they are interleaved ROUND-ROBIN
/// (community, partner, …), which keeps each feed's own order intact and
/// gives both equal visibility instead of letting one side bury the other.
class MergedExperiencesFeed extends StatefulWidget {
  const MergedExperiencesFeed({
    super.key,
    required this.currentUserId,
    required this.gridView,
    required this.sort,
    this.query = '',
    this.userLat,
    this.userLng,
  });

  final String currentUserId;
  final bool gridView;

  /// Partner sort: distance | rating | reviews | date.
  final String sort;
  final String query;
  final double? userLat;
  final double? userLng;

  @override
  State<MergedExperiencesFeed> createState() => _MergedExperiencesFeedState();
}

class _MergedExperiencesFeedState extends State<MergedExperiencesFeed> {
  // Community search is a server query: debounce it like the Community tab.
  late String _query = widget.query.trim();
  Timer? _debounce;
  int _reloadTick = 0;

  @override
  void didUpdateWidget(MergedExperiencesFeed old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _query = widget.query.trim());
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  bool get _hasLocation => widget.userLat != null && widget.userLng != null;
  bool get _byDistance => widget.sort == 'distance' && _hasLocation;

  double? _km(double? lat, double? lng) {
    if (!_hasLocation || lat == null || lng == null) return null;
    return GeoQuery.distanceMeters(widget.userLat!, widget.userLng!, lat, lng) /
        1000;
  }

  static const ExperienceFirstPageCache _firstPages = ExperienceFirstPageCache();

  /// LastResultCache key of the community side's first page (unsearched
  /// view only), bucketed to the viewer's ~5km geohash cell.
  String get _communityCacheKey =>
      ExperienceFeedPrefetch.allFeedKey(widget.userLat, widget.userLng);

  FeedSource<_ExpItem> _community() {
    var pager = di.sl<UserExperiencesRepository>().communityFeed(
          lat: widget.userLat,
          lng: widget.userLng,
          query: _query,
        );
    _ExpItem map(UserExperience e) => _ExpItem.community(e, _km(e.lat, e.lng));
    if (_query.isNotEmpty) {
      return PagerFeedSource<UserExperience, _ExpItem>(
        hasMore: () => pager.hasMore,
        next: pager.next,
        map: map,
      );
    }
    final key = _communityCacheKey;
    return CachedFirstPageFeedSource<UserExperience, _ExpItem>(
      // Last session's first page, from the local cache (instant).
      cached: () => _firstPages.load(key),
      first: () async {
        // Adopt the background-warmed first page when it is this view.
        final warm = await ExperienceFeedPrefetch.take(
            lat: widget.userLat, lng: widget.userLng);
        if (warm != null) {
          pager = warm.pager;
          return warm.items;
        }
        final page = await pager.next();
        unawaited(_firstPages.save(key, page));
        return page;
      },
      next: () => pager.next(),
      hasMore: () => pager.hasMore,
      id: (e) => e.id,
      map: map,
    );
  }

  FeedSource<_ExpItem> _partner() {
    var pager = ExternalEventsPager(
      source: 'viator',
      sort: widget.sort,
      userLat: widget.userLat,
      userLng: widget.userLng,
    );
    return CachedFirstPageFeedSource<ExternalEvent, _ExpItem>(
      // Last session's first page of this view, from the local cache.
      cached: pager.loadCached,
      first: () async {
        // The background preloader warms exactly the distance view: adopt
        // its pager + first page instead of re-reading them.
        if (widget.sort == 'distance') {
          final warm = await ExternalEventsPreloader.instance
              .take('viator', lat: widget.userLat, lng: widget.userLng);
          if (warm != null) {
            pager = warm.pager;
            return warm.items;
          }
        }
        final page = await pager.next();
        unawaited(pager.saveFirstPage(page));
        return page;
      },
      next: () => pager.next(),
      hasMore: () => pager.hasMore,
      id: (e) => e.id,
      map: (e) => _ExpItem.partner(e, _km(e.lat, e.lng)),
    );
  }

  /// Partner search is client-side over the downloaded pages (as in the
  /// Partner view); community items already match the server-side query.
  bool _keep(_ExpItem x) {
    final p = x.partner;
    final q = widget.query.trim().toLowerCase();
    if (p == null || q.isEmpty) return true;
    return p.title.toLowerCase().contains(q) ||
        (p.city ?? '').toLowerCase().contains(q) ||
        (p.country ?? '').toLowerCase().contains(q);
  }

  Future<void> _openCommunity(UserExperience e) async {
    final r = await Navigator.of(context).push(ExperienceDetailScreen.route(
        experienceId: e.id, currentUserId: widget.currentUserId, initial: e));
    // Edited / unpublished / deleted: re-query so the merged list is truthful.
    if (mounted && (r?.deletedId != null || r?.updated != null)) {
      setState(() => _reloadTick++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final anchor = '${widget.userLat},${widget.userLng}';
    return InterleavedFeedView<_ExpItem>(
      sourceKeyA: 'c|$anchor|$_query|$_reloadTick',
      sourceKeyB: 'p|$anchor|${widget.sort}',
      filterKey: widget.query.trim(),
      createA: _community,
      createB: _partner,
      filter: _keep,
      compare: _byDistance
          ? (a, b) => compareNearestThenSoonest(a.key, b.key)
          : null,
      gridView: widget.gridView,
      listItemExtent: 300,
      // First screen in one go: the first viewport's pictures decoded first
      // (member cards decode at their real width: the grid cell, or the list
      // card's inner width).
      firstScreenImage: (context, x, grid, viewport) {
        final c = x.community;
        if (c == null) {
          return externalEventImageProvider(context, x.partner!, grid: grid);
        }
        final width = grid
            ? gridCellWidth(viewport.width, eventsGridColumns(context))
            : ExperienceCard.listImageWidth(viewport.width - 24);
        return ExperienceImage.providerFor(context, c.mainPhotoUrl, width);
      },
      itemBuilder: (context, x, grid) {
        final c = x.community;
        if (c != null) {
          return ExperienceCard(
            experience: c,
            compact: grid,
            distanceKm: grid ? null : x.distanceKm,
            onTap: () => _openCommunity(c),
          );
        }
        final p = x.partner!;
        void open() => showAttractionMenu(context,
            event: p, currentUserId: widget.currentUserId);
        return grid
            ? ExternalEventGridTile(
                event: p, onTap: open, showPartnerBadge: true)
            : ExternalEventCard(event: p, onTap: open, showPartnerBadge: true);
      },
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.travel_explore,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(l.uexpEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
