import 'package:flutter/material.dart';
import '../../../../core/widgets/map_basemap_layer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A tiny, non-interactive map preview rendered inside a location chat bubble.
///
/// Tiles come from the shared [MapBasemapLayer], which keeps its own on-disk
/// cache, so a bubble re-rendering or scrolling back into view does not refetch
/// anything.
class LocationMessageMap extends StatelessWidget {
  const LocationMessageMap({
    required this.lat,
    required this.lng,
    super.key,
    this.onTap,
    this.width = 220,
    this.height = 130,
  });

  final double lat;
  final double lng;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: height,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 15,
              // Fully static — the bubble's GestureDetector owns the tap
              // (opens the location in an external maps app).
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              const MapBasemapLayer(),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
