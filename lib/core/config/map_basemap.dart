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
///   tileUrl      raster template, e.g.
///                https://tile.openstreetmap.org/{z}/{x}/{y}.png
///   attribution  credit line shown on the map
///   maxZoom      furthest zoom the provider serves
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

  static const String defaultTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  static const String defaultAttribution =
      'Esri, HERE, Garmin, OpenStreetMap contributors';
  static const double defaultMaxZoom = 19;

  static String _tileUrl = defaultTileUrl;
  static String _attribution = defaultAttribution;
  static double _maxZoom = defaultMaxZoom;

  static String get tileUrl => _tileUrl;
  static String get attribution => _attribution;
  static double get maxZoom => _maxZoom;

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

      final url = data['tileUrl'] as String?;
      if (url != null && url.contains('{z}')) _tileUrl = url;

      final credit = data['attribution'] as String?;
      if (credit != null && credit.isNotEmpty) _attribution = credit;

      final zoom = data['maxZoom'];
      if (zoom is num && zoom > 0 && zoom <= 23) _maxZoom = zoom.toDouble();
    } catch (e) {
      debugPrint('MapBasemap: using defaults ($e)');
    }
  }
}
