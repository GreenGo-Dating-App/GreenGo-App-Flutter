import 'package:flutter/widgets.dart';

/// Non-destructive position of a cover / main photo inside whatever frame
/// shows it (owner request 2026-10-21: users position the cover to fit).
///
/// Stored next to the image URL as `coverFocalX`, `coverFocalY` (Flutter
/// [Alignment] coordinates, -1..1, 0 = centre) and `coverZoom` (1..3, 1 = no
/// zoom). Every display applies it with `BoxFit.cover` + [alignment] and a
/// [zoom] scale about the same point ([FocalCoverImage]), so one picture fits
/// every frame shape (16:9 editor, wide headers, square tiles) showing the
/// part the user chose. Missing fields (every doc before 5.0.52) = centre.
@immutable
class CoverFocus {
  const CoverFocus({this.x = 0, this.y = 0, this.zoom = 1});

  /// Centre, no zoom: the default for legacy docs.
  static const center = CoverFocus();

  static const double maxZoom = 3;

  static const kX = 'coverFocalX';
  static const kY = 'coverFocalY';
  static const kZoom = 'coverZoom';

  /// Horizontal focal point, -1 (left edge) .. 1 (right edge).
  final double x;

  /// Vertical focal point, -1 (top edge) .. 1 (bottom edge).
  final double y;

  /// Extra zoom on top of BoxFit.cover, 1..[maxZoom].
  final double zoom;

  Alignment get alignment => Alignment(x, y);

  bool get isCenter => x == 0 && y == 0 && zoom == 1;

  /// Clamped copy (bad / out-of-range stored values never break a layout).
  CoverFocus clamped() => CoverFocus(
        x: _clamp(x, -1, 1, 0),
        y: _clamp(y, -1, 1, 0),
        zoom: _clamp(zoom, 1, maxZoom, 1),
      );

  CoverFocus copyWith({double? x, double? y, double? zoom}) => CoverFocus(
        x: x ?? this.x,
        y: y ?? this.y,
        zoom: zoom ?? this.zoom,
      ).clamped();

  /// Reads `coverFocalX/Y` + `coverZoom` from a Firestore / JSON map.
  factory CoverFocus.fromMap(Map<String, dynamic>? data) {
    if (data == null) return center;
    double? n(Object? v) => v is num ? v.toDouble() : null;
    return CoverFocus(
      x: n(data[kX]) ?? 0,
      y: n(data[kY]) ?? 0,
      zoom: n(data[kZoom]) ?? 1,
    ).clamped();
  }

  /// The three fields, ready to merge into a document write.
  Map<String, double> toMap() {
    final c = clamped();
    return {kX: c.x, kY: c.y, kZoom: c.zoom};
  }

  static double _clamp(double v, double min, double max, double fallback) {
    if (v.isNaN || v.isInfinite) return fallback;
    return v < min ? min : (v > max ? max : v);
  }

  @override
  bool operator ==(Object other) =>
      other is CoverFocus && other.x == x && other.y == y && other.zoom == zoom;

  @override
  int get hashCode => Object.hash(x, y, zoom);

  @override
  String toString() => 'CoverFocus($x, $y, x$zoom)';
}
