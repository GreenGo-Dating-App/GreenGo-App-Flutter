import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../generated/app_localizations.dart';
import '../config/map_basemap.dart';
import 'interactive_location_map.dart' show LocationMapColors;

/// Round white map button with a gold icon — the control style shared by
/// every `flutter_map` surface (place maps, the network map).
class MapControlButton extends StatelessWidget {
  const MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LocationMapColors.surface,
      shape:
          const CircleBorder(side: BorderSide(color: LocationMapColors.border)),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: LocationMapColors.goldDark, size: 20),
        onPressed: onTap,
      ),
    );
  }
}

/// The zoom in / zoom out / recenter column shown at the top right of an
/// interactive map. [extra] buttons go below recenter.
class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    required this.controller,
    required this.onRecenter,
    super.key,
    this.minZoom = 2,
    this.maxZoom = MapBasemap.lightMaxZoom,
    this.recenterIcon = Icons.my_location,
    this.extra = const [],
  });

  final MapController controller;
  final VoidCallback onRecenter;
  final double minZoom;
  final double maxZoom;
  final IconData recenterIcon;
  final List<Widget> extra;

  void _zoomBy(double delta) {
    final cam = controller.camera;
    controller.move(cam.center, (cam.zoom + delta).clamp(minZoom, maxZoom));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (l == null) return const SizedBox.shrink();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      MapControlButton(
        key: const ValueKey('location-map-zoom-in'),
        icon: Icons.add,
        tooltip: l.locMapZoomIn,
        onTap: () => _zoomBy(1),
      ),
      const SizedBox(height: 6),
      MapControlButton(
        key: const ValueKey('location-map-zoom-out'),
        icon: Icons.remove,
        tooltip: l.locMapZoomOut,
        onTap: () => _zoomBy(-1),
      ),
      const SizedBox(height: 12),
      MapControlButton(
        key: const ValueKey('location-map-recenter'),
        icon: recenterIcon,
        tooltip: l.locMapRecenter,
        onTap: onRecenter,
      ),
      for (final w in extra) ...[const SizedBox(height: 6), w],
    ]);
  }
}

/// Gold count bubble for a group of map items (a cluster of pins or a
/// country aggregate). Grows slowly with the count so a thousand-strong
/// bubble stays readable without covering a continent.
class MapCountBubble extends StatelessWidget {
  const MapCountBubble({required this.count, super.key, this.icon});

  final int count;

  /// Optional glyph above the number (e.g. people for a country aggregate).
  final IconData? icon;

  /// Diameter for [count]: 40 for a pair, up to 64 for very large groups.
  static double sizeFor(int count) =>
      (36 + count.toString().length * 6).clamp(40, 64).toDouble();

  @override
  Widget build(BuildContext context) {
    final label =
        count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LocationMapColors.gold,
        border: Border.all(color: LocationMapColors.surface, width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4)],
      ),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Icon(icon, size: 13, color: LocationMapColors.text),
        Text(
          label,
          style: const TextStyle(
            color: LocationMapColors.text,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ]),
    );
  }
}

/// Moves [controller] so every point in [points] is visible (with [padding]),
/// never past [maxZoom]. A single point just centres at [maxZoom].
void fitMapToPoints(
  MapController controller,
  List<LatLng> points, {
  double maxZoom = 16,
  EdgeInsets padding = const EdgeInsets.all(64),
}) {
  if (points.isEmpty) return;
  if (points.length == 1) {
    controller.move(points.first, maxZoom);
    return;
  }
  controller.fitCamera(CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(points),
    padding: padding,
    maxZoom: maxZoom,
  ));
}
