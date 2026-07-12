import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Design tokens for GreenGo's "liquid glass" (glassmorphism) surfaces.
///
/// Track F / Phase 2 of APPLE_APPROVAL_PLAN_v3.0.0. These tokens keep the
/// frosted-glass treatment consistent across the app: blur strength, corner
/// radii, translucent fills, hairline borders, the signature gold glow and the
/// spring/press timings used for tactile feedback.
///
/// Blur is intentionally reserved for structural surfaces (cards, sheets, nav
/// bars) — never long list rows — to protect scroll performance.
class AppGlass {
  AppGlass._();

  // Blur strength applied by BackdropFilter on glass surfaces.
  static const double blurSigma = 18.0;

  // Corner radii.
  static const double radiusCard = 22.0;
  static const double radiusSheet = 28.0;
  static const double radiusPill = 999.0;

  // Translucent surface fills.
  static final Color surface = Colors.white.withOpacity(0.06);
  static final Color surfaceHi = Colors.white.withOpacity(0.10);

  // Hairline borders.
  static final Color border = Colors.white.withOpacity(0.12);
  static final Color borderGold = AppColors.richGold.withOpacity(0.35);

  // Signature gold glow used behind primary CTAs and active glass.
  static final List<BoxShadow> goldGlow = <BoxShadow>[
    BoxShadow(
      color: AppColors.richGold.withOpacity(0.25),
      blurRadius: 24,
      spreadRadius: 1,
    ),
  ];

  // Motion tokens for press interactions.
  static const Cubic spring = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Duration pressDuration = Duration(milliseconds: 180);
}
