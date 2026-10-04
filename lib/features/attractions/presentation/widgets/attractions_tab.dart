

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/attraction_icons.dart';
import '../../../../core/utils/first_screen_gate.dart';
import '../../../../core/services/location_share_service.dart';
import '../../../../core/utils/geo_query.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/attractions_prefetch.dart';
import '../../data/datasources/attractions_datasource.dart';
import '../../data/services/attraction_ratings_store.dart';
import '../../domain/attraction_filters.dart';
import '../../domain/attraction_rating.dart';
import '../../domain/category_labels.dart';
import '../../domain/country_resolver.dart';
import '../../domain/entities/attraction.dart';
import '../screens/attraction_detail_screen.dart';
import 'attraction_grid_tile.dart';
import 'attraction_rating_line.dart';
import 'attraction_score_badge.dart';
import 'attractions_filter_sheet.dart';

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
    this.filters,
  });

  final bool gridView;
  final String query;
  final String currentUserId;

  /// Chosen in the Events search bar (distance|score|rating|price|name), so the
  /// tab carries no duplicate sort control of its own.
  final String sort;
  final double? userLat;
  final double? userLng;

  /// Lets a host (the Events search bar) open the filter sheet and show a
  /// "filters active" badge. Optional: without it the tab still filters with
  /// its defaults, it just has no external entry point to the sheet.
  final AttractionsFilterController? filters;

  @override
  State<AttractionsTab> createState() => _AttractionsTabState();
}

class _AttractionsTabState extends State<AttractionsTab>
    with AutomaticKeepAliveClientMixin {
  final _ds = AttractionsDataSource();

  // Kept alive so swiping between the Events sub-tabs doesn't re-bootstrap.
  @override
  bool get wantKeepAlive => true;

  List<AttractionCountry> _countries = const [];
  List<Attraction> _items = const [];

  /// How many records are rendered right now. The list grows by [_pageSize] as
  /// the user reaches the end, rather than laying out the whole country up
  /// front.
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;

  /// Identifies the list currently on screen (country + category + sort +
  /// query). When it changes the window is reset, so switching country does not
  /// drop the user into the middle of a fresh list.
  String _windowKey = '';

  final ScrollController _scroll = ScrollController();

  /// Whole catalogue, loaded lazily the first time the user searches so a query
  /// can match a country or city outside the one currently being browsed.
  List<Attraction> _all = const [];
  bool _loadingAll = false;

  /// attractionId -> relevance rank for the current query. Kept so an explicit
  /// sort can still fall back to relevance when two records tie.
  final Map<int, int> _rank = {};
  String? _homeIso; // primaryOrigin
  String? _hereIso; // country the user is currently in (when travelling)
  String? _selectedIso;
  bool _userPickedCountry = false;

  /// Anchor position for "nearest first" AND for deciding which country to
  /// show. Priority: Traveler-mode location > device position (the Events
  /// screen's anchor, or a fix taken here) > profile location.
  double? _lat;
  double? _lng;

  /// Free-text country from whichever location the anchor came from. Lets the
  /// resolver skip geometry entirely when the profile already knows the country.
  String? _anchorCountryName;

  /// True while Traveler mode is active and unexpired — GPS must not override
  /// an explicit traveler destination.
  bool _travelerActive = false;
  bool _locating = false;

  double? get _posLat => _lat ?? widget.userLat;
  double? get _posLng => _lng ?? widget.userLng;
  String? _category; // raw xlsx Category (e.g. 'Historic Site'); null = all
  String? _city; // attractionCityKey; null = all cities

  /// GreenGo Score filter (inclusive, 0-100). The full range = no filter.
  RangeValues _scoreRange = const RangeValues(0, 100);
  String _bucket = 'greengo-chat.firebasestorage.app';

  bool _loading = true;
  bool _failed = false;

  // ------------------------------------------------------ image readiness ---
  //
  // The FIRST screen of a country / layout appears in one go: the spinner
  // stays until the first viewport's images are decoded (or failed — the
  // card's fallback shows), capped by [FirstScreenGate] so one slow image
  // never blocks the list. Each next window is precached ahead while
  // scrolling and revealed once decoded (capped).

  /// Image variant per layout. Must match what [_tile] / [_card] render, or
  /// the precache warms a different ImageCache entry than the one displayed.
  static const String _gridVariant = 'thumb';
  static const String _listVariant = 'thumb';
  String get _variant => widget.gridView ? _gridVariant : _listVariant;

  static const Duration _precacheCap = Duration(seconds: 3);

  /// URLs whose image finished (decoded or failed).
  final Set<String> _decoded = {};
  final Map<String, Future<void>> _inflight = {};

  /// Window (list identity + variant) whose first page is ready to paint.
  String _readyKey = '';
  String? _preparingKey;
  bool _growing = false;

  /// The full ordered list last built, so scrolling can precache from it.
  List<Attraction> _lastAll = const [];

  // -------------------------------------------------------------- ratings ---
  //
  // GreenGo users' ratings live in `attraction_stats`, apart from the static
  // catalogue. The ids actually on screen are handed to the shared session
  // memo, which reads only the missing ones in whereIn chunks of 30 and
  // notifies; the cards then repaint with their rating line. Never per tile,
  // never the whole country, never gating the first screen.
  final AttractionRatingsStore _ratings = AttractionRatingsStore.instance;

  /// Ids last handed to the memo (skip identical requests on rebuilds).
  String _ratingIdsKey = '';

  void _onRatings() {
    if (mounted) setState(() {});
  }

  void _requestRatings(List<Attraction> shown) {
    if (shown.isEmpty) return;
    final ids = [for (final a in shown) a.id];
    final key = ids.join(',');
    if (key == _ratingIdsKey) return;
    _ratingIdsKey = key;
    // After the frame: ensure() may notify, which rebuilds this widget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_ratings.ensure(ids));
    });
  }

  AttractionRatingDisplay? _ratingOf(Attraction a) =>
      AttractionRatingDisplay.of(_ratings.peek(a.id), a.googleRating);

  @override
  void initState() {
    super.initState();
    widget.filters?.attach(_openFilters);
    _scroll.addListener(_onScroll);
    _ratings.addListener(_onRatings);
    _lat = widget.userLat;
    _lng = widget.userLng;
    _bootstrap();
  }

  /// Extends the window when the user gets near the end.
  ///
  /// 600px of lead time means the next 20 are laid out before they are needed,
  /// so scrolling stays continuous instead of stuttering at each boundary.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels < pos.maxScrollExtent - 600) return;
    _revealMore();
  }

  /// Grows the window by one page once that page's images are ready (capped),
  /// then warms the page after it so the next boundary is instant.
  Future<void> _revealMore() async {
    if (_growing || _visibleCount >= _lastItemCount) return;
    _growing = true;
    final key = _windowKey;
    final variant = _variant;
    final next = _lastAll.skip(_visibleCount).take(_pageSize).toList();
    await _precache(next, variant, cap: _precacheCap);
    _growing = false;
    if (!mounted || key != _windowKey) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _lastItemCount);
    });
    unawaited(_precache(
        _lastAll.skip(_visibleCount).take(_pageSize).toList(), variant));
  }

  String _urlOf(Attraction a, String variant) =>
      a.imageUrl(variant, bucket: _bucket);

  /// Decode width (physical px) of a card image: the grid cell or the full
  /// list width. Shared by [_img] and [_precache] so both hit the SAME
  /// ImageCache entry (CachedNetworkImage wraps its provider in a ResizeImage).
  int _memW() {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final cols = w >= 1100 ? 6 : (w >= 800 ? 4 : 3);
    final box = widget.gridView ? w / cols : w;
    return (box * mq.devicePixelRatio).round().clamp(64, 4096);
  }

  String _decodedKey(String url, int memW) => '$url@$memW';

  /// The exact provider [_img] paints (CachedNetworkImage + memCacheWidth).
  ImageProvider _providerOf(Attraction a, String variant) =>
      cachedNetworkImageProvider(_urlOf(a, variant), memCacheWidth: _memW());

  /// Images of the first viewport of [all] in the current layout.
  List<ImageProvider> _firstScreenImages(
      List<Attraction> all, Size viewport) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 1100 ? 6 : (w >= 800 ? 4 : 3);
    final count = widget.gridView
        ? firstScreenGridCount(
            viewport: viewport, columns: cols, childAspectRatio: 0.62)
        : firstScreenListCount(
            viewportHeight: viewport.height, itemExtent: 290);
    final variant = _variant;
    return [for (final a in all.take(count)) _providerOf(a, variant)];
  }

  /// Decodes [list]'s images into the ImageCache using the SAME provider the
  /// cards use (CachedNetworkImageProvider keyed by URL), so a revealed card
  /// paints its image on the first frame. Completes when all are done or
  /// failed, or after [cap].
  Future<void> _precache(List<Attraction> list, String variant,
      {Duration? cap}) {
    if (!mounted || list.isEmpty) return Future.value();
    final memW = _memW();
    final waits = <Future<void>>[];
    for (final a in list) {
      final url = _urlOf(a, variant);
      final key = _decodedKey(url, memW);
      if (_decoded.contains(key)) continue;
      waits.add(_inflight[key] ??= precacheImage(
        _providerOf(a, variant),
        context,
        onError: (_, __) {/* card shows its error fallback */},
      ).catchError((_) {}).whenComplete(() {
        _inflight.remove(key);
        _decoded.add(key);
      }));
    }
    if (waits.isEmpty) return Future.value();
    final all = Future.wait(waits);
    return cap == null
        ? all
        : all.timeout(cap, onTimeout: () => const <void>[]);
  }

  /// The first window is gated by [FirstScreenGate] (its viewport decoded
  /// first); the FOLLOWING page is predecoded after the first frame, so the
  /// next boundary is instant.
  void _prepareFirstWindow(String readyKey) {
    if (_preparingKey == readyKey) return;
    _preparingKey = readyKey;
    final variant = _variant;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _preparingKey != readyKey) return;
      unawaited(_precache(
          _lastAll.skip(_visibleCount).take(_pageSize).toList(), variant));
    });
  }

  /// Size of the list the window is being applied to, kept so the scroll
  /// handler knows when there is nothing left to reveal.
  int _lastItemCount = 0;

  /// Resets the window when the list being shown is a different one.
  void _syncWindow(String key, int total) {
    _lastItemCount = total;
    if (key == _windowKey) return;
    _windowKey = key;
    // Called from build - assigning directly is correct here; a setState would
    // be a re-entrant build.
    _visibleCount = _pageSize;
  }

  @override
  void dispose() {
    widget.filters?.detach(_openFilters);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _ratings.removeListener(_onRatings);
    super.dispose();
  }

  @override
  void didUpdateWidget(AttractionsTab old) {
    super.didUpdateWidget(old);
    if (!identical(old.filters, widget.filters)) {
      old.filters?.detach(_openFilters);
      widget.filters?.attach(_openFilters);
      _publishActive();
    }
    if (widget.query.trim().isNotEmpty && _all.isEmpty) _loadAll();
    // A refined device position (from the Events screen) re-sorts and can
    // reveal the "you're here" country — unless Traveler mode pins the anchor.
    if ((old.userLat != widget.userLat || old.userLng != widget.userLng) &&
        widget.userLat != null &&
        widget.userLng != null &&
        !_travelerActive) {
      _lat = widget.userLat;
      _lng = widget.userLng;
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

  /// Fetch a fresh (medium-accuracy) fix. Runs on pull-to-refresh and on
  /// "retry location", so the order reflects where the user is AT THAT MOMENT.
  Future<void> _locate() async {
    if (_locating) return;
    _locating = true;
    try {
      final pos = await const LocationShareService().getApproximatePosition();
      // A traveler anchor is an explicit user choice — GPS must not override it.
      if (pos != null && mounted && !_travelerActive) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
        await _detectHere();
      }
    } catch (_) {/* permission denied / no fix -> score ordering */}
    _locating = false;
  }

  /// profiles/{uid} from the local cache (warmed at startup), else the server.
  Future<Map<String, dynamic>> _readProfile() async {
    final ref = FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.currentUserId);
    try {
      final c = await ref.get(const GetOptions(source: Source.cache));
      if (c.exists) return c.data() ?? const {};
    } catch (_) {/* not cached */}
    try {
      return (await ref.get()).data() ?? const {};
    } catch (_) {
      return const {}; // profile unreadable -> device anchor only
    }
  }

  Future<void> _bootstrap({bool relocate = false}) async {
    // The country the background prefetch resolved (normally already loaded
    // and memoised): start its shard read NOW, in parallel with the reads
    // below, instead of after them. Shared with the prefetch's own in-flight
    // read, so nothing is read twice.
    final likely = AttractionsPrefetch.likelyIso;
    if (likely != null && !relocate) unawaited(_ds.forCountry(likely));
    try {
      // Every read here is independent, so they run together. geoIndex is
      // warmed now because _detectHere needs it right after.
      final reads = await Future.wait<Object>([
        _ds.bucket(),
        _ds.publishedCountries(),
        _readProfile(),
        _ds.geoIndex(),
      ]);
      _bucket = reads[0] as String;
      final countries = reads[1] as List<AttractionCountry>;
      final profile = reads[2] as Map<String, dynamic>;
      final home = (profile['primaryOrigin'] as String?)?.toUpperCase();
      _applyProfileAnchor(profile);
      // The device position beats the profile's stored one (not a traveler's).
      if (!_travelerActive && widget.userLat != null && widget.userLng != null) {
        _lat = widget.userLat;
        _lng = widget.userLng;
      }

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
      // A fresh fix only refines ordering; the list is already visible. On
      // open the Events screen supplies (and refines) the position instead.
      if (relocate) unawaited(_locate());
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
      // ONE cached document (attraction_config/geo) carries every published
      // country's bbox and its city coordinates. This used to read ~700
      // attraction_cities docs plus ~60 attraction_countries docs on every
      // open, before the first attraction could even be shown.
      final candidates = (await _ds.geoIndex()).map((m) {
        final iso = (m['iso2'] ?? '').toString().toUpperCase();
        final bboxRaw = m['bbox'];
        return CountryCandidate(
          iso2: iso,
          name: (m['name'] ?? iso).toString(),
          bbox: bboxRaw is List
              ? bboxRaw.map((e) => (e as num).toDouble()).toList()
              : null,
          cities: ((m['cities'] as List?) ?? const [])
              .map<(double, double)>((c) =>
                  ((c[0] as num).toDouble(), (c[1] as num).toDouble()))
              .toList(),
        );
      }).toList();

      final iso = CountryResolver.resolve(
        candidates: candidates,
        countryName: _anchorCountryName,
        lat: lat,
        lng: lng,
      );
      if (!mounted) return;
      final switched = !_userPickedCountry &&
          iso != null &&
          _selectedIso != null &&
          iso != _selectedIso;
      setState(() {
        _hereIso = iso;
        if (!_userPickedCountry && iso != null) _selectedIso = iso;
        // Category / city belong to the previous country.
        if (switched) {
          _category = null;
          _city = null;
        }
      });
      _publishActive();
      // A late fix that moves the user into another country must also load it.
      if (switched) await _loadSelected();
    } catch (_) {/* non-fatal: falls back to primaryOrigin */}
  }

  /// Pull the whole catalogue once, so search is not limited to the country
  /// currently on screen.
  Future<void> _loadAll() async {
    if (_loadingAll || _all.isNotEmpty) return;
    _loadingAll = true;
    final list = await _ds.allPublished();
    if (mounted) setState(() => _all = list);
    _loadingAll = false;
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
    await _bootstrap(relocate: true);
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

  /// Distance ordering needs only a position; falls back to the score when
  /// there is no fix at all.
  String get _effectiveSort =>
      (widget.sort == 'distance' && !_distanceMeaningful) ? 'score' : widget.sort;

  bool get _searching => widget.query.trim().isNotEmpty;

  String? _countryNameOf(String iso) {
    for (final c in _countries) {
      if (c.iso2 == iso) return c.name;
    }
    return null;
  }

  /// How well [a] answers [q]. Higher is better; 0 means no match.
  ///
  /// Ranked so the most specific interpretation of a query wins: typing "Rome"
  /// should lead with attractions *named* after Rome, then everything *in*
  /// Rome; typing "Italy" should return the whole country.
  int _score(Attraction a, String q, AppLocalizations? l10n) {
    final name = a.name.toLowerCase();
    final city = a.cityName.toLowerCase();
    final country = (_countryNameOf(a.countryIso2) ?? '').toLowerCase();
    final iso = a.countryIso2.toLowerCase();
    final cat = (a.category ?? '').toLowerCase();
    final catLocal =
        l10n == null ? '' : CategoryLabels.of(l10n, a.category).toLowerCase();

    if (name == q) return 1000;
    if (city == q) return 900;
    if (country == q || iso == q) return 850;
    if (name.startsWith(q)) return 800;
    if (city.startsWith(q)) return 700;
    if (country.startsWith(q)) return 650;
    if (name.contains(q)) return 600;
    if (city.contains(q)) return 500;
    if (country.contains(q)) return 450;
    if (cat == q || catLocal == q) return 400;
    if (cat.contains(q) || catLocal.contains(q)) return 300;
    if (a.slug.contains(q)) return 200;
    return 0;
  }

  /// Everything that answers the current query (or the whole country when not
  /// searching), BEFORE the category filter is applied.
  ///
  /// The category tabs and the result list MUST both derive from this, or the
  /// tab counts describe a different set than the one on screen — searching
  /// "Italy" showed 100 results under a tab reading "All 93", because the tabs
  /// were still counting the user's own country.
  List<Attraction> get _matched {
    if (!_searching) return _items;
    final q = widget.query.trim().toLowerCase();
    // Fall back to the current country while the full catalogue is still
    // loading, so the first keystrokes still show something.
    final pool = _all.isNotEmpty ? _all : _items;
    final l10n = AppLocalizations.of(context);
    final scored = <(int, Attraction)>[];
    for (final a in pool) {
      final sc = _score(a, q, l10n);
      if (sc > 0) scored.add((sc, a));
    }
    _rank
      ..clear()
      ..addEntries(scored.map((e) => MapEntry(e.$2.id, e.$1)));
    scored.sort((x, y) {
      if (x.$1 != y.$1) return y.$1.compareTo(x.$1); // relevance first
      if (_distanceMeaningful) {
        return (_distanceMeters(x.$2) ?? double.maxFinite)
            .compareTo(_distanceMeters(y.$2) ?? double.maxFinite);
      }
      return y.$2.greengoScore.compareTo(x.$2.greengoScore);
    });
    return scored.map((e) => e.$2).toList();
  }

  /// What the grid/list renders: [base] (already narrowed by the filters)
  /// ordered by the sort chosen in the search bar, with relevance as the
  /// tie-breaker while searching.
  List<Attraction> _visibleFrom(List<Attraction> list) {
    // The sort bar stays live while searching: after results load the user can
    // still order them by distance, GreenGo Score, rating, price or name.
    // Relevance is kept as the tie-breaker so equally-ranked items retain a
    // sensible order.
    final out = [...list];
    int byRelevance(Attraction a, Attraction b) =>
        (_rank[b.id] ?? 0).compareTo(_rank[a.id] ?? 0);
    int then(int primary, Attraction a, Attraction b) =>
        primary != 0 ? primary : (_searching ? byRelevance(a, b) : 0);

    switch (_effectiveSort) {
      case 'score':
        out.sort((a, b) =>
            then(b.greengoScore.compareTo(a.greengoScore), a, b));
        break;
      case 'rating':
        out.sort((a, b) =>
            then((b.googleRating ?? 0).compareTo(a.googleRating ?? 0), a, b));
        break;
      case 'price':
        out.sort((a, b) =>
            then((a.ticketPrice ?? 0).compareTo(b.ticketPrice ?? 0), a, b));
        break;
      case 'name':
        out.sort((a, b) => then(a.name.compareTo(b.name), a, b));
        break;
      case 'distance':
      default:
        if (_distanceMeaningful) {
          out.sort((a, b) => then(
              (_distanceMeters(a) ?? double.maxFinite)
                  .compareTo(_distanceMeters(b) ?? double.maxFinite),
              a,
              b));
        } else {
          out.sort((a, b) =>
              then(b.greengoScore.compareTo(a.greengoScore), a, b));
        }
    }
    return out;
  }

  // -------------------------------------------------------------- filters ---

  /// The country the tab picks on its own: where the user is, else home, else
  /// the first published one. "Clear" returns here.
  String? get _defaultIso =>
      _hereIso ?? _homeIso ?? (_countries.isNotEmpty ? _countries.first.iso2 : null);

  AttractionFilterSelection get _selection => AttractionFilterSelection(
        countryIso: _selectedIso,
        minScore: _scoreRange.start.round(),
        maxScore: _scoreRange.end.round(),
        category: _category,
        city: _city,
      );

  /// Tells the host whether to badge its filter icon. Deferred to after the
  /// frame: this can run during build, where notifying listeners is illegal.
  void _publishActive() {
    final c = widget.filters;
    if (c == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(widget.filters, c)) return;
      c.setActive(_selection.isActive(_defaultIso));
    });
  }

  /// Countries for the sheet: "you're here" and home first, then the rest of
  /// the published catalogue by name.
  List<AttractionCountryOption> _countryOptions(AppLocalizations l10n) {
    final out = <AttractionCountryOption>[];
    final seen = <String>{};
    void add(String iso, [String? suffix]) {
      if (!seen.add(iso)) return;
      final name = _countryNameOf(iso) ?? iso;
      out.add((iso: iso, label: suffix == null ? name : '$name · $suffix'));
    }

    if (_hereIso != null) add(_hereIso!, l10n.attrChipHere);
    if (_homeIso != null) add(_homeIso!, l10n.attrChipHome);
    final rest = [..._countries]..sort((a, b) => a.name.compareTo(b.name));
    for (final c in rest) {
      add(c.iso2);
    }
    // A country selected from elsewhere must stay representable.
    if (_selectedIso != null) add(_selectedIso!);
    return out;
  }

  /// Opens the filter sheet (score, category, country -> city). Attached to
  /// [AttractionsTab.filters] so the Events search bar icon can call it.
  Future<void> _openFilters() async {
    if (!mounted || _loading || _countries.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final picked = await AttractionsFilterSheet.show(
      context,
      initial: _selection,
      defaults: AttractionFilterSelection(countryIso: _defaultIso),
      countries: _countryOptions(l10n),
      currentPool: _matched,
      loadCountry: _ds.forCountry,
    );
    if (picked == null || !mounted) return;
    _applyFilters(picked);
  }

  void _applyFilters(AttractionFilterSelection f) {
    final iso = f.countryIso ?? _defaultIso;
    final countryChanged = iso != _selectedIso;
    setState(() {
      _scoreRange = RangeValues(f.minScore.toDouble(), f.maxScore.toDouble());
      _category = f.category;
      _city = f.city;
      if (countryChanged) _selectedIso = iso;
      // Back on the automatic country => let a later fix move it again.
      _userPickedCountry = iso != _defaultIso;
    });
    // Same memoised, bounded loader the country chips used.
    if (countryChanged) _loadSelected();
    _publishActive();
  }

  // ----------------------------------------------------------------- misc ---

  Widget _scoreBadge(Attraction a, {double size = 11}) =>
      AttractionScoreBadge(attraction: a, size: size);

  Widget _img(Attraction a, String variant, double? h) => CachedNetworkImage(
        imageUrl: a.imageUrl(variant, bucket: _bucket),
        height: h,
        width: double.infinity,
        fit: BoxFit.cover,
        // Decode at the card's size, not the source's.
        memCacheWidth: _memW(),
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

  /// "City - Country" — always shown on the cards (the list is one country
  /// at a time, but search results span every country).
  String _cityCountry(Attraction a) {
    final c = _countryNameOf(a.countryIso2) ?? a.countryName ?? a.countryIso2;
    return c.isEmpty ? a.cityName : '${a.cityName} - $c';
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
    super.build(context);
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

    // ONE computation per build. Score, category and city all narrow the
    // matched list (country, or search results), and the result header and
    // the grid both read from it, so they can never disagree.
    final all = _visibleFrom(filterAttractions(
      _matched,
      minScore: _scoreRange.start.round(),
      maxScore: _scoreRange.end.round(),
      category: _category,
      city: _city,
    ));
    _lastAll = all;
    // Reset the window when the underlying list changes identity.
    _syncWindow(
      '${_selectedIso ?? ''}|${_category ?? ''}|${_city ?? ''}|$_effectiveSort'
      '|${widget.query.trim()}'
      '|${_scoreRange.start.round()}-${_scoreRange.end.round()}',
      all.length,
    );
    _publishActive();
    final items = all.length <= _visibleCount
        ? all
        : all.sublist(0, _visibleCount);
    final hasMore = all.length > items.length;
    _requestRatings(items);

    // The first window appears in one go (gated below on its first
    // viewport's images); the next page is warmed in the background.
    final readyKey = '$_windowKey|$_variant';
    if (_readyKey != readyKey) {
      _readyKey = readyKey;
      _prepareFirstWindow(readyKey);
    }

    return Column(
      children: [
        if (_searching)
          Container(
            width: double.infinity,
            color: AppColors.backgroundCard,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(children: [
              const Icon(Icons.search, size: 14, color: AppColors.richGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.attrSearchResults(all.length, widget.query.trim()),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              if (_loadingAll)
                const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.richGold)),
            ]),
          ),
        if (!_searching && _posLat == null)
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
        Expanded(
          child: RefreshIndicator(
            color: AppColors.richGold,
            onRefresh: _refresh,
            // Re-armed per country / layout (not per keystroke or filter).
            child: FirstScreenGate(
              key: ValueKey('attrGate|$_selectedIso|$_variant|${widget.gridView}'),
              ready: true,
              images: (_, viewport) => _firstScreenImages(items, viewport),
              placeholder: const Center(
                  child: CircularProgressIndicator(color: AppColors.richGold)),
              builder: (_) => items.isEmpty
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                          child: Text(l10n.attrNoResults,
                              style: const TextStyle(
                                  color: AppColors.textSecondary))),
                    )
                  ])
                : (widget.gridView
                    ? _grid(items, l10n, hasMore)
                    : _list(items, l10n, hasMore)),
            ),
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

  Widget _grid(List<Attraction> items, AppLocalizations l10n, bool hasMore) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 1100 ? 6 : (w >= 800 ? 4 : 3);
    return GridView.builder(
      key: const ValueKey('attrGrid'),
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      // One extra cell while more remain, so the user can see that the list is
      // still growing rather than believing it has ended.
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (_, i) => i >= items.length
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.richGold,
                  ),
                ),
              ),
            )
          : _tile(items[i], l10n),
    );
  }

  Widget _tile(Attraction a, AppLocalizations l10n) => AttractionGridTile(
        attraction: a,
        image: _img(a, _gridVariant, null),
        cityCountry: _cityCountry(a),
        distance: _distanceLabel(l10n, a),
        rating: _ratingOf(a),
        attribution: a.needsAttribution
            ? l10n.attrPhotoBy(a.attributionAuthor!, a.attributionLicense ?? '')
            : null,
        onTap: () => _open(a),
      );

  Widget _list(List<Attraction> items, AppLocalizations l10n, bool hasMore) =>
      ListView.builder(
        controller: _scroll,
        key: const ValueKey('attrList'),
        padding: const EdgeInsets.all(12),
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (_, i) => i >= items.length
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.richGold,
                    ),
                  ),
                ),
              )
            : _card(items[i], l10n),
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
                    // 'thumb' (720x405) at a 160px-tall row: 'card' (1280x720)
                    // was ~3x the bytes for no visible gain, which hurt most on
                    // web where every row is a fresh network fetch.
                    label: a.altText ?? a.name, child: _img(a, _listVariant, 160)),
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
                    [_cityCountry(a), dist]
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
                    AttractionRatingLine(
                        display: _ratingOf(a),
                        fontSize: 12,
                        color: AppColors.textPrimary),
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




