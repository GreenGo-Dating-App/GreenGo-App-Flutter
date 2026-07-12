import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/external_events_data_source.dart';
import '../../data/datasources/external_events_pager.dart';
import '../../data/datasources/external_events_preloader.dart';
import '../../domain/entities/external_event.dart';
import 'attraction_menu_dialog.dart';

/// Experiences tab — external events (Experiences/Attractions/Live Events) with
/// **infinite scroll**, downloaded already filtered & ordered from Firestore:
/// distance (default) via expanding geohash rings, otherwise orderBy
/// date/stars/reviews. No client-side global re-sort — pages arrive in order.
class ExperiencesTab extends StatefulWidget {
  const ExperiencesTab({
    super.key,
    required this.gridView,
    required this.query,
    this.popular = false,
    this.source = 'viator',
    this.userLat,
    this.userLng,
    this.sort = 'distance',
    this.category,
    this.currentUserId = '',
  });

  final bool gridView;
  final String query;
  final bool popular;
  final String source;
  final double? userLat;
  final double? userLng;
  final String sort; // distance | rating | reviews | date
  final String? category; // optional category filter (Attractions tab)
  final String currentUserId;

  @override
  State<ExperiencesTab> createState() => _ExperiencesTabState();
}

class _ExperiencesTabState extends State<ExperiencesTab> {
  final _ds = ExternalEventsDataSource();
  // Grid and list each get their OWN ScrollController. A single controller can
  // only be attached to one ScrollPosition; sharing it across the GridView and
  // ListView branches threw "attached to multiple/no positions" while the view
  // toggle swapped them, aborting the rebuild and leaving the tab stuck on its
  // previous layout. Only one branch is ever mounted, so only one attaches.
  final _gridScroll = ScrollController();
  final _listScroll = ScrollController();

  /// Items downloaded so far, already in server order.
  final List<ExternalEvent> _items = [];
  ExternalEventsPager? _pager;
  bool _loadingMore = false;
  bool _firstLoadDone = false;
  int _gen = 0; // bumped per reload so stale pages can't append

  @override
  void initState() {
    super.initState();
    _gridScroll.addListener(_onScroll);
    _listScroll.addListener(_onScroll);
    _reload();
  }

  @override
  void didUpdateWidget(ExperiencesTab old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source ||
        old.popular != widget.popular ||
        old.sort != widget.sort ||
        old.category != widget.category ||
        old.userLat != widget.userLat ||
        old.userLng != widget.userLng) {
      _reload();
    }
  }

  @override
  void dispose() {
    _gridScroll.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Whichever branch is currently mounted owns the live position.
    final c = _gridScroll.hasClients
        ? _gridScroll
        : (_listScroll.hasClients ? _listScroll : null);
    if (c == null || _loadingMore) return;
    if (c.position.maxScrollExtent - c.position.pixels < 400) {
      _loadMore();
    }
  }

  Future<void> _reload() async {
    final gen = ++_gen;
    setState(() {
      _items.clear();
      _firstLoadDone = false;
    });
    if (widget.popular) {
      final list =
          await _ds.getPopularExperiences(source: widget.source, limit: 60);
      if (!mounted || gen != _gen) return;
      setState(() {
        _items.addAll(list);
        _firstLoadDone = true;
      });
      return;
    }
    // Adopt the background-preloaded pager for the default view (distance, no
    // category) so attractions/experiences appear instantly on first open.
    if (widget.sort == 'distance' &&
        (widget.category == null || widget.category!.isEmpty)) {
      final warm = ExternalEventsPreloader.instance.take(widget.source);
      if (warm != null) {
        _pager = warm.pager;
        if (!mounted || gen != _gen) return;
        setState(() {
          _items.addAll(warm.items);
          _firstLoadDone = true;
        });
        return;
      }
    }
    _pager = ExternalEventsPager(
      source: widget.source,
      sort: widget.sort,
      category: widget.category,
      userLat: widget.userLat,
      userLng: widget.userLng,
    );
    await _loadMore(gen: gen, first: true);
  }

  Future<void> _loadMore({int? gen, bool first = false}) async {
    final g = gen ?? _gen;
    final pager = _pager;
    if (pager == null || _loadingMore) return;
    if (!first && !pager.hasMore) return;
    _loadingMore = true;
    final page = await pager.next();
    if (!mounted || g != _gen) {
      _loadingMore = false;
      return;
    }
    setState(() {
      _items.addAll(page);
      _firstLoadDone = true;
      _loadingMore = false;
    });
  }

  /// Downloaded items, with the (client-side) free-text search applied over what
  /// has loaded so far. Order is the server order — no re-sort here.
  List<ExternalEvent> get _filtered {
    final q = widget.query.toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            (e.city ?? '').toLowerCase().contains(q) ||
            (e.country ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// Tap action for any external card → the attraction/experience window
  /// (image + info + actions: open link / official website / wikidata / maps /
  /// share to chat / share to group / report).
  void _open(ExternalEvent e) =>
      showAttractionMenu(context, event: e, currentUserId: widget.currentUserId);

  /// Pull-to-refresh: re-query from the server.
  Future<void> _refresh() => _reload();

  @override
  Widget build(BuildContext context) {
    if (!_firstLoadDone) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.richGold));
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.eventsNoEventsFound,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    // Trailing loader while more pages are available (server-ordered download).
    final showLoader =
        widget.query.isEmpty && (_pager?.hasMore ?? false);

    // ONE stable RefreshIndicator wraps whichever scroll view is active.
    // Each view branch used to return its OWN RefreshIndicator; toggling grid→
    // list reconciled those two same-typed indicators into a single reused
    // element while its child swapped from the GridView (bound to _gridScroll)
    // to the ListView (bound to _listScroll). The reused indicator kept its
    // scroll-notification wiring bound to the outgoing position, so the incoming
    // list mounted against a stale position and rendered blank. Hoisting a
    // single RefreshIndicator (as the community tab does) and giving each scroll
    // view a distinct key makes the swap clean, so the list shows the events.
    final Widget child;
    if (widget.gridView) {
      final w = MediaQuery.of(context).size.width;
      final cols = w >= 1100 ? 6 : (w >= 800 ? 4 : 3);
      child = GridView.builder(
        key: const ValueKey('expGrid'),
        controller: _gridScroll,
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.62,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => _gridTile(items[i]),
      );
    } else {
      child = ListView.builder(
        key: const ValueKey('expList'),
        controller: _listScroll,
        padding: const EdgeInsets.all(12),
        itemCount: items.length + (showLoader ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.richGold)),
            );
          }
          return _card(items[i]);
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: _refresh,
      child: child,
    );
  }

  /// Hostname of a URL without the leading "www." (e.g. "curitiba.pr.gov.br").
  String _hostOf(String url) {
    try {
      final h = Uri.parse(url).host;
      return h.startsWith('www.') ? h.substring(4) : h;
    } catch (_) {
      return '';
    }
  }

  Widget _badge(ExternalEvent e) {
    final color = e.source == 'tiqets' || e.source == 'geoapify'
        ? Colors.purple
        : e.source == 'ticketmaster'
            ? Colors.indigo
            : e.source == 'google'
                ? Colors.green
                : Colors.teal;
    // Show the destination domain (viator.com, ticketmaster.com,
    // curitiba.pr.gov.br, …) instead of a generic source label.
    final host = _hostOf(e.bookingUrl);
    final label = host.isNotEmpty ? host : e.sourceLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _price(ExternalEvent e) {
    if (e.fromPrice == null) return '';
    final l10n = AppLocalizations.of(context)!;
    return '${l10n.eventsFromPrice} ${e.currency ?? ''} ${e.fromPrice!.toStringAsFixed(0)}';
  }

  Widget _img(ExternalEvent e, double height) {
    if (e.imageUrl != null && e.imageUrl!.isNotEmpty) {
      // CachedNetworkImage keeps a persistent disk cache keyed by URL, so an
      // event image is downloaded once and reused across sessions; it only
      // re-downloads when the URL changes (i.e. the server refreshed the event).
      return CachedNetworkImage(
        imageUrl: e.imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (c, _) => Container(
          height: height,
          color: AppColors.backgroundInput,
          child: const Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.richGold))),
        ),
        errorWidget: (_, __, ___) => _imgPlaceholder(e, height),
      );
    }
    return _imgPlaceholder(e, height);
  }

  /// Category-themed placeholder shown when an event has no image (or it failed
  /// to load).
  Widget _imgPlaceholder(ExternalEvent e, double height) {
    IconData icon;
    switch (e.category) {
      case 'museum':
        icon = Icons.museum;
        break;
      case 'park':
      case 'national_park':
        icon = Icons.park;
        break;
      case 'theme_park':
        icon = Icons.attractions;
        break;
      default:
        icon = Icons.place;
    }
    return Container(
        height: height,
        width: double.infinity,
        color: AppColors.backgroundInput,
        child: Icon(icon, color: AppColors.textTertiary, size: 32));
  }

  Widget _card(ExternalEvent e) {
    return GestureDetector(
      onTap: () => _open(e),
      child:Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: _img(e, 160),
                ),
                Positioned(top: 8, left: 8, child: _badge(e)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  if (e.startDate != null && e.startDate!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event,
                            size: 14, color: AppColors.richGold),
                        const SizedBox(width: 4),
                        Text(e.startDate!,
                            style: const TextStyle(
                                color: AppColors.richGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          [e.city, e.country]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      if (e.rating != null && e.rating! > 0) ...[
                        const Icon(Icons.star,
                            size: 14, color: AppColors.richGold),
                        const SizedBox(width: 2),
                        Text('${e.rating}',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                        if (e.reviewCount != null && e.reviewCount! > 0)
                          Text(' (${e.reviewCount})',
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 11)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_price(e),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      ElevatedButton.icon(
                        onPressed: () => _open(e),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(AppLocalizations.of(context)!.eventsBook),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridTile(ExternalEvent e) {
    return GestureDetector(
      onTap: () => _open(e),
      child:ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColors.backgroundCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _img(e, double.infinity),
                    Positioned(top: 4, left: 4, child: _badge(e)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    if (e.startDate != null && e.startDate!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.event,
                            size: 10, color: AppColors.richGold),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(e.startDate!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.richGold, fontSize: 10)),
                        ),
                      ]),
                    ],
                    if ([e.city, e.country]
                        .any((s) => s != null && s.isNotEmpty)) ...[
                      const SizedBox(height: 2),
                      Text(
                        [e.city, e.country]
                            .where((s) => s != null && s.isNotEmpty)
                            .join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (e.rating != null && e.rating! > 0) ...[
                          const Icon(Icons.star,
                              size: 10, color: AppColors.richGold),
                          Text('${e.rating}',
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 10)),
                          const Spacer(),
                        ],
                        if (e.fromPrice != null)
                          Text(
                              '${e.currency ?? ''}${e.fromPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppColors.richGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
