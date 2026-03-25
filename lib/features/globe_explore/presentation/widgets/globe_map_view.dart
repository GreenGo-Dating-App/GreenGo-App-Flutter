import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/country_centroids.dart';
import '../../domain/entities/globe_user.dart';

/// Returns the clustering threshold in degrees based on the current zoom level.
/// At low zoom (zoomed out), threshold is large → more clustering.
/// At high zoom (zoomed in), threshold is tiny → pins show individually.
double _clusterThresholdForZoom(double zoom) {
  // At zoom 2: ~5° (clusters across ~500km)
  // At zoom 5: ~0.5° (clusters across ~50km)
  // At zoom 8: ~0.06° (clusters across ~6km)
  // At zoom 12+: ~0.004° (nearly no clustering)
  return 180.0 / pow(2, zoom);
}

class GlobeMapView extends StatefulWidget {
  final GlobeData data;
  final bool showMatched;
  final bool showDiscovery;
  final String? flyToCountry;
  final void Function(String userId, GlobePinType pinType) onPinTapped;
  final void Function(String countryName, double lat, double lng)
      onCountryTapped;
  final void Function(List<GlobeUser> users)? onClusterTapped;

  const GlobeMapView({
    super.key,
    required this.data,
    required this.showMatched,
    required this.showDiscovery,
    this.flyToCountry,
    required this.onPinTapped,
    required this.onCountryTapped,
    this.onClusterTapped,
  });

  @override
  State<GlobeMapView> createState() => _GlobeMapViewState();
}

class _GlobeMapViewState extends State<GlobeMapView>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Timer? _pulseTimer;
  double _pulseScale = 1.0;
  double _currentZoom = 3.0;

  @override
  void initState() {
    super.initState();
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted) {
        setState(() {
          _pulseScale =
              1.0 + 0.25 * sin(DateTime.now().millisecondsSinceEpoch / 400.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GlobeMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flyToCountry != null &&
        widget.flyToCountry != oldWidget.flyToCountry) {
      _flyToCountry(widget.flyToCountry!);
    }
  }

  void _flyToCountry(String country) {
    final centroid = countryCentroids[country];
    if (centroid != null) {
      _mapController.move(LatLng(centroid[0], centroid[1]), 5.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.data.currentUser;
    final initialCenter =
        LatLng(currentUser.pinLatitude, currentUser.pinLongitude);
    final l10n = AppLocalizations.of(context)!;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 3.0,
        minZoom: 2.0,
        maxZoom: 18.0,
        backgroundColor: const Color(0xFF1A1A2E),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onPositionChanged: (camera, hasGesture) {
          final newZoom = camera.zoom ?? _currentZoom;
          if ((newZoom - _currentZoom).abs() > 0.3) {
            setState(() {
              _currentZoom = newZoom;
            });
          }
        },
        onTap: (tapPosition, point) {
          final nearest =
              _findNearestCountry(point.latitude, point.longitude);
          if (nearest != null) {
            widget.onCountryTapped(nearest, point.latitude, point.longitude);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.greengochat.greengochatapp',
          maxZoom: 19,
          retinaMode: true,
        ),
        PolylineLayer(polylines: _buildFlightPaths()),
        MarkerLayer(markers: _buildMarkers(l10n)),
      ],
    );
  }

  // ── Clustering logic ──────────────────────────────────────────────

  List<Marker> _buildMarkers(AppLocalizations l10n) {
    final markers = <Marker>[];

    // Cluster matched users based on current zoom level
    if (widget.showMatched) {
      final threshold = _clusterThresholdForZoom(_currentZoom);
      final clusters = _clusterUsers(widget.data.matchedUsers, threshold);
      for (final cluster in clusters) {
        if (cluster.length == 1) {
          markers.add(_buildMatchMarker(cluster.first));
        } else {
          markers.add(_buildClusterMarker(cluster));
        }
      }
    }

    // Current user always on top, never clustered
    markers.add(_buildCurrentUserMarker(widget.data.currentUser, l10n));

    return markers;
  }

  /// Groups users whose pin coordinates are within [threshold] degrees.
  List<List<GlobeUser>> _clusterUsers(
      List<GlobeUser> users, double threshold) {
    final assigned = List<bool>.filled(users.length, false);
    final clusters = <List<GlobeUser>>[];
    final thresholdSq = threshold * threshold;

    for (int i = 0; i < users.length; i++) {
      if (assigned[i]) continue;
      final cluster = <GlobeUser>[users[i]];
      assigned[i] = true;

      for (int j = i + 1; j < users.length; j++) {
        if (assigned[j]) continue;
        final dLat = users[i].pinLatitude - users[j].pinLatitude;
        final dLng = users[i].pinLongitude - users[j].pinLongitude;
        if (dLat * dLat + dLng * dLng <= thresholdSq) {
          cluster.add(users[j]);
          assigned[j] = true;
        }
      }
      clusters.add(cluster);
    }
    return clusters;
  }

  Marker _buildClusterMarker(List<GlobeUser> users) {
    // Center of cluster
    double sumLat = 0, sumLng = 0;
    for (final u in users) {
      sumLat += u.pinLatitude;
      sumLng += u.pinLongitude;
    }
    final center = LatLng(sumLat / users.length, sumLng / users.length);

    const size = 52.0;
    return Marker(
      point: center,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          if (widget.onClusterTapped != null) {
            widget.onClusterTapped!(users);
          }
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFD700),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${users.length}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Individual markers ────────────────────────────────────────────

  Marker _buildCurrentUserMarker(GlobeUser user, AppLocalizations l10n) {
    const markerSize = 52.0;
    return Marker(
      point: LatLng(user.pinLatitude, user.pinLongitude),
      width: markerSize + 16,
      height: markerSize + 24,
      child: GestureDetector(
        onTap: () => widget.onPinTapped(user.userId, user.pinType),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4 * _pulseScale),
                        blurRadius: 10 * _pulseScale,
                        spreadRadius: 2 * _pulseScale,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: user.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                _buildFallbackAvatar(user),
                            errorWidget: (_, __, ___) =>
                                _buildFallbackAvatar(user),
                          )
                        : _buildFallbackAvatar(user),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.globeYou,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildMatchMarker(GlobeUser user) {
    const markerSize = 48.0;
    return Marker(
      point: LatLng(user.pinLatitude, user.pinLongitude),
      width: markerSize + 16,
      height: markerSize + 24,
      child: GestureDetector(
        onTap: () => widget.onPinTapped(user.userId, user.pinType),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: user.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.backgroundCard,
                              child: Center(
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) =>
                                _buildFallbackAvatar(user),
                          )
                        : _buildFallbackAvatar(user),
                  ),
                ),
                if (user.isOnline)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                if (user.isTravelerActive)
                  Positioned(
                    left: -4,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flight,
                          color: Colors.white, size: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(GlobeUser user) {
    return Container(
      color: AppColors.backgroundCard,
      child: Center(
        child: Text(
          user.displayName.isNotEmpty
              ? user.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── Flight paths ──────────────────────────────────────────────────

  List<Polyline> _buildFlightPaths() {
    final polylines = <Polyline>[];
    for (final user in widget.data.matchedUsers) {
      if (!user.isTravelerActive ||
          user.realCountryLatitude == null ||
          user.realCountryLongitude == null) continue;

      final start =
          LatLng(user.realCountryLatitude!, user.realCountryLongitude!);
      final end = LatLng(user.pinLatitude, user.pinLongitude);
      polylines.add(Polyline(
        points: _buildArcPoints(start, end),
        color: Colors.blue.withOpacity(0.5),
        strokeWidth: 2,
        isDotted: true,
      ));
    }
    return polylines;
  }

  List<LatLng> _buildArcPoints(LatLng start, LatLng end) {
    const segments = 30;
    final points = <LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lat = start.latitude + t * (end.latitude - start.latitude);
      final lng = start.longitude + t * (end.longitude - start.longitude);
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  String? _findNearestCountry(double lat, double lng) {
    String? nearest;
    double minDist = double.infinity;
    for (final entry in countryCentroids.entries) {
      final cLat = entry.value[0];
      final cLng = entry.value[1];
      final dist = (cLat - lat) * (cLat - lat) + (cLng - lng) * (cLng - lng);
      if (dist < minDist) {
        minDist = dist;
        nearest = entry.key;
      }
    }
    if (minDist > 100) return null;
    return nearest;
  }
}
