import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_basemap.dart';
import '../../../../core/widgets/interactive_location_map.dart';
import '../../../../core/widgets/map_basemap_layer.dart';
import '../../../../core/widgets/map_controls.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/country_centroids.dart';
import '../../domain/entities/globe_user.dart';
import 'globe_markers.dart';
import 'globe_pin_layout.dart';

/// The network ("world") map, drawn on the same stack as every place map in
/// the app: light basemap, attribution, zoom / recenter controls and gestures
/// all come from `core/widgets`, so it looks and behaves like the event and
/// experience maps on mobile and web alike.
///
/// Scale: the pins come from the bounded network read (see
/// GlobeRemoteDataSource): people the user follows / is followed by / chatted
/// with, and businesses (at their business address). Zoomed out they are aggregated per country; zoomed
/// in they cluster on a screen grid. Grouping is computed once per whole zoom
/// band and cached, and only the marker layer listens to band changes, so
/// panning and pinching never rebuild the map itself.
class GlobeMapView extends StatefulWidget {
  const GlobeMapView({
    required this.data,
    required this.onPinTapped,
    required this.onCountryTapped,
    required this.onClusterTapped,
    super.key,
    this.flyToCountry,
    this.flyRequestId = 0,
  });

  final GlobeData data;

  /// Country to jump to; acted on whenever [flyRequestId] changes, so asking
  /// for the same country twice still moves the map.
  final String? flyToCountry;
  final int flyRequestId;

  final void Function(String userId, GlobePinType pinType) onPinTapped;
  final void Function(String countryName, double lat, double lng)
      onCountryTapped;

  /// A cluster that zooming cannot split any further.
  final void Function(List<GlobeUser> users) onClusterTapped;

  @override
  State<GlobeMapView> createState() => _GlobeMapViewState();
}

class _GlobeMapViewState extends State<GlobeMapView> {
  final MapController _controller = MapController();

  /// Whole-number zoom; the marker layer rebuilds only when it changes.
  late final ValueNotifier<int> _band =
      ValueNotifier<int>(MapBasemap.initialZoom.floor());

  /// Markers per zoom band for the current (filtered) [GlobeData.matchedUsers].
  final Map<int, List<Marker>> _markerCache = {};
  List<Polyline>? _flightPaths;

  GlobeUser get _me => widget.data.currentUser;
  LatLng get _mePoint => LatLng(_me.pinLatitude, _me.pinLongitude);

  @override
  void didUpdateWidget(covariant GlobeMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.data.matchedUsers, oldWidget.data.matchedUsers) ||
        widget.data.currentUser != oldWidget.data.currentUser) {
      _markerCache.clear();
      _flightPaths = null;
    }
    final country = widget.flyToCountry;
    if (country != null && widget.flyRequestId != oldWidget.flyRequestId) {
      _flyToCountry(country);
    }
  }

  @override
  void dispose() {
    _band.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _flyToCountry(String country) {
    final c = countryCentroids[normalizeCountryName(country)];
    if (c != null) {
      _controller.move(LatLng(c[0], c[1]), 5);
      return;
    }
    // Not in the centroid table: frame the people we have there instead.
    fitMapToPoints(
        _controller,
        [
          for (final u in widget.data.matchedUsers)
            if (u.country == country) LatLng(u.pinLatitude, u.pinLongitude),
        ],
        maxZoom: 6);
  }

  void _recenter() => _controller.move(_mePoint, MapBasemap.initialZoom);

  void _showWholeNetwork() => fitMapToPoints(_controller, [
        _mePoint,
        for (final u in widget.data.matchedUsers)
          LatLng(u.pinLatitude, u.pinLongitude),
      ]);

  void _onGroupTapped(GlobePinGroup g) {
    if (g.isSingle) {
      widget.onPinTapped(g.first.userId, g.first.pinType);
      return;
    }
    final country = g.country;
    if (country != null) {
      widget.onCountryTapped(country, g.cluster.lat, g.cluster.lng);
      return;
    }
    if (_band.value >= kGlobeClusterListBand) {
      widget.onClusterTapped(g.cluster.items);
      return;
    }
    fitMapToPoints(
        _controller,
        [
          for (final u in g.cluster.items)
            LatLng(u.pinLatitude, u.pinLongitude),
        ],
        maxZoom: kGlobeClusterListBand.toDouble());
  }

  void _onMapTapped(LatLng point) {
    if (_band.value > kGlobeCountryTapMaxBand) return;
    final nearest = _nearestCountry(point.latitude, point.longitude);
    if (nearest != null) {
      widget.onCountryTapped(nearest, point.latitude, point.longitude);
    }
  }

  List<Marker> _markersFor(int band, String selfLabel) {
    return _markerCache.putIfAbsent(band, () {
      final markers = <Marker>[
        for (final g in layoutGlobePins(widget.data.matchedUsers, band))
          if (g.isSingle)
            Marker(
              key: ValueKey('globe-pin-${g.first.userId}'),
              point: LatLng(g.first.pinLatitude, g.first.pinLongitude),
              width: g.first.isBusiness
                  ? GlobeAvatarPin.businessBoxWidth
                  : GlobeAvatarPin.boxWidth,
              height: g.first.isBusiness
                  ? GlobeAvatarPin.businessBoxHeight
                  : GlobeAvatarPin.boxHeight,
              child: GestureDetector(
                onTap: () => _onGroupTapped(g),
                child: GlobeAvatarPin(
                  name: g.first.displayName,
                  photoUrl: g.first.photoUrl,
                  isOnline: g.first.isOnline && !g.first.isBusiness,
                  isTraveler: g.first.isTravelerActive,
                  relations: g.first.relations,
                  isBusiness: g.first.isBusiness,
                ),
              ),
            )
          else
            Marker(
              key: ValueKey('globe-group-${g.cluster.id}'),
              point: LatLng(g.cluster.lat, g.cluster.lng),
              width: MapCountBubble.sizeFor(g.cluster.items.length),
              height: MapCountBubble.sizeFor(g.cluster.items.length),
              child: GestureDetector(
                onTap: () => _onGroupTapped(g),
                child: MapCountBubble(
                  count: g.cluster.items.length,
                  icon: g.country != null ? Icons.people : null,
                ),
              ),
            ),
        // The user's own pin: never grouped, drawn last so it stays on top.
        Marker(
          key: const ValueKey('globe-pin-self'),
          point: _mePoint,
          width: GlobeAvatarPin.boxWidth,
          height: GlobeAvatarPin.boxHeight,
          child: GestureDetector(
            onTap: () => widget.onPinTapped(_me.userId, _me.pinType),
            child: GlobeAvatarPin(
              name: _me.displayName,
              photoUrl: _me.photoUrl,
              isTraveler: _me.isTravelerActive,
              selfLabel: selfLabel,
            ),
          ),
        ),
      ];
      return markers;
    });
  }

  /// Dotted line from an active traveler's home country to where they are.
  List<Polyline> _travelPaths() => _flightPaths ??= [
        for (final u in widget.data.matchedUsers)
          if (u.isTravelerActive &&
              u.realCountryLatitude != null &&
              u.realCountryLongitude != null)
            Polyline(
              points: [
                LatLng(u.realCountryLatitude!, u.realCountryLongitude!),
                LatLng(u.pinLatitude, u.pinLongitude),
              ],
              color: kGlobeTravelerColor.withValues(alpha: 0.6),
              strokeWidth: 2,
              isDotted: true,
            ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paths = _travelPaths();
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            // Open on the user's own city; pinch (or the globe button) to
            // see the whole network.
            initialCenter: _mePoint,
            initialZoom: MapBasemap.initialZoom,
            minZoom: 2,
            maxZoom: MapBasemap.lightMaxZoom,
            backgroundColor: LocationMapColors.background,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onPositionChanged: (camera, _) {
              final band = (camera.zoom ?? _band.value.toDouble()).floor();
              if (band != _band.value) _band.value = band;
            },
            onTap: (_, point) => _onMapTapped(point),
          ),
          children: [
            const MapBasemapLayer.light(),
            if (paths.isNotEmpty) PolylineLayer(polylines: paths),
            ValueListenableBuilder<int>(
              valueListenable: _band,
              builder: (_, band, __) => MarkerLayer(
                markers: _markersFor(band, l10n.globeYou),
              ),
            ),
          ],
        ),
        const Positioned(right: 4, bottom: 2, child: MapAttribution()),
        Positioned(
          right: 10,
          top: 10,
          child: MapZoomControls(
            controller: _controller,
            onRecenter: _recenter,
            extra: [
              MapControlButton(
                key: const ValueKey('globe-map-whole-network'),
                icon: Icons.public,
                tooltip: l10n.globeShowWholeNetwork,
                onTap: _showWholeNetwork,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Country whose centroid is nearest [lat],[lng] (within ~10 degrees).
  String? _nearestCountry(double lat, double lng) {
    String? nearest;
    var minDist = double.infinity;
    for (final entry in countryCentroids.entries) {
      final dLat = entry.value[0] - lat;
      final dLng = entry.value[1] - lng;
      final dist = dLat * dLat + dLng * dLng;
      if (dist < minDist) {
        minDist = dist;
        nearest = entry.key;
      }
    }
    return minDist > 100 ? null : nearest;
  }
}
