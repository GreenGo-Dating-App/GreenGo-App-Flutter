import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// The raster basemap every `flutter_map` surface draws: Esri World Street
/// Map (light, labelled, the closest keyless match to Google Maps). Keyless
/// raster - no key, no account, plain HTTPS - so it renders the same in an
/// Android release build as in the browser. The event venue, experience
/// meeting point, chat shared location, location pickers and the network
/// (world) map all use it.
///
/// It can be changed from Firestore `app_config/map_style` WITHOUT
/// rebuilding either app. Fields (all optional; a URL only applies together
/// with its attribution, and CARTO URLs are ignored):
///
///   lightTileUrl        raster template
///   lightAttribution    credit line for lightTileUrl (required with it)
///   lightMaxNativeZoom  deepest real zoom of lightTileUrl (default 19)
///   initialZoom         how far in the network map opens (11-13 is city level)
///
/// (Older builds also read `styleUrl`, `useVector`, `tileUrl`, `attribution`,
/// `maxNativeZoom` and `maxZoom` for the former dark globe basemap; this
/// build ignores them.)
///
/// Some ready-made values, all verified keyless (2026-10):
///   Esri Street   .../World_Street_Map/MapServer/tile/{z}/{y}/{x}
///   Esri Topo     .../World_Topo_Map/MapServer/tile/{z}/{y}/{x}
///   Esri Gray     .../Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x} (native <= 16)
///   (CARTO basemaps.cartocdn.com now needs an API key: placeholder tiles.
///   Do NOT use tile.openstreetmap.org: its policy forbids heavy app traffic.)
///
/// Note Esri addresses tiles as {z}/{y}/{x}; most others use {z}/{x}/{y}.
/// Esri's terms: attribution required; commercial production use is meant to
/// run under an ArcGIS Location Platform account (free tier available).
class MapBasemap {
  const MapBasemap._();

  /// CARTO's public basemaps (basemaps.cartocdn.com) now answer every
  /// keyless request with an "API KEY REQUIRED" placeholder tile (HTTP 200,
  /// so nothing errors: the map is just blank). Verified 2026-10 for
  /// light_all, dark_all and voyager, with or without a browser Referer.
  /// Remote config pointing at it is ignored, see [isUsableTileUrl].
  static const String _esri = 'https://server.arcgisonline.com/ArcGIS/rest/services';

  /// The LIGHT basemap for every place map (event venue, experience meeting
  /// point, chat shared location, the location picker, the network map):
  /// Esri World Street Map. Keyless raster with street names down to zoom 19,
  /// which a "pick the exact meeting point" map needs (the light-gray canvas
  /// stops at 16).
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

  static String _lightTileUrl = defaultLightTileUrl;
  static String _lightAttribution = defaultLightAttribution;
  static int _lightMaxNativeZoom = lightMaxZoom.toInt();
  static double _initialZoom = defaultInitialZoom;

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

      final start = data['initialZoom'];
      if (start is num && start >= 1 && start <= 20) {
        _initialZoom = start.toDouble();
      }
    } catch (e) {
      debugPrint('MapBasemap: using defaults ($e)');
    }
  }
}
