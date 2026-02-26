import 'package:flutter/material.dart';

/// Global responsive scaling utility.
///
/// Design baseline: 375px width (standard phone like iPhone 8/SE).
/// On larger screens, all dimensions scale up proportionally.
/// Scale factor is clamped between 1.0 and 1.4.
///
/// Usage:
///   context.rs(16)  — scale any dimension (padding, margin, size, radius)
///   context.scaleFactor — get the raw scale factor
///   Responsive.of(context).scale(16) — alternative static access
class Responsive {
  static const double _baseWidth = 375.0;

  final double scaleFactor;

  Responsive._(this.scaleFactor);

  factory Responsive.of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / _baseWidth).clamp(1.0, 1.4);
    return Responsive._(scale);
  }

  /// Scale a dimension value proportionally to screen width.
  double scale(double value) => (value * scaleFactor).roundToDouble();
}

/// Convenience extension on BuildContext for responsive scaling.
extension ResponsiveExtension on BuildContext {
  /// Scale a dimension proportionally to screen width.
  /// Use for padding, margin, icon size, card size, button height, radius, etc.
  double rs(double value) => Responsive.of(this).scale(value);

  /// The current scale factor (1.0 on 375px, up to 1.4 on larger screens).
  double get scaleFactor => Responsive.of(this).scaleFactor;
}
