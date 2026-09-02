import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../config/map_basemap.dart';

/// The basemap layer for every `flutter_map` in the app.
///
/// Draws OpenFreeMap's vector tiles by default. Vector is the reason this
/// exists: it is free with no key and no request quota (raster providers
/// either rate-limit us, forbid app traffic, or want an account), and it stays
/// sharp at any zoom for a fraction of the bytes.
///
/// Raster is kept as a live fallback rather than deleted. If the style fails
/// to load — offline, a bad URL in config, the public instance down — the map
/// silently draws raster tiles instead of nothing. Setting `useVector: false`
/// in `app_config/map_style` pins every client to raster without a rebuild.
class MapBasemapLayer extends StatefulWidget {
  const MapBasemapLayer({super.key});

  @override
  State<MapBasemapLayer> createState() => _MapBasemapLayerState();
}

class _MapBasemapLayerState extends State<MapBasemapLayer> {
  /// Shared across every map in the app: the style is a ~40 KB document that
  /// only needs fetching and parsing once per session.
  static Future<Style>? _style;

  static Future<Style> _readStyle() =>
      _style ??= StyleReader(uri: MapBasemap.styleUrl).read();

  Widget _raster() => TileLayer(
        urlTemplate: MapBasemap.tileUrl,
        userAgentPackageName: 'com.greengochat.greengochatapp',
        maxZoom: MapBasemap.maxZoom,
      );

  @override
  Widget build(BuildContext context) {
    if (!MapBasemap.useVector) return _raster();

    return FutureBuilder<Style>(
      future: _readStyle(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
              'MapBasemapLayer: vector style failed, using raster '
              '(${snapshot.error})');
          return _raster();
        }
        final style = snapshot.data;
        if (style == null) {
          // Style still loading. Draw nothing rather than fetching raster
          // tiles we are about to throw away — the map's own background shows
          // for the moment it takes.
          return const SizedBox.shrink();
        }
        return VectorTileLayer(
          tileProviders: style.providers,
          theme: style.theme,
          sprites: style.sprites,
          maximumZoom: MapBasemap.maxZoom,
        );
      },
    );
  }
}
