import 'package:flutter/material.dart';

/// GreenGoChat Color Palette
/// Following the brand guidelines with gold and black theme
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color richGold = Color(0xFFD4AF37);
  static const Color gold = richGold; // Alias for convenience
  static const Color deepBlack = Color(0xFF0A0A0A);

  // Secondary Colors
  static const Color accentGold = Color(0xFFFFD700);
  static const Color charcoal = Color(0xFF1A1A1A);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textTertiary = Color(0xFFB0B0B0);

  // Pure Colors
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);

  // Status Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color infoBlue = Color(0xFF3B82F6);

  // "Liquid Gold" auth screens (login, waiting). Contrast on [liquidBase]:
  // liquidText 17.1:1, liquidTagline 13.1:1, liquidMuted 9.9:1,
  // liquidGoldLight 12.1:1, liquidHint 7.3:1; liquidInk on the gold button
  // 8.0-12.8:1. Text on the glass card stays >= 4.3:1 over a glow peak.
  static const Color liquidBase = Color(0xFF070604); // near-black, warm
  static const Color liquidGoldLight = Color(0xFFE9C46A); // links, glows
  static const Color liquidGoldBright = Color(0xFFF0CF7A); // focus, button top
  static const Color liquidGoldDeep = Color(0xFFC9A227); // button bottom
  static const Color liquidGoldCream = Color(0xFFFFF4D6); // shimmer band
  static const Color liquidInk = Color(0xFF120E05); // text on gold
  static const Color liquidText = Color(0xFFF3EBDD); // input text
  static const Color liquidTagline = Color(0xFFD9CFBE);
  static const Color liquidMuted = Color(0xFFBFB49F); // labels, footer
  static const Color liquidHint = Color(0xFFA39A88);

  // UI Elements
  // Owner 2026-10-25: app background #101010 (was #0A0A0A, near pure black).
  static const Color backgroundDark = Color(0xFF101010);
  static const Color backgroundCard = Color(0xFF1A1A1A);
  static const Color backgroundInput = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF3A3A3A);

  // Gradient Colors
  static const LinearGradient goldGradient = LinearGradient(
    colors: [accentGold, richGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [deepBlack, charcoal],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Primary gradient alias for consistency
  static const LinearGradient primaryGradient = goldGradient;

  // Shadow Colors
  static final Color shadowLight = Colors.black.withValues(alpha: 0.1);
  static final Color shadowMedium = Colors.black.withValues(alpha: 0.3);
  static final Color shadowHeavy = Colors.black.withValues(alpha: 0.5);

  // Membership Tier Colors
  static const Color basePurple = Color(0xFFB388FF);       // Light purple for GreenGo Base
  static const Color basePurpleDark = Color(0xFF7C4DFF);   // Darker purple for gradients
  static const Color platinumBlue = Color(0xFF81D4FA);     // Light blue for Platinum
  static const Color platinumBlueDark = Color(0xFF29B6F6); // Darker blue for gradients

  // Online Status
  static const Color online = Color(0xFF10B981);
  static const Color away = Color(0xFFF59E0B);
  static const Color offline = Color(0xFF6B7280);
}
