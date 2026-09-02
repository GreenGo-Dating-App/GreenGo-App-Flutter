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

  /// GreenGo's decluttered take on OpenFreeMap's "Liberty" style, served from
  /// our own hosting. Liberty renders OpenStreetMap data close to Google Maps;
  /// this copy drops POI labels, road labels and shields, and residential /
  /// service / track / path geometry, keeping the motorway-to-tertiary network,
  /// rail, water and place names. 111 layers down to 85.
  ///
  /// Serving it ourselves means the look can be retuned by redeploying hosting
  /// alone — no app build — while the tiles, sprites and glyphs it references
  /// still come from OpenFreeMap. Point styleUrl at
  /// https://tiles.openfreemap.org/styles/liberty for the full-detail original.
  static const String defaultStyleUrl =
      'https://greengo-chat.web.app/greengo-map-style.json';

  /// Raster fallback, used when [useVector] is false or the style fails.
  static const String defaultTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  /// Credit for the default vector basemap. OpenFreeMap renders OpenStreetMap
  /// data, so OSM is who gets named; override it in config alongside a
  /// tileUrl/styleUrl that needs different wording.
  static const String defaultAttribution = 'OpenStreetMap contributors';
  static const double defaultMaxZoom = 19;

  /// City level. 3-5 is continent/country, 11-13 shows a city and its
  /// surroundings, 15+ is street level.
  static const double defaultInitialZoom = 12;

  static String _styleUrl = defaultStyleUrl;
  static bool _useVector = true;
  static String _tileUrl = defaultTileUrl;
  static String _attribution = defaultAttribution;
  static double _maxZoom = defaultMaxZoom;
  static double _initialZoom = defaultInitialZoom;

  static String get styleUrl => _styleUrl;

  /// Whether to draw the vector basemap. Flip this to false in Firestore to
  /// fall straight back to raster tiles without shipping a build.
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
