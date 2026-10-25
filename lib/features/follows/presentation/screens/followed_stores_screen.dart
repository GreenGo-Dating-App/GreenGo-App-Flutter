import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/business_categories.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/utils/compact_count.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../core/utils/follow_name_normalizer.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../../../business/presentation/screens/business_storefront_screen.dart';
import '../../../profile/domain/entities/profile.dart';

/// The business accounts the signed-in user follows (own-profile "Stores"),
/// with a name search and category / place filters.
///
/// PRIVATE: only ever for the signed-in user's own uid (the place facets are
/// owner-only in the rules). Every page is ONE bounded query on the own
/// mirror ([FollowService.followedStoresPage], 30 per page, endless scroll):
/// the plain list in document-id order, or - with a search and / or filters
/// - the SERVER-side query over ALL followed stores on the server-written
/// store fields (prefix search on the name, equality on category / country /
/// city). The place options come from the owner's own place facets
/// ([FollowService.followedStoreCountries] / [FollowService.followedStoreCities]),
/// the categories from the full [BusinessCategories] list. Profiles come from
/// [UserDirectoryService] (cache-first, batched). Tap -> storefront.
class FollowedStoresScreen extends StatefulWidget {
  const FollowedStoresScreen({required this.userId, super.key});

  final String userId;

  /// Search typing -> query delay.
  static const Duration debounce = Duration(milliseconds: 300);

  static Route<void> route({required String userId}) => MaterialPageRoute<void>(
        builder: (_) => FollowedStoresScreen(userId: userId),
      );

  @override
  State<FollowedStoresScreen> createState() => _FollowedStoresScreenState();
}

/// One paged id list (the plain list, or one search / filter combination).
class _Paged {
  final List<String> ids = [];
  final Set<String> seen = {};
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool hasMore = true;
  bool loading = false;
  bool error = false;

  /// Bumped by [reset]: a late answer for an older request is dropped.
  int gen = 0;

  void reset() {
    gen++;
    ids.clear();
    seen.clear();
    cursor = null;
    hasMore = true;
    loading = false;
    error = false;
  }
}

/// The place filter: a country, optionally narrowed to one of its cities.
class _PlaceChoice {
  const _PlaceChoice({required this.country, this.cityLower = '', this.city = ''});

  /// "All places" (no place filter).
  static const _PlaceChoice none = _PlaceChoice(country: '');

  final String country;
  final String cityLower;
  final String city;
}

class _FollowedStoresScreenState extends State<FollowedStoresScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final _Paged _list = _Paged();
  final _Paged _results = _Paged();

  /// Loaded profiles of the rows (kept here: the directory's profile cache
  /// is bounded, a long list must not lose rows).
  final Map<String, Profile> _profiles = {};

  StoreFilter _filter = const StoreFilter();
  _PlaceChoice _place = _PlaceChoice.none;
  Timer? _debounce;

  FollowService get _service => di.sl<FollowService>();

  _Paged get _active => _filter.isEmpty ? _list : _results;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 600) _loadMore();
    });
    _loadMore();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    final p = _active;
    final filter = _filter;
    final gen = p.gen;
    if (p.loading || !p.hasMore || widget.userId.isEmpty) return;
    setState(() {
      p.loading = true;
      p.error = false;
    });
    try {
      final page = await _service.followedStoresPage(widget.userId,
          after: p.cursor, filter: filter);
      final ids = page.userIds.where((id) => id.isNotEmpty && p.seen.add(id)).toList();
      final need = ids.where((id) => !_profiles.containsKey(id)).toList();
      final resolved = need.isEmpty
          ? const <String, Profile?>{}
          : await UserDirectoryService.instance.resolveProfiles(need);
      if (!mounted || gen != p.gen) return;
      setState(() {
        for (final e in resolved.entries) {
          if (e.value != null) _profiles[e.key] = e.value!;
        }
        // Deleted / banned / suspended accounts are not listed.
        p.ids.addAll(ids.where((id) => _isListed(_profiles[id])));
        p.cursor = page.cursor;
        p.hasMore = page.hasMore;
        p.loading = false;
      });
      // A short first page (nothing to scroll) or a page that was entirely
      // filtered out must not stall the endless list.
      if (p.hasMore) WidgetsBinding.instance.addPostFrameCallback((_) => _fillViewport());
    } catch (_) {
      if (!mounted || gen != p.gen) return;
      setState(() {
        p.loading = false;
        p.error = true;
      });
    }
  }

  void _fillViewport() {
    if (!mounted || !_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 600) _loadMore();
  }

  static bool _isListed(Profile? p) =>
      p != null && p.accountStatus == 'active' && !p.isBanned;

  /// Switch to [next] (a new search and / or filter): a fresh result list;
  /// back to "no filter" returns to the plain list with its loaded pages.
  void _applyFilter(StoreFilter next) {
    if (next == _filter) return;
    setState(() {
      _filter = next;
      _results.reset();
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (!next.isEmpty || _list.ids.isEmpty) _loadMore();
  }

  StoreFilter _with({String? query, String? category, bool clearCategory = false, _PlaceChoice? place}) {
    final pl = place ?? _place;
    return StoreFilter(
      query: query ?? _filter.query,
      category: clearCategory ? null : (category ?? _filter.category),
      country: pl.country.isEmpty ? null : pl.country,
      cityLower: pl.cityLower.isEmpty ? null : pl.cityLower,
    );
  }

  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(FollowedStoresScreen.debounce, () => _applyFilter(_with(query: raw)));
    setState(() {}); // clear-button visibility
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _debounce?.cancel();
    _applyFilter(_with(query: ''));
  }

  void _clearFilters() {
    _place = _PlaceChoice.none;
    _applyFilter(_with(clearCategory: true, place: _PlaceChoice.none));
  }

  Future<void> _refresh() async {
    setState(() => _active.reset());
    await _loadMore();
  }

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _CategorySheet(selected: _filter.category),
    );
    if (picked == null || !mounted) return;
    _applyFilter(picked.isEmpty ? _with(clearCategory: true) : _with(category: picked));
  }

  Future<void> _pickPlace() async {
    final picked = await showModalBottomSheet<_PlaceChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _PlaceSheet(
        service: _service,
        userId: widget.userId,
        selected: _place,
      ),
    );
    if (picked == null || !mounted) return;
    _place = picked;
    _applyFilter(_with(place: picked));
  }

  Widget _searchBox(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          key: const Key('followed_stores_search'),
          controller: _searchCtrl,
          onChanged: _onQueryChanged,
          onSubmitted: (v) {
            _debounce?.cancel();
            _applyFilter(_with(query: v));
          },
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.richGold,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.backgroundCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            hintText: l10n.followedStoresSearchHint,
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textTertiary),
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.userFollowSearchClear,
                    icon: const Icon(Icons.close, color: AppColors.textTertiary),
                    onPressed: _clearSearch,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.35), width: 1),
            ),
          ),
        ),
      );

  Widget _filterBar(AppLocalizations l10n) {
    final category = _filter.category;
    final placeLabel = _place.country.isEmpty
        ? l10n.followedStoresFilterPlace
        : [
            if (_place.city.isNotEmpty) _place.city,
            localizedCountryName(l10n, _place.country),
          ].join(', ');
    final anyFilter = _filter.hasCategory || _filter.hasCountry;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterPill(
            key: const Key('followed_stores_filter_category'),
            icon: Icons.category_outlined,
            label: category == null || category.isEmpty
                ? l10n.followedStoresFilterCategory
                : localizedBusinessCategory(l10n, category),
            active: _filter.hasCategory,
            onTap: _pickCategory,
          ),
          _FilterPill(
            key: const Key('followed_stores_filter_place'),
            icon: Icons.place_outlined,
            label: placeLabel,
            active: _filter.hasCountry,
            onTap: _pickPlace,
          ),
          if (anyFilter)
            TextButton(
              key: const Key('followed_stores_clear_filters'),
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.richGold,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(l10n.followedStoresClearFilters),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = _active;
    final filtered = !_filter.isEmpty;

    Widget? message;
    if (p.ids.isEmpty && !p.hasMore && !p.loading) {
      message = Padding(
        key: const Key('followed_stores_empty'),
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              p.error
                  ? Icons.cloud_off_outlined
                  : filtered
                      ? Icons.search_off
                      : Icons.storefront_outlined,
              size: 36,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 10),
            Text(
              p.error
                  ? l10n.userFollowListError
                  : filtered
                      ? l10n.followedStoresNoResults
                      : l10n.userFollowEmptyStores,
              key: const Key('followed_stores_message'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            if (p.error)
              TextButton(
                onPressed: _loadMore,
                child: Text(l10n.retry, style: const TextStyle(color: AppColors.richGold)),
              ),
          ],
        ),
      );
    }
    final rows = p.ids.length;
    final showFooter = message == null && (p.loading || p.error || p.hasMore);
    // The search + filters only make sense once there is something to search.
    final showTools = filtered || _list.ids.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(l10n.userFollowStoresLabel,
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: RefreshIndicator(
        color: AppColors.richGold,
        onRefresh: _refresh,
        child: ListView.builder(
          key: const Key('followed_stores_list'),
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: (showTools ? 2 : 0) + (message != null ? 1 : rows) + (showFooter ? 1 : 0),
          itemBuilder: (context, i) {
            if (showTools) {
              if (i == 0) return _searchBox(l10n);
              if (i == 1) return _filterBar(l10n);
              i -= 2;
            }
            if (message != null) return message;
            if (i >= rows) {
              if (p.error) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: TextButton(
                      onPressed: _loadMore,
                      child: Text(
                        '${l10n.userFollowListError} ${l10n.retry}',
                        style: const TextStyle(color: AppColors.richGold),
                      ),
                    ),
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
              );
            }
            final store = _profiles[p.ids[i]]!;
            return FollowedStoreRow(
              key: ValueKey('followed_store_${store.userId}'),
              store: store,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BusinessStorefrontScreen(
                    business: store,
                    currentUserId: widget.userId,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One followed store: logo, name + stars, and "Category · 🇮🇹 Rome, Italy".
@visibleForTesting
class FollowedStoreRow extends StatelessWidget {
  const FollowedStoreRow({required this.store, required this.onTap, super.key});

  final Profile store;
  final VoidCallback onTap;

  /// Storefront name (businessName, else the display name).
  static String nameOf(Profile p) {
    final b = (p.businessName ?? '').trim();
    return b.isNotEmpty ? b : p.displayName.trim();
  }

  /// "🇮🇹 Rome, Italy" from the PUBLIC storefront address ('' when none; the
  /// personal location is private and never shown).
  static String placeLine(AppLocalizations l10n, Profile p) {
    final a = p.businessAddress;
    if (a == null) return '';
    final city = a.city.trim();
    final country = a.country.trim();
    final code = country.isEmpty ? null : countryCodeFor(country);
    final flag = code == null ? '' : CountryFlagHelper.getFlag(code);
    final place = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) localizedCountryName(l10n, country),
    ].join(', ');
    return [if (flag.isNotEmpty) flag, if (place.isNotEmpty) place].join(' ');
  }

  /// "Category · place" / "Category" / "place" / ''.
  static String subtitleLine(AppLocalizations l10n, Profile p) {
    final c = (p.businessCategory ?? '').trim();
    return [
      if (c.isNotEmpty) localizedBusinessCategory(l10n, c),
      placeLine(l10n, p),
    ].where((s) => s.isNotEmpty).join(' · ');
  }

  /// "4.3 (12)"; null when the store has no ratings.
  static String? ratingText(AppLocalizations l10n, Profile p, String locale) {
    if (p.businessRatingCount <= 0) return null;
    return l10n.followedStoresRating(
      NumberFormat('0.0', locale).format(p.businessRatingAvg),
      formatCompactCount(p.businessRatingCount, locale: locale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final logo = store.businessLogoOrNull ??
        (store.photoUrls.isNotEmpty ? store.photoUrls.first : null);
    final subtitle = subtitleLine(l10n, store);
    final rating = ratingText(l10n, store, locale);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.backgroundCard,
              backgroundImage: logo != null ? CachedNetworkImageProvider(logo) : null,
              child: logo == null
                  ? const Icon(Icons.storefront, color: AppColors.richGold)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        nameOf(store),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 8),
                      Semantics(
                        label: l10n.followedStoresRatingSemantics(
                          NumberFormat('0.0', locale).format(store.businessRatingAvg),
                          store.businessRatingCount,
                        ),
                        excludeSemantics: true,
                        child: Row(
                          key: const Key('followed_store_rating'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.richGold),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ]),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        key: const Key('followed_store_subtitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded filter button (gold outline when a value is chosen).
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.richGold : AppColors.textSecondary;
    return Material(
      color: active ? AppColors.richGold.withOpacity(0.12) : AppColors.backgroundCard,
      shape: StadiumBorder(
        side: BorderSide(color: active ? AppColors.richGold.withOpacity(0.6) : Colors.transparent),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, maxWidth: 220),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Category picker: "All categories" + every category (localized, A-Z).
/// Pops the raw category value, or '' for "All".
class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      for (final c in BusinessCategories.all) (value: c, label: localizedBusinessCategory(l10n, c)),
    ]..sort((a, b) => normalizeFollowName(a.label).compareTo(normalizeFollowName(b.label)));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, ctrl) => ListView(
        controller: ctrl,
        children: [
          _sheetTitle(l10n.followedStoresFilterCategory),
          _option(
            key: const Key('followed_stores_category_all'),
            label: l10n.followedStoresAllCategories,
            selected: (selected ?? '').isEmpty,
            onTap: () => Navigator.of(context).pop(''),
          ),
          for (final c in items)
            _option(
              key: Key('followed_stores_category_${c.value}'),
              label: c.label,
              selected: c.value == selected,
              onTap: () => Navigator.of(context).pop(c.value),
            ),
        ],
      ),
    );
  }
}

/// Place picker: the countries of the user's followed stores (owner-only
/// facets, most stores first), then optionally one of that country's cities.
class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({required this.service, required this.userId, required this.selected});

  final FollowService service;
  final String userId;
  final _PlaceChoice selected;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  late Future<List<StorePlace>> _countries;

  /// The country whose cities are shown (null = the country list).
  StorePlace? _country;
  Future<List<StorePlace>>? _cities;

  @override
  void initState() {
    super.initState();
    _countries = widget.service.followedStoreCountries(widget.userId);
  }

  void _openCountry(StorePlace c) => setState(() {
        _country = c;
        _cities = widget.service.followedStoreCities(widget.userId, c.country);
      });

  String _countryLabel(AppLocalizations l10n, String country) {
    final code = countryCodeFor(country);
    final flag = code == null ? '' : CountryFlagHelper.getFlag(code);
    final name = localizedCountryName(l10n, country);
    return flag.isEmpty ? name : '$flag $name';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    String count(int n) => formatCompactCount(n, locale: locale);
    final country = _country;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, ctrl) => FutureBuilder<List<StorePlace>>(
        future: country == null ? _countries : _cities,
        builder: (context, snap) {
          final title = country == null
              ? _sheetTitle(l10n.followedStoresFilterPlace)
              : Row(children: [
                  IconButton(
                    key: const Key('followed_stores_place_back'),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => setState(() => _country = null),
                  ),
                  Expanded(child: _sheetTitle(_countryLabel(l10n, country.country), padLeft: 0)),
                ]);
          if (snap.connectionState != ConnectionState.done) {
            return ListView(controller: ctrl, children: [
              title,
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
              ),
            ]);
          }
          final places = snap.data ?? const <StorePlace>[];
          final children = <Widget>[title];
          if (snap.hasError) {
            children.add(_note(l10n.userFollowListError));
          } else if (country == null) {
            children.add(_option(
              key: const Key('followed_stores_place_all'),
              label: l10n.followedStoresAllPlaces,
              selected: widget.selected.country.isEmpty,
              onTap: () => Navigator.of(context).pop(_PlaceChoice.none),
            ));
            if (places.isEmpty) children.add(_note(l10n.followedStoresNoPlaces));
            for (final c in places) {
              children.add(_option(
                key: Key('followed_stores_place_${c.country}'),
                label: _countryLabel(l10n, c.country),
                trailing: count(c.count),
                selected: widget.selected.country == c.country,
                chevron: true,
                onTap: () => _openCountry(c),
              ));
            }
          } else {
            children.add(_option(
              key: const Key('followed_stores_city_all'),
              label: l10n.followedStoresAllOfCountry(localizedCountryName(l10n, country.country)),
              trailing: count(country.count),
              selected: widget.selected.country == country.country &&
                  widget.selected.cityLower.isEmpty,
              onTap: () => Navigator.of(context).pop(_PlaceChoice(country: country.country)),
            ));
            for (final c in places) {
              children.add(_option(
                key: Key('followed_stores_city_${c.cityLower}'),
                label: c.city.isEmpty ? c.cityLower : c.city,
                trailing: count(c.count),
                selected: widget.selected.country == country.country &&
                    widget.selected.cityLower == c.cityLower,
                onTap: () => Navigator.of(context).pop(_PlaceChoice(
                  country: country.country,
                  cityLower: c.cityLower,
                  city: c.city.isEmpty ? c.cityLower : c.city,
                )),
              ));
            }
          }
          return ListView(controller: ctrl, children: children);
        },
      ),
    );
  }
}

Widget _sheetTitle(String text, {double padLeft = 20}) => Padding(
      padding: EdgeInsets.fromLTRB(padLeft, 16, 20, 8),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );

Widget _note(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Text(text, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13.5)),
    );

Widget _option({
  required Key key,
  required String label,
  required bool selected,
  required VoidCallback onTap,
  String? trailing,
  bool chevron = false,
}) =>
    ListTile(
      key: key,
      dense: true,
      selected: selected,
      selectedColor: AppColors.richGold,
      textColor: AppColors.textPrimary,
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.check, size: 18, color: AppColors.richGold),
            )
          else if (chevron)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
            ),
        ],
      ),
      onTap: onTap,
    );
