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
///
/// [MapBasemapLayer.light] draws the light place-map basemap instead (Esri
/// World Street Map by default); its URL and attribution are only ever
/// overridden together, so the credit always matches the tiles.
class MapBasemapLayer extends StatefulWidget {
  const MapBasemapLayer({super.key}) : light = false;

  /// The light place-map basemap.
  const MapBasemapLayer.light({super.key}) : light = true;

  /// Whether this layer draws the light basemap.
  final bool light;

  /// Tests set this to skip network tile requests entirely (the test HTTP
  /// client answers every request with 400, which only adds noise).
  @visibleForTesting
  static bool debugDisableTiles = false;

  @override
  State<MapBasemapLayer> createState() => _MapBasemapLayerState();
}

class _MapBasemapLayerState extends State<MapBasemapLayer> {
  /// Shared across every map in the app: the style is a ~40 KB document that
  /// only needs fetching and parsing once per session.
  static Future<Style>? _style;

  static Future<Style> _readStyle() =>
      _style ??= StyleReader(uri: MapBasemap.styleUrl).read();

  Widget _raster() {
    final url = MapBasemap.tileUrl;
    // Derived from the template rather than hardcoded, so any URL configured
    // in app_config works: a {s} template needs subdomains to substitute, and
    // retinaMode is what fills {r} with "@2x". Turning retinaMode on for a URL
    // with no {r} makes flutter_map fake it by upscaling lower-zoom tiles,
    // which just looks blurry.
    return TileLayer(
      urlTemplate: url,
      subdomains:
          url.contains('{s}') ? const ['a', 'b', 'c', 'd'] : const <String>[],
      retinaMode: url.contains('{r}'),
      userAgentPackageName: 'com.greengochat.greengochatapp',
      maxZoom: MapBasemap.maxZoom,
      maxNativeZoom: MapBasemap.maxNativeZoom,
    );
  }

  Widget _light() {
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

  @override
  Widget build(BuildContext context) {
    if (MapBasemapLayer.debugDisableTiles) return const SizedBox.shrink();
    if (widget.light) return _light();
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
