import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../generated/app_localizations.dart';
import '../config/map_basemap.dart';
import '../services/location_share_service.dart';
import '../services/place_search_service.dart';
import 'interactive_location_map.dart' show LocationMapColors, MapAttribution;
import 'map_basemap_layer.dart';

/// Full-screen place picker, the same on Android, iOS and web:
///
/// * a search field with as-you-type suggestions (debounced, min 3 chars,
///   stale answers dropped, up to 6 rows with a primary and secondary line);
/// * choosing one glides the map there and drops a gold pin;
/// * tapping or long-pressing the map moves the pin, and the pin can be
///   dragged; each move reverse-geocodes the address text;
/// * "use my current location" (asks for permission; the browser's
///   geolocation on web);
/// * the confirm button pops a [PickedPlace].
///
/// Every lookup goes through [PlaceSearchRepository] (our Cloud Functions), so
/// no third-party geocoder is ever called from the device. The map is
/// flutter_map + the light Esri basemap: keyless raster tiles over HTTPS that
/// render the same in a release APK as in the browser.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
    this.mode = PlaceSearchMode.address,
    this.title,
    this.searchHint,
    this.confirmLabel,
    this.repository,
    this.locateMe,
    this.onConfirm,
  });

  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  /// [PlaceSearchMode.city] searches cities only, labels the pin with
  /// "City, Country" and requires a city to confirm.
  final PlaceSearchMode mode;
  final String? title;
  final String? searchHint;
  final String? confirmLabel;

  /// Defaults to [PlaceSearchRepository.instance].
  final PlaceSearchRepository? repository;

  /// Current position provider (tests). Defaults to [LocationShareService].
  final Future<LatLng?> Function()? locateMe;

  /// Replaces the default `Navigator.pop(context, place)`, for wrappers that
  /// return something else (the alert-city picker pops just the city).
  final void Function(BuildContext context, PickedPlace place)? onConfirm;

  static Route<PickedPlace> route({
    double? initialLat,
    double? initialLng,
    String? initialAddress,
    PlaceSearchMode mode = PlaceSearchMode.address,
    String? title,
    String? searchHint,
    String? confirmLabel,
  }) =>
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
          initialAddress: initialAddress,
          mode: mode,
          title: title,
          searchHint: searchHint,
          confirmLabel: confirmLabel,
        ),
      );

  /// Typing pause before a search is sent.
  static const Duration debounce = Duration(milliseconds: 350);
  static const int minQueryLength = 3;
  static const int maxSuggestions = 6;

  /// Forgets this session's recent places (tests).
  @visibleForTesting
  static void debugClearRecents() =>
      _LocationPickerScreenState._recentsByMode.clear();

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with TickerProviderStateMixin {
  /// Places picked earlier in this app session (newest first).
  static final Map<PlaceSearchMode, List<PickedPlace>> _recentsByMode = {};

  List<PickedPlace> get _recents =>
      _recentsByMode.putIfAbsent(widget.mode, () => []);

  final MapController _map = MapController();
  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();

  PlaceSearchRepository get _repo =>
      widget.repository ?? PlaceSearchRepository.instance;

  bool get _cityMode => widget.mode == PlaceSearchMode.city;

  Timer? _debounce;
  int _searchSeq = 0;
  int _reverseSeq = 0;
  String _sessionToken = newPlaceSessionToken();

  List<PlaceSuggestion> _suggestions = const [];
  bool _searching = false;
  bool _noResults = false;
  PlaceSearchFailure? _searchError;

  LatLng? _pin;
  PickedPlace? _place;
  bool _resolving = false;
  bool _locating = false;
  int _dropTick = 0;
  Point<double>? _dragPoint;

  AnimationController? _camAnim;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat;
    final lng = widget.initialLng;
    if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
      _pin = LatLng(lat, lng);
      final address = (widget.initialAddress ?? '').trim();
      _place = PickedPlace(address: address, lat: lat, lng: lng);
      if (address.isNotEmpty) {
        _query.text = address;
      } else {
        // Needs the locale, which initState can't read yet.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pin != null) _reverse(_pin!);
        });
      }
    }
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _camAnim?.dispose();
    _query.dispose();
    _focus.dispose();
    _map.dispose();
    super.dispose();
  }

  String get _lang => Localizations.localeOf(context).toLanguageTag();

  // ── Search ────────────────────────────────────────────────────────────────

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.length < LocationPickerScreen.minQueryLength) {
      _searchSeq++; // drop any answer still in flight
      setState(() {
        _suggestions = const [];
        _searching = false;
        _noResults = false;
        _searchError = null;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(LocationPickerScreen.debounce, () => _runSearch(q));
  }

  /// Bias toward what the user is looking at (only once zoomed past
  /// continent level), else toward the pin.
  LatLng? get _bias {
    if (_mapReady) {
      final cam = _map.camera;
      if (cam.zoom >= 5) return cam.center;
    }
    return _pin;
  }

  Future<void> _runSearch(String q) async {
    final seq = ++_searchSeq;
    final bias = _bias;
    try {
      final list = await _repo.search(
        q,
        lang: _lang,
        mode: widget.mode,
        biasLat: bias?.latitude,
        biasLng: bias?.longitude,
        sessionToken: _sessionToken,
      );
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _suggestions =
            list.take(LocationPickerScreen.maxSuggestions).toList();
        _noResults = list.isEmpty;
        _searchError = null;
        _searching = false;
      });
    } on PlaceSearchException catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _suggestions = const [];
        _noResults = false;
        _searchError = e.failure;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _suggestions = const [];
        _searchError = PlaceSearchFailure.unavailable;
        _searching = false;
      });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchSeq++;
    _query.clear();
    setState(() {
      _suggestions = const [];
      _searching = false;
      _noResults = false;
      _searchError = null;
    });
  }

  Future<void> _select(PlaceSuggestion s) async {
    _debounce?.cancel();
    _searchSeq++;
    _reverseSeq++; // a pending reverse lookup must not overwrite this choice
    FocusScope.of(context).unfocus();
    _query.text = s.fullText;
    setState(() {
      _suggestions = const [];
      _searching = false;
      _noResults = false;
      _searchError = null;
    });

    var place = s.toPlace();
    if (place == null && s.placeId != null) {
      setState(() => _resolving = true);
      try {
        place = await _repo.resolve(s.placeId!, sessionToken: _sessionToken);
      } on PlaceSearchException catch (e) {
        if (mounted) setState(() => _searchError = e.failure);
      } catch (_) {
        if (mounted) {
          setState(() => _searchError = PlaceSearchFailure.unavailable);
        }
      }
      if (!mounted) return;
      setState(() => _resolving = false);
    }
    // A session ends with a selection; the next search starts a new one.
    _sessionToken = newPlaceSessionToken();
    if (place == null || !mounted) return;
    final chosen = place.address.isEmpty
        ? place.copyWith(address: s.fullText)
        : place;
    setState(() {
      _pin = LatLng(chosen.lat, chosen.lng);
      _place = chosen;
      _dropTick++;
    });
    _animateTo(_pin!, _cityMode ? 11 : 16);
  }

  void _selectRecent(PickedPlace p) {
    _searchSeq++;
    _reverseSeq++;
    FocusScope.of(context).unfocus();
    _query.text = p.address;
    setState(() {
      _pin = LatLng(p.lat, p.lng);
      _place = p;
      _dropTick++;
    });
    _animateTo(_pin!, _cityMode ? 11 : 16);
  }

  // ── Pin ───────────────────────────────────────────────────────────────────

  void _dropPinAt(LatLng p) {
    FocusScope.of(context).unfocus();
    setState(() {
      _pin = p;
      _place = PickedPlace(address: '', lat: p.latitude, lng: p.longitude);
      _suggestions = const [];
      _dropTick++;
    });
    _reverse(p);
  }

  void _onPinDragStart(DragStartDetails _) {
    if (_pin == null || !_mapReady) return;
    _dragPoint = _map.camera.latLngToScreenPoint(_pin!);
  }

  void _onPinDragUpdate(DragUpdateDetails d) {
    final start = _dragPoint;
    if (start == null || !_mapReady) return;
    final next = Point<double>(start.x + d.delta.dx, start.y + d.delta.dy);
    _dragPoint = next;
    setState(() => _pin = _map.camera.pointToLatLng(next));
  }

  void _onPinDragEnd(DragEndDetails _) {
    _dragPoint = null;
    if (_pin != null) _reverse(_pin!);
  }

  /// Address text for the pin. City mode only needs the city, so it sends a
  /// ~1 km position (and shares cache entries).
  Future<void> _reverse(LatLng p) async {
    final seq = ++_reverseSeq;
    final lat = _cityMode ? _round2(p.latitude) : p.latitude;
    final lng = _cityMode ? _round2(p.longitude) : p.longitude;
    setState(() => _resolving = true);
    PickedPlace? found;
    try {
      found = await _repo.reverse(lat, lng, lang: _lang);
    } catch (_) {
      found = null; // the pin itself is still a valid answer
    }
    if (!mounted || seq != _reverseSeq) return;
    setState(() {
      _resolving = false;
      _place = (found ?? PickedPlace(address: '', lat: p.latitude, lng: p.longitude))
          .copyWith(lat: p.latitude, lng: p.longitude);
      if (_label.isNotEmpty) _query.text = _label;
    });
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  // ── Current location ──────────────────────────────────────────────────────

  Future<LatLng?> _defaultLocateMe() async {
    final pos = await const LocationShareService().getCurrentPosition();
    return pos == null ? null : LatLng(pos.latitude, pos.longitude);
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    LatLng? here;
    try {
      here = await (widget.locateMe ?? _defaultLocateMe)();
    } catch (_) {
      here = null;
    }
    if (!mounted) return;
    setState(() => _locating = false);
    if (here == null) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.locPickerLocationUnavailable)));
      return;
    }
    _dropPinAt(here);
    _animateTo(here, _cityMode ? 11 : 16);
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  /// Glides the camera to [dest] (pan + zoom together, ~0.6 s).
  void _animateTo(LatLng dest, double zoom) {
    if (!_mapReady) return; // initialCenter covers the first frame
    final cam = _map.camera;
    final targetZoom = zoom.clamp(2.0, MapBasemap.lightMaxZoom);
    final lat = Tween<double>(begin: cam.center.latitude, end: dest.latitude);
    final lng =
        Tween<double>(begin: cam.center.longitude, end: dest.longitude);
    final z = Tween<double>(begin: cam.zoom, end: targetZoom);
    _camAnim?.dispose();
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _camAnim = ctrl;
    final curve = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);
    ctrl.addListener(() {
      _map.move(
        LatLng(lat.evaluate(curve), lng.evaluate(curve)),
        z.evaluate(curve),
      );
    });
    ctrl.forward();
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final cam = _map.camera;
    _animateTo(cam.center, cam.zoom + delta);
  }

  // ── Labels ────────────────────────────────────────────────────────────────

  String get _label {
    final p = _place;
    if (p == null) return '';
    if (_cityMode) {
      return [p.city, p.country].where((s) => s.isNotEmpty).join(', ');
    }
    return p.address;
  }

  bool get _canConfirm {
    if (_pin == null || _resolving) return false;
    if (_cityMode) return (_place?.city ?? '').isNotEmpty;
    return true;
  }

  void _confirm() {
    final pin = _pin;
    if (pin == null) return;
    final place = (_place ??
            PickedPlace(address: '', lat: pin.latitude, lng: pin.longitude))
        .copyWith(lat: pin.latitude, lng: pin.longitude);
    if (place.address.isNotEmpty) {
      _recents.removeWhere((r) => r.address == place.address);
      _recents.insert(0, place);
      if (_recents.length > 5) _recents.removeLast();
    }
    final custom = widget.onConfirm;
    if (custom != null) {
      custom(context, place);
    } else {
      Navigator.of(context).pop(place);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final start = _pin ?? const LatLng(20, 0);
    return Scaffold(
      backgroundColor: LocationMapColors.surface,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: LocationMapColors.surface,
        foregroundColor: LocationMapColors.text,
        elevation: 0.5,
        title: Text(widget.title ?? l10n.locPickerTitle),
      ),
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: FlutterMap(
                key: const ValueKey('location-picker-map'),
                mapController: _map,
                options: MapOptions(
                  initialCenter: start,
                  initialZoom: _pin == null ? 2 : (_cityMode ? 11 : 16),
                  minZoom: 2,
                  maxZoom: MapBasemap.lightMaxZoom,
                  backgroundColor: LocationMapColors.background,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onMapReady: () => _mapReady = true,
                  onTap: (_, p) => _dropPinAt(p),
                  onLongPress: (_, p) => _dropPinAt(p),
                ),
                children: [
                  const MapBasemapLayer.light(),
                  if (_pin != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _pin!,
                        width: 56,
                        height: 56,
                        alignment: Alignment.topCenter,
                        child: _DraggablePin(
                          dropTick: _dropTick,
                          semanticLabel: l10n.locPickerPinLabel,
                          onDragStart: _onPinDragStart,
                          onDragUpdate: _onPinDragUpdate,
                          onDragEnd: _onPinDragEnd,
                        ),
                      ),
                    ]),
                ],
              ),
            ),
            const Positioned(right: 4, bottom: 2, child: MapAttribution()),
            Positioned(
              right: 12,
              bottom: 28,
              child: Column(children: [
                _RoundButton(
                  key: const ValueKey('location-picker-zoom-in'),
                  icon: Icons.add,
                  tooltip: l10n.locMapZoomIn,
                  onTap: () => _zoomBy(1),
                ),
                const SizedBox(height: 6),
                _RoundButton(
                  key: const ValueKey('location-picker-zoom-out'),
                  icon: Icons.remove,
                  tooltip: l10n.locMapZoomOut,
                  onTap: () => _zoomBy(-1),
                ),
                const SizedBox(height: 12),
                _RoundButton(
                  key: const ValueKey('location-picker-my-location'),
                  icon: Icons.my_location,
                  tooltip: l10n.locPickerMyLocation,
                  busy: _locating,
                  onTap: _useMyLocation,
                ),
              ]),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _searchPanel(l10n),
                ),
              ),
            ),
          ]),
        ),
        _confirmBar(l10n),
      ]),
    );
  }

  Widget _searchPanel(AppLocalizations l10n) {
    final showRecents = _focus.hasFocus &&
        _query.text.trim().isEmpty &&
        _recents.isNotEmpty;
    final error = switch (_searchError) {
      PlaceSearchFailure.offline => l10n.locPickerOffline,
      PlaceSearchFailure.rateLimited => l10n.locPickerRateLimited,
      PlaceSearchFailure.unavailable => l10n.locPickerUnavailable,
      null => null,
    };
    return Material(
      color: LocationMapColors.surface,
      elevation: 4,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          key: const ValueKey('location-picker-search'),
          controller: _query,
          focusNode: _focus,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (q) {
            if (_suggestions.isNotEmpty) {
              _select(_suggestions.first);
            } else if (q.trim().length >= LocationPickerScreen.minQueryLength) {
              _debounce?.cancel();
              _runSearch(q.trim());
            }
          },
          style: const TextStyle(color: LocationMapColors.text, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.searchHint ?? l10n.locPickerSearchHint,
            hintStyle: const TextStyle(color: LocationMapColors.subtext),
            prefixIcon:
                const Icon(Icons.search, color: LocationMapColors.goldDark),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: LocationMapColors.gold),
                    ),
                  )
                : (_query.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('location-picker-clear'),
                        tooltip: l10n.locPickerClear,
                        icon: const Icon(Icons.close,
                            color: LocationMapColors.subtext),
                        onPressed: _clearSearch,
                      )),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_suggestions.isNotEmpty)
          _list([
            for (final s in _suggestions)
              _SuggestionTile(
                key: ValueKey('location-picker-suggestion-${s.id}'),
                icon: Icons.place_outlined,
                primary: s.primary,
                secondary: s.secondary,
                onTap: () => _select(s),
              ),
          ])
        else if (showRecents)
          _list([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.locPickerRecent,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LocationMapColors.subtext)),
              ),
            ),
            for (final r in _recents)
              _SuggestionTile(
                icon: Icons.history,
                primary: r.address,
                secondary: '',
                onTap: () => _selectRecent(r),
              ),
          ])
        else if (error != null)
          _note(error, key: const ValueKey('location-picker-error'),
              icon: Icons.cloud_off)
        else if (_noResults && !_searching)
          _note(l10n.locPickerNoResults,
              key: const ValueKey('location-picker-no-results'),
              icon: Icons.search_off),
      ]),
    );
  }

  Widget _list(List<Widget> children) => Column(children: [
        const Divider(height: 1, color: LocationMapColors.border),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: children,
          ),
        ),
      ]);

  Widget _note(String text, {required Key key, required IconData icon}) =>
      Column(key: key, children: [
        const Divider(height: 1, color: LocationMapColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            Icon(icon, size: 18, color: LocationMapColors.subtext),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: LocationMapColors.subtext)),
            ),
          ]),
        ),
      ]);

  Widget _confirmBar(AppLocalizations l10n) {
    final String status;
    if (_pin == null) {
      status = l10n.locPickerHint;
    } else if (_resolving) {
      status = l10n.locPickerFindingAddress;
    } else if (_label.isNotEmpty) {
      status = _label;
    } else {
      status = l10n.locPickerNoAddress;
    }
    return Container(
      decoration: const BoxDecoration(
        color: LocationMapColors.surface,
        border: Border(top: BorderSide(color: LocationMapColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(_pin == null ? Icons.touch_app_outlined : Icons.place,
                    size: 18, color: LocationMapColors.goldDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status,
                    key: const ValueKey('location-picker-status'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: _pin != null && _label.isNotEmpty
                          ? LocationMapColors.text
                          : LocationMapColors.subtext,
                      fontWeight: _pin != null && _label.isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              FilledButton(
                key: const ValueKey('location-picker-confirm'),
                onPressed: _canConfirm ? _confirm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: LocationMapColors.gold,
                  foregroundColor: LocationMapColors.text,
                  disabledBackgroundColor: LocationMapColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.confirmLabel ?? l10n.locPickerConfirm,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The gold pin: drops in with a small bounce whenever it is placed, and can
/// be dragged.
class _DraggablePin extends StatelessWidget {
  const _DraggablePin({
    required this.dropTick,
    required this.semanticLabel,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final int dropTick;
  final String semanticLabel;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      // The map's own pan/zoom recognizer competes for every pointer; the
      // pin claims a pointer that lands on it at once, so dragging the pin
      // moves the pin, never the map under it.
      child: RawGestureDetector(
        key: const ValueKey('location-picker-pin'),
        behavior: HitTestBehavior.opaque,
        gestures: {
          _EagerPanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
            _EagerPanGestureRecognizer.new,
            (r) => r
              ..onStart = onDragStart
              ..onUpdate = onDragUpdate
              ..onEnd = onDragEnd,
          ),
        },
        child: TweenAnimationBuilder<double>(
          key: ValueKey(dropTick),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (_, t, child) => Transform.translate(
            offset: Offset(0, (1 - t) * -14),
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
          child: const Icon(
            Icons.location_on,
            size: 52,
            color: LocationMapColors.gold,
            shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
          ),
        ),
      ),
    );
  }
}

/// A pan recognizer that wins the gesture arena as soon as a pointer lands on
/// its widget.
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolvePointer(event.pointer, GestureDisposition.accepted);
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String primary;
  final String secondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Icon(icon, size: 20, color: LocationMapColors.goldDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LocationMapColors.text)),
                if (secondary.isNotEmpty)
                  Text(secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: LocationMapColors.subtext)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
    this.busy = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LocationMapColors.surface,
      shape: const CircleBorder(
          side: BorderSide(color: LocationMapColors.border)),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        onPressed: busy ? null : onTap,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: LocationMapColors.gold),
              )
            : Icon(icon, color: LocationMapColors.goldDark, size: 20),
      ),
    );
  }
}
