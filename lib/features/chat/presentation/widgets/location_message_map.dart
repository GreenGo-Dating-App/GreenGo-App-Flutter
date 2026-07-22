import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A tiny, non-interactive map preview rendered inside a location chat bubble.
///
/// Tiles are fetched through [CachedNetworkImageProvider], so every map tile is
/// downloaded at most once and then served from the on-disk cache — the same
/// location (and shared neighbouring tiles) never triggers repeat tile API
/// calls when the bubble re-renders or scrolls back into view.
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
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                tileProvider: _CachedTileProvider(),
                userAgentPackageName: 'com.greengochat.greengochatapp',
              ),
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

/// flutter_map tile provider that serves tiles via [CachedNetworkImageProvider]
/// so tiles are persisted to disk and reused — avoids repeated tile API calls.
class _CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      headers: const {'User-Agent': 'GreenGoChat/1.0'},
    );
  }
}
