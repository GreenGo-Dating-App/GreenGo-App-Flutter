import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// The raster basemaps every `flutter_map` surface draws.
///
/// Two of them, both Esri keyless raster tiles (no key, no account, plain
/// HTTPS, so they render the same in an Android release build as in the
/// browser): Dark Gray Canvas for the globe/explore map, World Street Map
/// (light, labelled, the closest keyless match to Google Maps) for every
/// place map and the location picker.
///
/// Both can be changed from Firestore `app_config/map_style` WITHOUT
/// rebuilding either app. Fields (all optional; a URL only applies together
/// with its attribution, and CARTO URLs are ignored):
///
///   styleUrl            MapLibre style JSON for the vector basemap
///   useVector           true draws the vector style on the globe map
///   tileUrl             globe raster template, e.g. the Esri ones below
///   attribution         credit line for tileUrl (required with it)
///   maxNativeZoom       deepest zoom tileUrl has real tiles for (default 19)
///   lightTileUrl        place-map raster template
///   lightAttribution    credit line for lightTileUrl (required with it)
///   lightMaxNativeZoom  deepest real zoom of lightTileUrl (default 19)
///   maxZoom             furthest the globe map lets users zoom
///   initialZoom         how far in the world map opens (11-13 is city level)
///
/// Some ready-made values, all verified keyless (2026-10):
///   Esri Street   .../World_Street_Map/MapServer/tile/{z}/{y}/{x}
///   Esri Topo     .../World_Topo_Map/MapServer/tile/{z}/{y}/{x}
///   Esri Gray     .../Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x} (native <= 16)
///   Esri Dark     .../Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}  (native <= 16)
///   (CARTO basemaps.cartocdn.com now needs an API key: placeholder tiles.
///   Do NOT use tile.openstreetmap.org: its policy forbids heavy app traffic.)
///
/// Note Esri addresses tiles as {z}/{y}/{x}; most others use {z}/{x}/{y}.
/// Esri's terms: attribution required; commercial production use is meant to
/// run under an ArcGIS Location Platform account (free tier available).
class MapBasemap {
  const MapBasemap._();

  /// Vector style, used only when [useVector] is turned on in config. Left in
  /// place because the migration works end to end in a build; it is off by
  /// default because it did not render reliably on device.
  static const String defaultStyleUrl =
      'https://greengo-chat.web.app/greengo-map-style.json';

  /// CARTO's public basemaps (basemaps.cartocdn.com) now answer every
  /// keyless request with an "API KEY REQUIRED" placeholder tile (HTTP 200,
  /// so nothing errors: the map is just blank). Verified 2026-10 for
  /// light_all, dark_all and voyager, with or without a browser Referer.
  /// Remote config pointing at it is ignored, see [isUsableTileUrl].
  static const String _esri = 'https://server.arcgisonline.com/ArcGIS/rest/services';

  /// The default (dark) basemap for the globe/explore map: Esri Dark Gray
  /// Canvas. Keyless raster; Esri serves real data up to zoom 16 here and
  /// "Map data not yet available" beyond, so [defaultMaxNativeZoom] is 16 and
  /// flutter_map upscales past it.
  static const String defaultTileUrl =
      '$_esri/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
  /// Credit for the default basemap.
  static const String defaultAttribution =
      'Esri, HERE, Garmin, © OpenStreetMap contributors';
  static const double defaultMaxZoom = 19;
  static const int defaultMaxNativeZoom = 16;

  /// The LIGHT basemap for every place map (event venue, experience meeting
  /// point, chat shared location, the location picker): Esri World Street
  /// Map. Keyless raster with street names down to zoom 19, which a "pick the
  /// exact meeting point" map needs (the light-gray canvas stops at 16).
  static const String defaultLightTileUrl =
      '$_esri/World_Street_Map/MapServer/tile/{z}/{y}/{x}';

  /// Required credit for [defaultLightTileUrl].
  static const String defaultLightAttribution =
      'Esri, HERE, Garmin, © OpenStreetMap contributors';
  static const double lightMaxZoom = 19;

  /// False for a template that cannot draw a map: not http(s), no {z}/{x}/{y},
  /// or CARTO (placeholder tiles without a key, see above).
  static bool isUsableTileUrl(String? url) {
    if (url == null) return false;
    final u = url.trim();
    return u.startsWith('https://') &&
        u.contains('{z}') &&
        u.contains('{x}') &&
        u.contains('{y}') &&
        !u.contains('cartocdn.com');
  }

  /// City level. 3-5 is continent/country, 11-13 shows a city and its
  /// surroundings, 15+ is street level.
  static const double defaultInitialZoom = 12;

  static String _styleUrl = defaultStyleUrl;
  static bool _useVector = false;
  static String _tileUrl = defaultTileUrl;
  static String _attribution = defaultAttribution;
  static double _maxZoom = defaultMaxZoom;
  static int _maxNativeZoom = defaultMaxNativeZoom;
  static String _lightTileUrl = defaultLightTileUrl;
  static String _lightAttribution = defaultLightAttribution;
  static int _lightMaxNativeZoom = lightMaxZoom.toInt();
  static double _initialZoom = defaultInitialZoom;

  static String get styleUrl => _styleUrl;

  /// Whether to draw the vector basemap. Off by default; flip it to true in
  /// Firestore to try vector again without shipping a build.
  static bool get useVector => _useVector;

  static String get tileUrl => _tileUrl;
  static String get attribution => _attribution;
  static double get maxZoom => _maxZoom;
  static int get maxNativeZoom => _maxNativeZoom;

  /// The light place-map basemap (remote-overridable as a pair with its
  /// attribution, so the credit always matches the tiles drawn).
  static String get lightTileUrl => _lightTileUrl;
  static String get lightAttribution => _lightAttribution;
  static int get lightMaxNativeZoom => _lightMaxNativeZoom;
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

      // A tile URL and its credit only apply together: a provider switch
      // must never draw new tiles under the old provider's attribution.
      final url = data['tileUrl'] as String?;
      final credit = data['attribution'] as String?;
      if (isUsableTileUrl(url) && credit != null && credit.trim().isNotEmpty) {
        _tileUrl = url!.trim();
        _attribution = credit.trim();
        final native = data['maxNativeZoom'];
        _maxNativeZoom =
            native is num && native >= 1 && native <= 23 ? native.toInt() : 19;
      }

      final lightUrl = data['lightTileUrl'] as String?;
      final lightCredit = data['lightAttribution'] as String?;
      if (isUsableTileUrl(lightUrl) &&
          lightCredit != null &&
          lightCredit.trim().isNotEmpty) {
        _lightTileUrl = lightUrl!.trim();
        _lightAttribution = lightCredit.trim();
        final native = data['lightMaxNativeZoom'];
        _lightMaxNativeZoom =
            native is num && native >= 1 && native <= 23 ? native.toInt() : 19;
      }

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
