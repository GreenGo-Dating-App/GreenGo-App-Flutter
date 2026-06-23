import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/external_events_data_source.dart';
import '../../data/datasources/external_events_pager.dart';
import '../../domain/entities/external_event.dart';
import 'share_external_sheet.dart';

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
  final _scroll = ScrollController();

  /// Items downloaded so far, already in server order.
  final List<ExternalEvent> _items = [];
  ExternalEventsPager? _pager;
  bool _loadingMore = false;
  bool _firstLoadDone = false;
  int _gen = 0; // bumped per reload so stale pages can't append

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
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
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loadingMore) return;
    if (_scroll.position.maxScrollExtent - _scroll.position.pixels < 400) {
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

  Future<void> _book(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Tap action for any external card → the chooser window (visit links /
  /// open in maps / share).
  void _open(ExternalEvent e) => _showLinkMenu(e);

  String? _mapsUrl(ExternalEvent e) {
    if (e.lat != null && e.lng != null) {
      return 'https://www.google.com/maps/search/?api=1&query=${e.lat},${e.lng}';
    }
    final place = '${e.title} ${e.city ?? ''}'.trim();
    if (place.isEmpty) return null;
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place)}';
  }

  /// A pop-up window with the attraction image on the left and the link options
  /// on the right (mega-menu style).
  void _showLinkMenu(ExternalEvent e) {
    final l10n = AppLocalizations.of(context)!;
    final maps = _mapsUrl(e);
    final seen = <String>{};
    final options = <Widget>[];

    Widget actionTile(IconData icon, String label, VoidCallback onTap) =>
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.richGold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textTertiary, size: 18),
              ],
            ),
          ),
        );

    // A "Visit <domain>" link, de-duplicated by host.
    void addLink(IconData icon, String label, String url) {
      if (url.isEmpty) return;
      final host = _hostOf(url);
      if (host.isNotEmpty && !seen.add(host)) return;
      options.add(actionTile(icon, label, () {
        Navigator.pop(context);
        _book(url);
      }));
    }

    // Primary destination (provider page / official website / Wikidata page).
    final primaryHost = _hostOf(e.bookingUrl);
    addLink(
        Icons.open_in_new,
        '${l10n.attractionOpenLink}${primaryHost.isNotEmpty ? '  ·  $primaryHost' : ''}',
        e.bookingUrl);
    if (e.website != null && e.website!.isNotEmpty) {
      addLink(Icons.public, l10n.attractionOpenWebsite, e.website!);
    }
    if (e.wikidataUrl != null && e.wikidataUrl!.isNotEmpty) {
      addLink(Icons.menu_book, l10n.attractionVisitWikidata, e.wikidataUrl!);
    }
    if (maps != null) {
      options.add(actionTile(Icons.map, l10n.attractionOpenInMaps, () {
        Navigator.pop(context);
        _book(maps);
      }));
    }
    // Share — split into chat and group targets.
    options.add(actionTile(Icons.chat_bubble_outline, l10n.attractionShareChat,
        () {
      Navigator.pop(context);
      showShareExternalSheet(context,
          item: e, currentUserId: widget.currentUserId, mode: 'chats');
    }));
    options.add(actionTile(Icons.groups, l10n.attractionShareGroup, () {
      Navigator.pop(context);
      showShareExternalSheet(context,
          item: e, currentUserId: widget.currentUserId, mode: 'groups');
    }));

    final place = [e.city, e.country]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.backgroundCard,
        clipBehavior: Clip.antiAlias,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.62),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: image
                SizedBox(
                  width: 130,
                  child: (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: e.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _imgPlaceholder(e, 160),
                        )
                      : _imgPlaceholder(e, 160),
                ),
                // Right: info (title, place, description) + options
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        if (place.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place,
                                  size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(place,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                        if (e.description != null &&
                            e.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(e.description!,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.3)),
                        ],
                        const Divider(height: 18, color: AppColors.divider),
                        ...options,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

    if (widget.gridView) {
      return RefreshIndicator(
        color: AppColors.richGold,
        onRefresh: _refresh,
        child: GridView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.62,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _gridTile(items[i]),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: _refresh,
      child: ListView.builder(
      controller: _scroll,
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
      ),
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
