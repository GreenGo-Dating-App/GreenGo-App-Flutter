import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/external_events_data_source.dart';
import '../../domain/entities/external_event.dart';
import 'share_external_sheet.dart';

/// Experiences tab — Viator experiences with **infinite scroll**.
/// Loads pages from `external_events` (ordered by rating) as the user scrolls.
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
  final List<ExternalEvent> _items = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = false;
  bool _hasMore = true;
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void didUpdateWidget(ExperiencesTab old) {
    super.didUpdateWidget(old);
    // Switching Popular/source, or location arriving, changes the dataset.
    if (old.popular != widget.popular ||
        old.source != widget.source ||
        old.sort != widget.sort ||
        old.userLat != widget.userLat ||
        old.userLng != widget.userLng) {
      _items.clear();
      _cursor = null;
      _hasMore = !widget.popular;
      _firstLoadDone = false;
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || !_hasMore) return;
    if (_scroll.position.maxScrollExtent - _scroll.position.pixels < 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    // Popular = a fixed top set (single load).
    if (widget.popular) {
      if (_firstLoadDone) return;
      setState(() => _loading = true);
      final items =
          await _ds.getPopularExperiences(source: widget.source, limit: 60);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _hasMore = false;
        _loading = false;
        _firstLoadDone = true;
      });
      return;
    }
    if (!_hasMore) return;
    setState(() => _loading = true);
    final page = await _ds.getExperiencesPage(
      source: widget.source,
      sort: widget.sort,
      startAfter: _cursor,
      limit: 20,
      userLat: widget.userLat,
      userLng: widget.userLng,
    );
    if (!mounted) return;
    setState(() {
      _items.addAll(page.items);
      _cursor = page.cursor;
      _hasMore = page.cursor != null && page.items.isNotEmpty;
      _loading = false;
      _firstLoadDone = true;
    });
  }

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

    // Trailing loader only when more pages exist and we're not filtering.
    final showLoader = _hasMore && widget.query.isEmpty;

    if (widget.gridView) {
      return GridView.builder(
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
      );
    }

    return ListView.builder(
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
    );
  }

  Widget _badge(ExternalEvent e) {
    final color = e.source == 'tiqets'
        ? Colors.purple
        : e.source == 'ticketmaster'
            ? Colors.indigo
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
