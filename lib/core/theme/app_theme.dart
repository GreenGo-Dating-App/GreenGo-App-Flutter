import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  /// Design baseline width (standard phone like iPhone 8/SE).
  static const double _baseWidth = 375.0;

  /// Returns a scale factor based on screen width.
  /// Clamped between 1.0 and 1.35.
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / _baseWidth;
    return scale.clamp(1.0, 1.35);
  }

  /// Scale a dimension value based on screen width.
  static double scaled(BuildContext context, double value) {
    return (value * scaleFactor(context)).roundToDouble();
  }

  /// Base dark theme with original font sizes.
  /// Text scaling is handled globally via MediaQuery.textScaler in main.dart,
  /// so ALL text (theme-based and hardcoded) scales proportionally.
  static ThemeData get darkTheme => _buildTheme(1.0);

  /// Scaled theme for non-text dimensions (buttons, icons, padding).
  /// Text sizes stay at base values — MediaQuery.textScaler handles text.
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
        toolbarHeight: s(56),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        iconTheme: IconThemeData(
          color: AppColors.richGold,
          size: s(24),
        ),
      ),

      // Text Theme — base sizes only, MediaQuery.textScaler handles scaling
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
      ),

      // Button Theme — scaled heights
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: AppColors.deepBlack,
          elevation: 0,
          minimumSize: Size(double.infinity, s(AppDimensions.buttonHeightM)),
          padding: EdgeInsets.symmetric(horizontal: s(16), vertical: s(12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s(AppDimensions.radiusM)),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.richGold,
          side: const BorderSide(color: AppColors.richGold, width: 1.5),
          minimumSize: Size(double.infinity, s(AppDimensions.buttonHeightM)),
          padding: EdgeInsets.symmetric(horizontal: s(16), vertical: s(12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s(AppDimensions.radiusM)),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.richGold,
          padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // Input Decoration Theme — scaled padding and radius
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s(AppDimensions.radiusM)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s(AppDimensions.radiusM)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s(AppDimensions.radiusM)),
          borderSide: const BorderSide(color: AppColors.richGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s(AppDimensions.radiusM)),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s(AppDimensions.radiusM)),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: s(AppDimensions.paddingM),
          vertical: s(AppDimensions.paddingM),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        errorStyle: const TextStyle(
          color: AppColors.errorRed,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      ),

      // Card Theme — scaled radius and margin
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s(AppDimensions.cardRadius)),
        ),
        margin: EdgeInsets.all(s(AppDimensions.marginS)),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme — scaled size
      iconTheme: IconThemeData(
        color: AppColors.textPrimary,
        size: s(AppDimensions.iconM),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.deepBlack,
        selectedItemColor: AppColors.richGold,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: 'Poppins',
        ),
      ),

      // Chip Theme — scaled padding
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
        padding: EdgeInsets.symmetric(
          horizontal: s(AppDimensions.paddingM),
          vertical: s(AppDimensions.paddingS),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      ),

      // Dialog Theme — scaled radius
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s(AppDimensions.radiusL)),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
        ),
      ),

      // Snackbar Theme — scaled radius
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.backgroundCard,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s(AppDimensions.radiusS)),
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
