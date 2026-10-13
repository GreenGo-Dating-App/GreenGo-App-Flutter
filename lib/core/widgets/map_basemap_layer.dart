import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../config/map_basemap.dart';

/// The basemap layer for every `flutter_map` in the app: the light place-map
/// basemap (Esri World Street Map by default) that the event, experience,
/// chat-location, picker and network maps all share.
///
/// Its URL and attribution are only ever overridden together (Firestore
/// `app_config/map_style`), so the credit always matches the tiles.
class MapBasemapLayer extends StatelessWidget {
  /// The light place-map basemap.
  const MapBasemapLayer.light({super.key});

  /// Tests set this to skip network tile requests entirely (the test HTTP
  /// client answers every request with 400, which only adds noise).
  @visibleForTesting
  static bool debugDisableTiles = false;

  @override
  Widget build(BuildContext context) {
    if (MapBasemapLayer.debugDisableTiles) return const SizedBox.shrink();
    final url = MapBasemap.lightTileUrl;
    return TileLayer(
      urlTemplate: url,
      subdomains:
          url.contains('{s}') ? const ['a', 'b', 'c', 'd'] : const <String>[],
      // Only a template with {r} has real @2x tiles; faking retina by
      // upscaling lower zooms just blurs street names.
      retinaMode: url.contains('{r}') && RetinaMode.isHighDensity(context),
      userAgentPackageName: 'com.greengochat.greengochatapp',
      maxZoom: MapBasemap.lightMaxZoom,
      maxNativeZoom: MapBasemap.lightMaxNativeZoom,
    );
  }
}
