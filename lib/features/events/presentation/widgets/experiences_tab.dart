import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../core/services/city_coordinates_service.dart';
import '../../../../core/services/external_events_index_service.dart';
import '../../data/datasources/external_events_data_source.dart';
import '../../domain/entities/external_event.dart';
import 'share_external_sheet.dart';

/// Experiences tab — external events (Experiences/Attractions/Live Events) with
/// **infinite scroll**. Loads the full source ONCE via the structured shard
/// index (ExternalEventsIndexService), then orders globally in memory by
/// distance (default) / date / stars / reviews and pages the result locally.
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
    this.currentUserId = '',
  });

  final bool gridView;
  final String query;
  final bool popular;
  final String source;
  final double? userLat;
  final double? userLng;
  final String sort; // distance | rating | reviews | date
  final String currentUserId;

  @override
  State<ExperiencesTab> createState() => _ExperiencesTabState();
}

class _ExperiencesTabState extends State<ExperiencesTab> {
  final _ds = ExternalEventsDataSource();
  final _scroll = ScrollController();
  static const int _pageSize = 24;

  /// The FULL set for this source, loaded once (structured shard index, with a
  /// raw-collection fallback). All ordering is done in memory over this list,
  /// so distance/date/stars/reviews are globally correct, not per-page.
  List<ExternalEvent> _all = [];
  int _visibleCount = _pageSize;
  bool _loading = false;
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // City→coords lookup (loaded once) so items without their own coordinates
    // can still be placed/sorted; unresolved items are hidden.
    CityCoordinatesService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    _load();
  }

  /// Resolved coordinates: the item's own, else the city lookup table.
  ({double lat, double lng})? _coordOf(ExternalEvent e) {
    if (e.lat != null && e.lng != null) return (lat: e.lat!, lng: e.lng!);
    if (e.city != null && e.city!.isNotEmpty) {
      return CityCoordinatesService.instance
          .coordsFor(e.city!, country: e.country);
    }
    return null;
  }

  double _distanceOf(ExternalEvent e) {
    final c = _coordOf(e);
    if (c == null || widget.userLat == null || widget.userLng == null) {
      return double.infinity;
    }
    const r = 6371.0;
    final dLat = (c.lat - widget.userLat!) * math.pi / 180;
    final dLng = (c.lng - widget.userLng!) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(widget.userLat! * math.pi / 180) *
            math.cos(c.lat * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  void didUpdateWidget(ExperiencesTab old) {
    super.didUpdateWidget(old);
    // Source/popular change → reload the dataset. Sort/query/location change →
    // just re-window the already-loaded list (instant, no refetch).
    if (old.source != widget.source || old.popular != widget.popular) {
      _load();
    } else if (old.sort != widget.sort ||
        old.query != widget.query ||
        old.userLat != widget.userLat ||
        old.userLng != widget.userLng) {
      setState(() => _visibleCount = _pageSize);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.maxScrollExtent - _scroll.position.pixels < 400) {
      final total = _filtered.length;
      if (_visibleCount < total) {
        setState(() =>
            _visibleCount = math.min(_visibleCount + _pageSize, total));
      }
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _visibleCount = _pageSize;
    });
    List<ExternalEvent> list;
    if (widget.popular) {
      list = await _ds.getPopularExperiences(source: widget.source, limit: 60);
    } else {
      list =
          await ExternalEventsIndexService.instance.ensureLoaded(widget.source);
    }
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
      _firstLoadDone = true;
    });
  }

  int _compareByDate(ExternalEvent a, ExternalEvent b) {
    final ad = (a.startDate == null || a.startDate!.isEmpty) ? '9999' : a.startDate!;
    final bd = (b.startDate == null || b.startDate!.isEmpty) ? '9999' : b.startDate!;
    return ad.compareTo(bd); // soonest first; undated last
  }

  /// Full, globally-ordered, search-filtered list (placeable items only).
  List<ExternalEvent> get _filtered {
    final q = widget.query.toLowerCase();
    final hasLoc = widget.userLat != null && widget.userLng != null;
    final list = _all.where((e) {
      // Hide items we can't place: no own coords AND city not in the lookup.
      if (_coordOf(e) == null) return false;
      if (q.isEmpty) return true;
      return e.title.toLowerCase().contains(q) ||
          (e.city ?? '').toLowerCase().contains(q) ||
          (e.country ?? '').toLowerCase().contains(q);
    }).toList();

    switch (widget.sort) {
      case 'date':
        list.sort(_compareByDate);
        break;
      case 'rating':
        list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'reviews':
        list.sort((a, b) => (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0));
        break;
      case 'distance':
      default:
        if (hasLoc) {
          list.sort((a, b) => _distanceOf(a).compareTo(_distanceOf(b)));
        } else {
          // No location yet → fall back to most-reviewed so the order is stable.
          list.sort((a, b) => (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0));
        }
    }
    return list;
  }

  Future<void> _book(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Pull-to-refresh: drop the cached index for this source and reload.
  Future<void> _refresh() async {
    if (!widget.popular) {
      ExternalEventsIndexService.instance.invalidate(widget.source);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstLoadDone) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.richGold));
    }
    final all = _filtered;
    if (all.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.eventsNoEventsFound,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    // In-memory pagination: show a growing window of the globally-sorted list.
    final items = all.take(_visibleCount).toList();
    final showLoader = _visibleCount < all.length;

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

  Widget _badge(ExternalEvent e) {
    final color = e.source == 'tiqets' || e.source == 'geoapify'
        ? Colors.purple
        : e.source == 'ticketmaster'
            ? Colors.indigo
            : e.source == 'google'
                ? Colors.green
                : Colors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(e.sourceLabel,
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
      return Image.network(
        e.imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, prog) => prog == null
            ? child
            : Container(
                height: height,
                color: AppColors.backgroundInput,
                child: const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.richGold)))),
        errorBuilder: (_, __, ___) => Container(
            height: height,
            color: AppColors.backgroundInput,
            child: const Icon(Icons.museum, color: AppColors.textTertiary)),
      );
    }
    return Container(
        height: height,
        color: AppColors.backgroundInput,
        child: const Icon(Icons.museum, color: AppColors.textTertiary));
  }

  Widget _card(ExternalEvent e) {
    return GestureDetector(
      onTap: () => _book(e.bookingUrl),
      onLongPress: () => showShareExternalSheet(context,
          item: e, currentUserId: widget.currentUserId),
      child: Container(
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
                        onPressed: () => _book(e.bookingUrl),
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
      onTap: () => _book(e.bookingUrl),
      onLongPress: () => showShareExternalSheet(context,
          item: e, currentUserId: widget.currentUserId),
      child: ClipRRect(
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
