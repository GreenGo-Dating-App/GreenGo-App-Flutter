import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// The raster basemap every `flutter_map` surface draws.
///
/// Defaults to Esri's World Street Map — the closest keyless match to Google
/// Maps: coloured roads, parks and water with readable labels, but without the
/// full POI/landuse clutter of the raw OpenStreetMap style.
///
/// The style can be changed from Firestore `app_config/map_style` WITHOUT
/// rebuilding and redeploying either app — settling on a look otherwise costs
/// a full build + store/hosting cycle per attempt. Fields (all optional):
///
///   styleUrl     MapLibre style JSON for the vector basemap
///   useVector    false pins the app to the raster fallback below
///   tileUrl      raster template used when useVector is false, or when the
///                vector style fails to load, e.g.
///                https://tile.openstreetmap.org/{z}/{x}/{y}.png
///   attribution  credit line shown on the map
///   maxZoom      furthest zoom the provider serves
///   initialZoom  how far in the world map opens (11-13 is city level)
///
/// Some ready-made values, all verified keyless:
///   Esri Street   .../World_Street_Map/MapServer/tile/{z}/{y}/{x}
///   Esri Topo     .../World_Topo_Map/MapServer/tile/{z}/{y}/{x}
///   Esri Gray     .../Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}
///   CARTO Voyager https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png
///   OSM standard  https://tile.openstreetmap.org/{z}/{x}/{y}.png
///
/// Note Esri addresses tiles as {z}/{y}/{x}; most others use {z}/{x}/{y}.
class MapBasemap {
  const MapBasemap._();

  /// Vector style, used only when [useVector] is turned on in config. Left in
  /// place because the migration works end to end in a build; it is off by
  /// default because it did not render reliably on device.
  static const String defaultStyleUrl =
      'https://greengo-chat.web.app/greengo-map-style.json';

  /// The basemap: CARTO "Dark Matter". Minimal by design — muted dark land,
  /// water and a thin road network with sparse labels — free, no API key, and
  /// verified serving real 256px tiles (and @2x retina) at every zoom.
  static const String defaultTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  /// Credit for the default basemap: CARTO renders OpenStreetMap data.
  static const String defaultAttribution = 'CARTO, OpenStreetMap contributors';
  static const double defaultMaxZoom = 19;

  /// City level. 3-5 is continent/country, 11-13 shows a city and its
  /// surroundings, 15+ is street level.
  static const double defaultInitialZoom = 12;

  static String _styleUrl = defaultStyleUrl;
  static bool _useVector = false;
  static String _tileUrl = defaultTileUrl;
  static String _attribution = defaultAttribution;
  static double _maxZoom = defaultMaxZoom;
  static double _initialZoom = defaultInitialZoom;

  static String get styleUrl => _styleUrl;

  /// Whether to draw the vector basemap. Off by default; flip it to true in
  /// Firestore to try vector again without shipping a build.
  static bool get useVector => _useVector;

  static String get tileUrl => _tileUrl;
  static String get attribution => _attribution;
  static double get maxZoom => _maxZoom;
  static double get initialZoom => _initialZoom;

  /// Pull the override once at startup. Best-effort: any failure leaves the
  /// defaults in place, so the map always draws something.
  static Future<void> load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('map_style')
          .get();
      final data = doc.data();
      if (data == null) return;

      final style = data['styleUrl'] as String?;
      if (style != null && style.startsWith('http')) _styleUrl = style;

      final vector = data['useVector'];
      if (vector is bool) _useVector = vector;

      final url = data['tileUrl'] as String?;
      if (url != null && url.contains('{z}')) _tileUrl = url;

      final credit = data['attribution'] as String?;
      if (credit != null && credit.isNotEmpty) _attribution = credit;

      final zoom = data['maxZoom'];
      if (zoom is num && zoom > 0 && zoom <= 23) _maxZoom = zoom.toDouble();

      final start = data['initialZoom'];
      if (start is num && start >= 1 && start <= 20) {
        _initialZoom = start.toDouble();
      }
    } catch (e) {
      debugPrint('MapBasemap: using defaults ($e)');
    }
  }
}
