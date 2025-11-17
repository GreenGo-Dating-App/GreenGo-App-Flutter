import 'package:flutter/material.dart';

/// GreenGoChat Color Palette
/// Following the brand guidelines with gold and black theme
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color richGold = Color(0xFFD4AF37);
  static const Color deepBlack = Color(0xFF0A0A0A);

  // Secondary Colors
  static const Color accentGold = Color(0xFFFFD700);
  static const Color charcoal = Color(0xFF1A1A1A);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textTertiary = Color(0xFFB0B0B0);

  // Status Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFDC2626);

  // UI Elements
  static const Color backgroundDark = Color(0xFF0A0A0A);
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

  // Shadow Colors
  static final Color shadowLight = Colors.black.withOpacity(0.1);
  static final Color shadowMedium = Colors.black.withOpacity(0.3);
  static final Color shadowHeavy = Colors.black.withOpacity(0.5);

  // Online Status
  static const Color online = Color(0xFF10B981);
  static const Color away = Color(0xFFF59E0B);
  static const Color offline = Color(0xFF6B7280);
}
