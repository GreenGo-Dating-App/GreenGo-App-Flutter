import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  /// Design baseline width (standard phone like iPhone 8/SE).
  /// Screens wider than this get proportionally larger text.
  static const double _baseWidth = 375.0;

  /// Returns a scale factor based on screen width.
  /// Clamped between 1.0 (never shrink below base) and 1.35 (cap for very large screens).
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / _baseWidth;
    return scale.clamp(1.0, 1.35);
  }

  /// Scaled font size helper.
  static double _sf(BuildContext context, double baseSize) {
    return (baseSize * scaleFactor(context)).roundToDouble();
  }

  /// The original static theme (no scaling) used as initial theme in MaterialApp.
  static ThemeData get darkTheme => _buildTheme(1.0);

  /// Context-aware scaled theme — call from Builder widget below MaterialApp.
  static ThemeData scaledDarkTheme(BuildContext context) {
    return _buildTheme(scaleFactor(context));
  }

  static ThemeData _buildTheme(double sf) {
    double s(double base) => (base * sf).roundToDouble();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.richGold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.richGold,
        secondary: AppColors.accentGold,
        surface: AppColors.backgroundCard,
        background: AppColors.backgroundDark,
        error: AppColors.errorRed,
        onPrimary: AppColors.deepBlack,
        onSecondary: AppColors.deepBlack,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: s(20),
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        iconTheme: const IconThemeData(
          color: AppColors.richGold,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: s(32),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        displayMedium: TextStyle(
          fontSize: s(28),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        displaySmall: TextStyle(
          fontSize: s(24),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        headlineLarge: TextStyle(
          fontSize: s(22),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        headlineMedium: TextStyle(
          fontSize: s(20),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        headlineSmall: TextStyle(
          fontSize: s(18),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        titleLarge: TextStyle(
          fontSize: s(16),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        titleMedium: TextStyle(
          fontSize: s(14),
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        titleSmall: TextStyle(
          fontSize: s(12),
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
        bodyLarge: TextStyle(
          fontSize: s(16),
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        bodyMedium: TextStyle(
          fontSize: s(14),
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        bodySmall: TextStyle(
          fontSize: s(12),
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
        labelLarge: TextStyle(
          fontSize: s(14),
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        labelMedium: TextStyle(
          fontSize: s(12),
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
        labelSmall: TextStyle(
          fontSize: s(10),
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: AppColors.deepBlack,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          textStyle: TextStyle(
            fontSize: s(16),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.richGold,
          side: const BorderSide(color: AppColors.richGold, width: 1.5),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          textStyle: TextStyle(
            fontSize: s(16),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.richGold,
          textStyle: TextStyle(
            fontSize: s(14),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.richGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        hintStyle: TextStyle(
          color: AppColors.textTertiary,
          fontSize: s(14),
          fontFamily: 'Poppins',
        ),
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: s(14),
          fontFamily: 'Poppins',
        ),
        errorStyle: TextStyle(
          color: AppColors.errorRed,
          fontSize: s(12),
          fontFamily: 'Poppins',
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        margin: const EdgeInsets.all(AppDimensions.marginS),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppDimensions.iconM,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.deepBlack,
        selectedItemColor: AppColors.richGold,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: s(12),
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: s(12),
          fontWeight: FontWeight.normal,
          fontFamily: 'Poppins',
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundInput,
        selectedColor: AppColors.richGold,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.deepBlack,
          fontFamily: 'Poppins',
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        titleTextStyle: TextStyle(
          fontSize: s(20),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        contentTextStyle: TextStyle(
          fontSize: s(14),
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.backgroundCard,
        contentTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: s(14),
          fontFamily: 'Poppins',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.richGold;
          }
          return AppColors.textTertiary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.richGold.withOpacity(0.5);
          }
          return AppColors.divider;
        }),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.richGold;
          }
          return AppColors.textTertiary;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.richGold;
          }
          return AppColors.textTertiary;
        }),
        checkColor: MaterialStateProperty.all(AppColors.deepBlack),
      ),
    );
  }
}
