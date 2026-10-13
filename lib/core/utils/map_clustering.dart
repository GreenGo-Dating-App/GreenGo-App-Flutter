import 'dart:math' as math;

/// A group of map items drawn as one marker: a single pin when [items] has
/// one entry, a count bubble otherwise.
class MapCluster<T> {
  const MapCluster({
    required this.id,
    required this.items,
    required this.lat,
    required this.lng,
  });

  /// Stable for the same members at the same zoom band, so it can key the
  /// marker widget (flutter_map then reuses it instead of rebuilding).
  final String id;
  final List<T> items;

  /// Where the marker sits: the members' average position.
  final double lat;
  final double lng;

  bool get isSingle => items.length == 1;
}

/// Web-mercator pixel position of [lat],[lng] at [zoom] (256px tiles).
math.Point<double> _pixel(double lat, double lng, double zoom) {
  final scale = 256 * math.pow(2, zoom);
  final x = (lng + 180) / 360 * scale;
  final s = math.sin(lat.clamp(-85.05112878, 85.05112878) * math.pi / 180);
  final y = (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * scale;
  return math.Point(x, y);
}

/// Groups [items] into screen-space grid cells of [cellPixels] at [zoom].
///
/// One linear pass with a hash map (O(n)), so thousands of pins re-cluster in
/// well under a frame. Cells are aligned to the world pixel grid, not the
/// viewport, so panning never reshuffles clusters; only a zoom-band change
/// does. Callers should pass a whole-number zoom (the band) so the result is
/// cacheable while the user pans or pinches inside one band.
List<MapCluster<T>> clusterByGrid<T>(
  Iterable<T> items, {
  required double Function(T) lat,
  required double Function(T) lng,
  required String Function(T) id,
  required double zoom,
  double cellPixels = 64,
}) {
  final cells = <String, List<T>>{};
  for (final item in items) {
    final p = _pixel(lat(item), lng(item), zoom);
    final key = '${(p.x / cellPixels).floor()}:${(p.y / cellPixels).floor()}';
    (cells[key] ??= <T>[]).add(item);
  }
  return [
    for (final e in cells.entries)
      _clusterOf(
        e.value.length == 1 ? id(e.value.first) : 'z${zoom.floor()}:${e.key}',
        e.value,
        lat,
        lng,
      ),
  ];
}

/// Groups [items] by [keyOf] (e.g. country). Items whose key is empty are
/// left out. [anchor] may place a group somewhere other than its members'
/// average (a country's centroid); returning null falls back to the average.
List<MapCluster<T>> clusterByKey<T>(
  Iterable<T> items, {
  required String Function(T) keyOf,
  required double Function(T) lat,
  required double Function(T) lng,
  (double, double)? Function(String key)? anchor,
}) {
  final groups = <String, List<T>>{};
  for (final item in items) {
    final k = keyOf(item);
    if (k.isEmpty) continue;
    (groups[k] ??= <T>[]).add(item);
  }
  return [
    for (final e in groups.entries)
      () {
        final c = _clusterOf('key:${e.key}', e.value, lat, lng);
        final a = anchor?.call(e.key);
        return a == null
            ? c
            : MapCluster<T>(id: c.id, items: c.items, lat: a.$1, lng: a.$2);
      }(),
  ];
}

MapCluster<T> _clusterOf<T>(
  String id,
  List<T> members,
  double Function(T) lat,
  double Function(T) lng,
) {
  var sumLat = 0.0, sumLng = 0.0;
  for (final m in members) {
    sumLat += lat(m);
    sumLng += lng(m);
  }
  return MapCluster<T>(
    id: id,
    items: members,
    lat: sumLat / members.length,
    lng: sumLng / members.length,
  );
}
