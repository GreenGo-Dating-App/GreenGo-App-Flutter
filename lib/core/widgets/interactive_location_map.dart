import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/app_localizations.dart';
import '../config/map_basemap.dart';
import '../constants/app_colors.dart';
import 'map_basemap_layer.dart';
import 'map_controls.dart';

/// Light palette shared by every place map (white card, gold accents).
class LocationMapColors {
  const LocationMapColors._();
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E2CF);
  static const Color text = Color(0xFF1F2328);
  static const Color subtext = Color(0xFF5F6670);
  static const Color gold = AppColors.richGold;
  static const Color goldDark = Color(0xFF9C7A12);
  static const Color background = Color(0xFFF2EFE6);
}

/// Which native maps app family an "Open in Maps" link targets.
enum MapsPlatform { android, ios, web }

/// The platform the app runs on, for [mapsLaunchUri].
MapsPlatform currentMapsPlatform() {
  if (kIsWeb) return MapsPlatform.web;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return MapsPlatform.android;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return MapsPlatform.ios;
    default:
      return MapsPlatform.web;
  }
}

/// Builds the link that opens [lat],[lng] in the platform maps app.
///
/// * Android: a `geo:` URI, so the user's chosen maps app opens (it offers
///   directions from there). With [directions] it is the Google Maps
///   directions URL, which Android hands to the Maps app via app links.
/// * iOS / macOS: Apple Maps (`maps.apple.com`), pin or driving directions.
/// * Web / desktop: the Google Maps web URL.
Uri mapsLaunchUri(
  double lat,
  double lng, {
  required MapsPlatform platform,
  String? label,
  bool directions = false,
}) {
  final ll = '$lat,$lng';
  final name = (label ?? '').trim();
  switch (platform) {
    case MapsPlatform.android:
      if (directions) return googleMapsWebUri(lat, lng, directions: true);
      // geo:lat,lng?q=lat,lng(Label) — the q form drops a labelled pin.
      final q = name.isEmpty ? ll : '$ll(${Uri.encodeComponent(name)})';
      return Uri.parse('geo:$ll?q=$q');
    case MapsPlatform.ios:
      return Uri.https('maps.apple.com', '/', {
        if (directions) 'daddr': ll else 'll': ll,
        'q': name.isEmpty ? ll : name,
        if (directions) 'dirflg': 'd',
      });
    case MapsPlatform.web:
      return googleMapsWebUri(lat, lng, directions: directions);
  }
}

/// Google Maps web URL — the universal fallback.
Uri googleMapsWebUri(double lat, double lng, {bool directions = false}) =>
    directions
        ? Uri.https('www.google.com', '/maps/dir/',
            {'api': '1', 'destination': '$lat,$lng'})
        : Uri.https('www.google.com', '/maps/search/',
            {'api': '1', 'query': '$lat,$lng'});

/// Opens the platform maps app; falls back to the Google Maps web URL, then
/// to a snackbar when nothing can open it.
Future<void> openInMapsApp(
  BuildContext context,
  double lat,
  double lng, {
  String? label,
  bool directions = false,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failText = AppLocalizations.of(context)?.locMapCouldNotOpen;
  Future<bool> tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  final primary = mapsLaunchUri(lat, lng,
      platform: currentMapsPlatform(), label: label, directions: directions);
  if (await tryLaunch(primary)) return;
  final web = googleMapsWebUri(lat, lng, directions: directions);
  if (web != primary && await tryLaunch(web)) return;
  if (failText != null) {
    messenger?.showSnackBar(SnackBar(content: Text(failText)));
  }
}

/// The map itself: light basemap, gold pin (or approximate-area
/// circle), required attribution, optional zoom / recenter controls.
///
/// With [interactive] false it is a static preview (no gestures at all), safe
/// inside scroll views and chat lists.
class LocationMapView extends StatefulWidget {
  const LocationMapView({
    required this.lat,
    required this.lng,
    super.key,
    this.label,
    this.approximateRadiusMeters,
    this.interactive = true,
    this.showControls = true,
    this.initialZoom,
  });

  final double lat;
  final double lng;
  final String? label;

  /// When set, draws a translucent circle of this radius (meters) instead of
  /// an exact pin. Callers must pass an already-coarsened centre: the circle
  /// hides the pin, not the coordinates handed to this widget.
  final double? approximateRadiusMeters;
  final bool interactive;
  final bool showControls;
  final double? initialZoom;

  bool get isApproximate => (approximateRadiusMeters ?? 0) > 0;

  @override
  State<LocationMapView> createState() => _LocationMapViewState();
}

class _LocationMapViewState extends State<LocationMapView> {
  final MapController _controller = MapController();

  LatLng get _point => LatLng(widget.lat, widget.lng);

  double get _startZoom =>
      widget.initialZoom ?? (widget.isApproximate ? 14 : 16);

  void _recenter() => _controller.move(_point, _startZoom);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _point,
            initialZoom: _startZoom,
            minZoom: 2,
            maxZoom: MapBasemap.lightMaxZoom,
            backgroundColor: LocationMapColors.background,
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            const MapBasemapLayer.light(),
            if (widget.isApproximate)
              CircleLayer(circles: [
                CircleMarker(
                  key: const ValueKey('location-map-area'),
                  point: _point,
                  radius: widget.approximateRadiusMeters!,
                  useRadiusInMeter: true,
                  color: LocationMapColors.gold.withValues(alpha: 0.22),
                  borderColor: LocationMapColors.goldDark,
                  borderStrokeWidth: 2,
                ),
              ])
            else
              MarkerLayer(markers: [
                Marker(
                  point: _point,
                  width: 180,
                  height: 72,
                  alignment: Alignment.topCenter,
                  child: _GoldPin(label: widget.label),
                ),
              ]),
          ],
        ),
        const Positioned(right: 4, bottom: 2, child: MapAttribution()),
        if (widget.interactive && widget.showControls)
          Positioned(
            right: 10,
            top: 10,
            child: MapZoomControls(
              controller: _controller,
              onRecenter: _recenter,
            ),
          ),
      ],
    );
  }
}

/// The basemap credit (provider + OpenStreetMap) required on every map.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        MapBasemap.lightAttribution, // i18n-ignore: legal map credit
        style: const TextStyle(fontSize: 9, color: LocationMapColors.subtext),
      ),
    );
  }
}

class _GoldPin extends StatelessWidget {
  const _GoldPin({this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = (label ?? '').trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (text.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 170),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: LocationMapColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: LocationMapColors.gold),
              boxShadow: const [
                BoxShadow(color: Color(0x22000000), blurRadius: 4),
              ],
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: LocationMapColors.text),
            ),
          ),
        const Icon(Icons.location_on,
            key: ValueKey('location-map-pin'),
            size: 38,
            color: LocationMapColors.gold,
            shadows: [Shadow(color: Color(0x55000000), blurRadius: 4)]),
      ],
    );
  }
}

/// Compact embedded map card (light, rounded) with an "Open in Maps" action.
/// The map is a static preview; tapping it opens [LocationMapScreen] with
/// full gestures, zoom buttons, recenter and directions.
class InteractiveLocationMap extends StatelessWidget {
  const InteractiveLocationMap({
    required this.lat,
    required this.lng,
    super.key,
    this.label,
    this.subtitle,
    this.approximateRadiusMeters,
    this.height = 200,
  });

  final double lat;
  final double lng;
  final String? label;
  final String? subtitle;
  final double? approximateRadiusMeters;
  final double height;

  bool get _approx => (approximateRadiusMeters ?? 0) > 0;

  /// Coordinates worth drawing (rejects null, NaN, out-of-range and the
  /// 0,0 "unset" sentinel).
  static bool validCoordinates(double? lat, double? lng) =>
      lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180 &&
      !(lat == 0 && lng == 0);

  void _openFull(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LocationMapScreen(
        lat: lat,
        lng: lng,
        label: label,
        subtitle: subtitle,
        approximateRadiusMeters: approximateRadiusMeters,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('interactive-location-map'),
      decoration: BoxDecoration(
        color: LocationMapColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LocationMapColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height,
            child: Stack(children: [
              Positioned.fill(
                child: LocationMapView(
                  lat: lat,
                  lng: lng,
                  label: label,
                  approximateRadiusMeters: approximateRadiusMeters,
                  interactive: false,
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openFull(context),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: MapControlButton(
                  icon: Icons.open_in_full,
                  tooltip: l.locMapExpand,
                  onTap: () => _openFull(context),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(children: [
              Icon(_approx ? Icons.blur_circular : Icons.place,
                  size: 18, color: LocationMapColors.goldDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _approx ? l.locMapApproximateArea : (label ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: LocationMapColors.text),
                ),
              ),
              if (!_approx)
                TextButton.icon(
                  key: const ValueKey('location-map-open-in-maps'),
                  style: TextButton.styleFrom(
                      foregroundColor: LocationMapColors.goldDark),
                  onPressed: () =>
                      openInMapsApp(context, lat, lng, label: label),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(l.locMapOpenInMaps),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Full-screen interactive map with zoom, recenter and directions.
class LocationMapScreen extends StatelessWidget {
  const LocationMapScreen({
    required this.lat,
    required this.lng,
    super.key,
    this.label,
    this.subtitle,
    this.approximateRadiusMeters,
  });

  final double lat;
  final double lng;
  final String? label;
  final String? subtitle;
  final double? approximateRadiusMeters;

  bool get _approx => (approximateRadiusMeters ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = (label ?? '').trim();
    return Scaffold(
      backgroundColor: LocationMapColors.surface,
      appBar: AppBar(
        backgroundColor: LocationMapColors.surface,
        foregroundColor: LocationMapColors.text,
        elevation: 0.5,
        title: Text(title.isEmpty ? l.chatLocation : title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(children: [
        Expanded(
          child: LocationMapView(
            lat: lat,
            lng: lng,
            label: label,
            approximateRadiusMeters: approximateRadiusMeters,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(children: [
              Expanded(
                child: Text(
                  _approx ? l.locMapApproximateArea : (subtitle ?? title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, color: LocationMapColors.subtext),
                ),
              ),
              if (!_approx) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const ValueKey('location-map-directions'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LocationMapColors.gold,
                    foregroundColor: LocationMapColors.text,
                  ),
                  onPressed: () => openInMapsApp(context, lat, lng,
                      label: label, directions: true),
                  icon: const Icon(Icons.directions),
                  label: Text(l.locMapDirections),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
