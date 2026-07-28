

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/attraction_icons.dart';
import '../../../../core/services/location_share_service.dart';
import '../../../../core/utils/geo_query.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/attractions_datasource.dart';
import '../../domain/country_resolver.dart';
import '../../domain/entities/attraction.dart';
import '../screens/attraction_detail_screen.dart';

/// Curated attractions, scoped to ONE country at a time.
///
/// Shows ONE country at a time, ordered nearest-first.
///
/// The country is the one the user is physically IN. `primaryOrigin` is only a
/// fallback for when location is unavailable or we don't publish where they
/// are. At home the two coincide; while travelling a second chip lets them
/// switch back to their home country.
///
/// A country is <= ~100 records and arrives in a single document read, so
/// sorting, filtering and search all run in memory — no paging, no geo queries.
class AttractionsTab extends StatefulWidget {
  const AttractionsTab({
    super.key,
    required this.gridView,
    required this.query,
    required this.currentUserId,
    this.sort = 'distance',
    this.userLat,
    this.userLng,
  });

  final bool gridView;
  final String query;
  final String currentUserId;

  /// Chosen in the Events search bar (distance|score|rating|price|name), so the
  /// tab carries no duplicate sort control of its own.
  final String sort;
  final double? userLat;
  final double? userLng;

  @override
  State<AttractionsTab> createState() => _AttractionsTabState();
}

class _AttractionsTabState extends State<AttractionsTab>
    with TickerProviderStateMixin {
  final _ds = AttractionsDataSource();

  List<AttractionCountry> _countries = const [];
  List<Attraction> _items = const [];
  String? _homeIso; // primaryOrigin
  String? _hereIso; // country the user is currently in (when travelling)
  String? _selectedIso;
  bool _userPickedCountry = false;

  /// Anchor position for "nearest first" AND for deciding which country to
  /// show. Priority: Traveler-mode location > profile location > live GPS fix.
  /// Acquired here so ordering does not depend on the parent screen's one-shot
  /// fetch (which can be denied, or arrive after the list is already built).
  double? _lat;
  double? _lng;

  /// Free-text country from whichever location the anchor came from. Lets the
  /// resolver skip geometry entirely when the profile already knows the country.
  String? _anchorCountryName;

  /// True while Traveler mode is active and unexpired — GPS must not override
  /// an explicit traveler destination.
  bool _travelerActive = false;
  bool _locating = false;

  /// Category TabBar. Rebuilt whenever the visible category set changes
  /// (i.e. when the country changes), since the tab count must match.
  TabController? _catController;
  List<String> _catKeys = const [];

  double? get _posLat => _lat ?? widget.userLat;
  double? get _posLng => _lng ?? widget.userLng;
  String? _category; // raw xlsx Category (e.g. 'Historic Site'); null = all
  String _bucket = 'greengo-chat.firebasestorage.app';

  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.userLat;
    _lng = widget.userLng;
    _bootstrap();
  }

  @override
  void dispose() {
    _catController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AttractionsTab old) {
    super.didUpdateWidget(old);
    // Location arriving late can reveal the "you're here" country.
    if (old.userLat != widget.userLat || old.userLng != widget.userLng) {
      _detectHere();
    }
  }

  /// Mirrors `Profile.effectiveLocation`: the traveler location while Traveler
  /// mode is active and unexpired, otherwise the profile's own location. A user
  /// in Traveler mode to Los Angeles must see the USA even while sitting in
  /// Milan, so this takes priority over the device's GPS.
  void _applyProfileAnchor(Map<String, dynamic> d) {
    final expiryRaw = d['travelerExpiry'];
    DateTime? expiry;
    if (expiryRaw is Timestamp) expiry = expiryRaw.toDate();
    if (expiryRaw is String) expiry = DateTime.tryParse(expiryRaw);
    final active = d['isTraveler'] == true &&
        expiry != null &&
        expiry.isAfter(DateTime.now());

    final loc = (active ? d['travelerLocation'] : d['location']) as Map?;
    final fallback = d['location'] as Map?;
    final chosen = loc ?? fallback;
    if (chosen == null) return;

    final la = (chosen['latitude'] as num?)?.toDouble();
    final ln = (chosen['longitude'] as num?)?.toDouble();
    if (la == null || ln == null) return;
    _lat = la;
    _lng = ln;
    _anchorCountryName = chosen['country'] as String?;
    _travelerActive = active;
  }

  /// Fetch a fresh GPS fix. Runs on open and on pull-to-refresh so the order
  /// reflects where the user is AT THAT MOMENT, not where they were when the
  /// Events screen first loaded.
  Future<void> _locate() async {
    if (_locating) return;
    _locating = true;
    try {
      final pos = await const LocationShareService().getCurrentPosition();
      // A traveler anchor is an explicit user choice — GPS must not override it.
      if (pos != null && mounted && !_travelerActive) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (_) {/* permission denied / no fix -> score ordering */}
    _locating = false;
  }

  Future<void> _bootstrap() async {
    try {
      await _locate();
      _bucket = await _ds.bucket();
      final countries = await _ds.publishedCountries();
      String? home;
      try {
        final p = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(widget.currentUserId)
            .get();
        final d = p.data() ?? const <String, dynamic>{};
        home = (d['primaryOrigin'] as String?)?.toUpperCase();
        _applyProfileAnchor(d);
      } catch (_) {/* profile unreadable -> GPS anchor only */}

      // An empty result here means the read FAILED (network/rules), not that
      // we publish nothing — the two must not look the same to the user.
      if (countries.isEmpty) {
        if (mounted) setState(() { _loading = false; _failed = true; });
        return;
      }
      final published = countries.map((c) => c.iso2).toSet();
      // Home only counts if we actually publish it.
      final validHome = (home != null && published.contains(home)) ? home : null;

      if (!mounted) return;
      setState(() {
        _countries = countries;
        _homeIso = validHome;
      });
      // Resolve "where am I" FIRST — that country wins. Origin is the fallback.
      await _detectHere();
      if (!mounted) return;
      setState(() {
        _selectedIso ??= _hereIso ??
            validHome ??
            (countries.isNotEmpty ? countries.first.iso2 : null);
      });
      await _loadSelected();
    } catch (_) {
      if (mounted) setState(() { _loading = false; _failed = true; });
    }
  }

  /// Which published country is the user in? Uses the layered [CountryResolver]
  /// — profile country name, then bounding box, then nearest city with NO
  /// distance cap — so a user in Denver or Seattle still resolves to the USA
  /// even though neither is one of our published cities.
  Future<void> _detectHere() async {
    final lat = _posLat, lng = _posLng;
    if (lat == null && _anchorCountryName == null) return;
    try {
      final citySnap = await FirebaseFirestore.instance
          .collection('attraction_cities')
          .where('published', isEqualTo: true)
          .get();
      final cityByIso = <String, List<(double, double)>>{};
      for (final d in citySnap.docs) {
        final m = d.data();
        final iso = (m['iso2'] as String?)?.toUpperCase();
        final cl = (m['lat'] as num?)?.toDouble();
        final cn = (m['lng'] as num?)?.toDouble();
        if (iso == null || cl == null || cn == null) continue;
        (cityByIso[iso] ??= []).add((cl, cn));
      }

      final countrySnap = await FirebaseFirestore.instance
          .collection('attraction_countries')
          .where('published', isEqualTo: true)
          .get();
      final candidates = countrySnap.docs.map((d) {
        final m = d.data();
        final iso = (m['iso2'] ?? d.id).toString().toUpperCase();
        final bboxRaw = m['bbox'];
        return CountryCandidate(
          iso2: iso,
          name: (m['name'] ?? iso).toString(),
          bbox: bboxRaw is List
              ? bboxRaw.map((e) => (e as num).toDouble()).toList()
              : null,
          cities: cityByIso[iso] ?? const [],
        );
      }).toList();

      final iso = CountryResolver.resolve(
        candidates: candidates,
        countryName: _anchorCountryName,
        lat: lat,
        lng: lng,
      );
      if (!mounted) return;
      setState(() {
        _hereIso = iso;
        if (!_userPickedCountry && iso != null) _selectedIso = iso;
      });
    } catch (_) {/* non-fatal: falls back to primaryOrigin */}
  }

  Future<void> _loadSelected() async {
    final iso = _selectedIso;
    if (iso == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    final list = await _ds.forCountry(iso);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
      _failed = false;
    });
  }

  Future<void> _refresh() async {
    AttractionsDataSource.invalidate();
    _userPickedCountry = false; // re-adopt wherever the user now is
    await _bootstrap();
  }

  double? _distanceMeters(Attraction a) {
    final lat = _posLat, lng = _posLng;
    if (lat == null || lng == null || a.lat == null || a.lng == null) return null;
    return GeoQuery.distanceMeters(lat, lng, a.lat!, a.lng!);
  }

  /// Distance ordering needs only a position. We sort by REAL distance from the
  /// user whenever we have a fix — including while viewing another country —
  /// and fall back to the GreenGo Score only when there is no fix at all.
  bool get _distanceMeaningful => _posLat != null && _posLng != null;

  /// Distance ordering is only honest inside the country being shown; abroad it
  /// silently becomes the GreenGo Score.
  String get _effectiveSort =>
      (widget.sort == 'distance' && !_distanceMeaningful) ? 'score' : widget.sort;

  List<Attraction> get _visible {
    var list = _items;

    if (_category != null) {
      list = list.where((a) => a.category == _category).toList();
    }
    final q = widget.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.cityName.toLowerCase().contains(q) ||
              (a.category ?? '').toLowerCase().contains(q))
          .toList();
    }

    final out = [...list];
    switch (_effectiveSort) {
      case 'score':
        out.sort((a, b) => b.greengoScore.compareTo(a.greengoScore));
        break;
      case 'rating':
        out.sort((a, b) => (b.googleRating ?? 0).compareTo(a.googleRating ?? 0));
        break;
      case 'price':
        out.sort((a, b) => (a.ticketPrice ?? 0).compareTo(b.ticketPrice ?? 0));
        break;
      case 'name':
        out.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'distance':
      default:
        if (_distanceMeaningful) {
          out.sort((a, b) => (_distanceMeters(a) ?? double.maxFinite)
              .compareTo(_distanceMeters(b) ?? double.maxFinite));
        } else {
          // No GPS fix: distance cannot be computed, so rank by score instead.
          out.sort((a, b) => b.greengoScore.compareTo(a.greengoScore));
        }
    }
    return out;
  }

  // ---------------------------------------------------------------- chips ---

  Widget _countryChips(AppLocalizations l10n) {
    final chips = <Widget>[];
    void add(String iso, String suffix) {
      final c = _countries.firstWhere((x) => x.iso2 == iso,
          orElse: () => AttractionCountry(iso2: iso, name: iso, total: 0));
      final selected = _selectedIso == iso;
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('${c.name} · $suffix'),
          selected: selected,
          backgroundColor: AppColors.backgroundCard,
          selectedColor: AppColors.richGold,
          labelStyle: TextStyle(
              fontSize: 12,
              color: selected ? AppColors.deepBlack : AppColors.textPrimary),
          onSelected: (_) {
            setState(() {
              _selectedIso = iso;
              _userPickedCountry = true;
            });
            _loadSelected();
          },
        ),
      ));
    }

    if (_hereIso != null) add(_hereIso!, l10n.attrChipHere);
    if (_homeIso != null && _homeIso != _hereIso) {
      add(_homeIso!, l10n.attrChipHome);
    }
    // One country available => nothing to switch between.
    if (chips.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: chips,
      ),
    );
  }

  /// Categories exactly as they appear in the spreadsheet's `Category` column,
  /// as a scrollable TabBar. Only categories present in the loaded country are
  /// shown, most-populated first, each with its own icon.
  Widget _categoryTabs(AppLocalizations l10n) {
    final counts = <String, int>{};
    final icons = <String, String?>{};
    for (final a in _items) {
      final c = a.category;
      if (c == null || c.isEmpty) continue;
      counts[c] = (counts[c] ?? 0) + 1;
      icons[c] ??= a.categoryIcon;
    }
    final cats = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    final keys = <String>['', ...cats]; // '' = All

    // Recreate the controller only when the tab set actually changes.
    if (_catController == null || !_listEq(keys, _catKeys)) {
      _catController?.dispose();
      _catKeys = keys;
      final initial = _category == null ? 0 : keys.indexOf(_category!);
      _catController = TabController(
        length: keys.length,
        vsync: this,
        initialIndex: initial < 0 ? 0 : initial,
      );
      _catController!.addListener(() {
        if (_catController!.indexIsChanging) return;
        final k = _catKeys[_catController!.index];
        final next = k.isEmpty ? null : k;
        if (next != _category) setState(() => _category = next);
      });
    }

    if (keys.length <= 1) return const SizedBox.shrink();

    return Container(
      color: AppColors.deepBlack,
      child: TabBar(
        controller: _catController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.richGold,
        indicatorWeight: 2.5,
        labelColor: AppColors.richGold,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12.5),
        dividerColor: AppColors.divider,
        tabs: [
          Tab(
            height: 46,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.apps, size: 15),
              const SizedBox(width: 6),
              Text('${l10n.attrAllCategories}  ${_items.length}'),
            ]),
          ),
          ...cats.map((c) => Tab(
                height: 46,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(AttractionIcons.category(icons[c]), size: 15),
                  const SizedBox(width: 6),
                  Text('$c  ${counts[c]}'),
                ]),
              )),
        ],
      ),
    );
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ----------------------------------------------------------------- misc ---

  String _tierLabel(AppLocalizations l10n, String? tier) {
    switch (tier) {
      case 'iconic':
        return l10n.attrTierIconic;
      case 'exceptional':
        return l10n.attrTierExceptional;
      case 'excellent':
        return l10n.attrTierExcellent;
      case 'great':
        return l10n.attrTierGreat;
      default:
        return l10n.attrTierWorthVisit;
    }
  }

  Widget _scoreBadge(Attraction a, {double size = 11}) {
    final c = AttractionIcons.tierColor(a.scoreTier);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.5, vertical: size * 0.16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('${a.greengoScore}',
          style: TextStyle(
              color: AppColors.deepBlack,
              fontSize: size,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _img(Attraction a, String variant, double? h) => CachedNetworkImage(
        imageUrl: a.imageUrl(variant, bucket: _bucket),
        height: h,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.backgroundInput),
        errorWidget: (_, __, ___) => Container(
            color: AppColors.backgroundInput,
            child: Icon(AttractionIcons.category(a.categoryIcon),
                color: AppColors.textTertiary, size: 28)),
      );

  /// Credit line, shown only where the image licence demands one.
  Widget _attribution(Attraction a) {
    if (!a.needsAttribution) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        AppLocalizations.of(context)!
            .attrPhotoBy(a.attributionAuthor!, a.attributionLicense ?? ''),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 8.5),
      ),
    );
  }

  String? _distanceLabel(AppLocalizations l10n, Attraction a) {
    if (!_distanceMeaningful) return null;
    final d = _distanceMeters(a);
    if (d == null) return null;
    final km = d / 1000;
    return l10n.attrKmAway(km < 10 ? km.toStringAsFixed(1) : km.round().toString());
  }

  void _open(Attraction a) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AttractionDetailScreen(
            attractionId: a.id, fallback: a, bucket: _bucket),
      ));

  // ---------------------------------------------------------------- build ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.richGold));
    }
    if (_failed) {
      return _messageState(l10n.attrLoadFailed, Icons.wifi_off, retry: true);
    }
    if (_selectedIso == null) {
      return _messageState(l10n.attrNoCoverage, Icons.public_off);
    }

    final items = _visible;

    return Column(
      children: [
        _countryChips(l10n),
        if (_posLat == null)
          Container(
            width: double.infinity,
            color: AppColors.backgroundCard,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              const Icon(Icons.location_off,
                  size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.attrEnableLocation,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 11.5)),
              ),
              TextButton(
                onPressed: _locate,
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.richGold),
                child: Text(l10n.attrRetry,
                    style: const TextStyle(fontSize: 11.5)),
              ),
            ]),
          ),
        _categoryTabs(l10n),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.richGold,
            onRefresh: _refresh,
            child: items.isEmpty
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                          child: Text(l10n.attrNoResults,
                              style: const TextStyle(
                                  color: AppColors.textSecondary))),
                    )
                  ])
                : (widget.gridView ? _grid(items, l10n) : _list(items, l10n)),
          ),
        ),
      ],
    );
  }

  /// Terminal state that is still pull-to-refresh-able. A plain Center() is
  /// not scrollable, so RefreshIndicator never fires and the user is stuck.
  Widget _messageState(String message, IconData icon, {bool retry = false}) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 120, 32, 24),
            child: Column(children: [
              Icon(icon, size: 40, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              if (retry) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.attrRetry),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _grid(List<Attraction> items, AppLocalizations l10n) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 1100 ? 6 : (w >= 800 ? 4 : 3);
    return GridView.builder(
      key: const ValueKey('attrGrid'),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _tile(items[i], l10n),
    );
  }

  Widget _tile(Attraction a, AppLocalizations l10n) {
    final dist = _distanceLabel(l10n, a);
    return GestureDetector(
      onTap: () => _open(a),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColors.backgroundCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(fit: StackFit.expand, children: [
                  Semantics(label: a.altText ?? a.name, child: _img(a, 'thumb', null)),
                  Positioned(top: 4, left: 4, child: _scoreBadge(a, size: 10)),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(AttractionIcons.importance(a.importanceIcon),
                        size: 14,
                        color: AttractionIcons.importanceColor(a.importanceKey)),
                  ),
                  if (a.unesco)
                    const Positioned(
                        bottom: 4,
                        left: 4,
                        child: Icon(Icons.verified,
                            size: 13, color: AppColors.richGold)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(AttractionIcons.category(a.categoryIcon),
                          size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(dist ?? a.cityName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 10)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      if (a.freeEntry)
                        Text(l10n.attrFree,
                            style: const TextStyle(
                                color: AppColors.richGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold))
                      else if (a.ticketPrice != null && a.ticketPrice! > 0)
                        Text('${a.currency ?? ''} ${a.ticketPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 10)),
                      const Spacer(),
                      if (a.googleRating != null) ...[
                        const Icon(Icons.star, size: 10, color: AppColors.richGold),
                        Text('${a.googleRating}',
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 10)),
                      ],
                    ]),
                    _attribution(a),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<Attraction> items, AppLocalizations l10n) => ListView.builder(
        key: const ValueKey('attrList'),
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) => _card(items[i], l10n),
      );

  Widget _card(Attraction a, AppLocalizations l10n) {
    final dist = _distanceLabel(l10n, a);
    return GestureDetector(
      onTap: () => _open(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Semantics(
                    label: a.altText ?? a.name, child: _img(a, 'card', 160)),
              ),
              Positioned(top: 8, left: 8, child: _scoreBadge(a, size: 12)),
              Positioned(
                top: 8,
                right: 8,
                child: Row(children: [
                  if (a.mustVisit)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.push_pin, size: 16, color: AppColors.richGold),
                    ),
                  Icon(AttractionIcons.importance(a.importanceIcon),
                      size: 17,
                      color: AttractionIcons.importanceColor(a.importanceKey)),
                ]),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(AttractionIcons.category(a.categoryIcon),
                        size: 15, color: AppColors.richGold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (a.unesco)
                      const Icon(Icons.verified, size: 15, color: AppColors.richGold),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    [a.cityName, dist, _tierLabel(l10n, a.scoreTier)]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (a.descriptionShort != null) ...[
                    const SizedBox(height: 6),
                    Text(a.descriptionShort!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12, height: 1.3)),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    if (a.visitDuration != null) ...[
                      const Icon(Icons.schedule, size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(a.visitDuration!,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 11)),
                      const SizedBox(width: 12),
                    ],
                    if (a.freeEntry)
                      Text(l10n.attrFree,
                          style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))
                    else if (a.ticketPrice != null && a.ticketPrice! > 0)
                      Text('${a.currency ?? ''} ${a.ticketPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 12)),
                    const Spacer(),
                    if (a.googleRating != null) ...[
                      const Icon(Icons.star, size: 13, color: AppColors.richGold),
                      const SizedBox(width: 2),
                      Text('${a.googleRating}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 12)),
                    ],
                  ]),
                  _attribution(a),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




