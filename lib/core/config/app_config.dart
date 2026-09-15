import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode, debugPrint;

/// App Configuration
///
/// Feature flags to enable/disable authentication methods and other features.
/// Set these flags based on your environment (MVP, Staging, Production)
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Environment name (for debugging)
  /// This is automatically set based on build mode
  static String get environment => kDebugMode ? 'Development' : 'Production';

  // ============================================================================
  // LOCAL DEVELOPMENT / EMULATOR SETTINGS
  // ============================================================================

  /// Use Firebase Emulators (running in Docker) for local development
  /// Automatically disabled in release builds for production safety
  /// Can be manually overridden for testing with: --dart-define=USE_EMULATORS=true
  static const bool _forceEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: false);

  /// Release builds can never reach an emulator, whatever is defined — that is
  /// the production safety guard and it stays.
  ///
  /// Profile builds can, because that is how the end-to-end suites run on web:
  /// a debug (DDC) build of an app this size times out DWDS's debugger attach
  /// before the tests ever start, so `flutter drive` has to use `--profile`.
  /// Gating on `kDebugMode` there would have pointed the suites — which ban,
  /// reject and delete accounts — at production instead.
  static bool get useLocalEmulators => !kReleaseMode && _forceEmulators;

  /// Emulator host address
  /// - Use '10.0.2.2' for Android Emulator (points to host machine's localhost)
  /// - Use '127.0.0.1' or 'localhost' for iOS Simulator or Web
  /// - Use your machine's local IP (e.g., '192.168.1.x') for physical devices
  ///
  /// Overridable so one build can target more than the Android emulator:
  /// `--dart-define=EMULATOR_HOST=127.0.0.1` is what a web or iOS-simulator
  /// run needs, since 10.0.2.2 only means "the host machine" inside an
  /// Android emulator. Default is unchanged.
  static const String emulatorHost =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

  // Firebase Emulator Ports (standard ports).
  //
  // Overridable too: 8080 in particular is a popular port, and a machine
  // already running something there cannot host the Firestore emulator on the
  // default. Defaults are unchanged.
  static const int authEmulatorPort =
      int.fromEnvironment('EMULATOR_AUTH_PORT', defaultValue: 9099);
  static const int firestoreEmulatorPort =
      int.fromEnvironment('EMULATOR_FIRESTORE_PORT', defaultValue: 8080);
  static const int storageEmulatorPort =
      int.fromEnvironment('EMULATOR_STORAGE_PORT', defaultValue: 9199);
  static const int functionsEmulatorPort =
      int.fromEnvironment('EMULATOR_FUNCTIONS_PORT', defaultValue: 5001);

  // ============================================================================
  // AUTHENTICATION FEATURE FLAGS
  // ============================================================================

  /// Enable/Disable Google Sign-In
  ///
  /// Requirements when enabled:
  /// - Uncomment `google_sign_in` in pubspec.yaml
  /// - Add SHA-1 fingerprint to Firebase Console
  /// - Enable Google Sign-In in Firebase Authentication
  static const bool enableGoogleAuth = false;

  /// Enable/Disable Facebook Login
  ///
  /// Requirements when enabled:
  /// - Uncomment `flutter_facebook_auth` in pubspec.yaml
  /// - Configure Facebook App ID and App Secret
  /// - Enable Facebook in Firebase Authentication
  static const bool enableFacebookAuth = false;

  /// Enable/Disable Biometric Authentication (Fingerprint/Face ID)
  ///
  /// Requirements when enabled:
  /// - Uncomment `local_auth` in pubspec.yaml
  /// - Add biometric permissions to AndroidManifest.xml and Info.plist
  static const bool enableBiometricAuth = false;

  /// Enable/Disable Apple Sign-In
  ///
  /// Requirements when enabled:
  /// - Uncomment `sign_in_with_apple` in pubspec.yaml
  /// - Configure Apple Sign-In in Firebase
  /// - iOS only feature
  static const bool enableAppleAuth = false;

  // ============================================================================
  // UI FEATURE FLAGS
  // ============================================================================

  /// Show social login section on login screen
  /// This will be true if any social auth method is enabled
  static bool get showSocialLoginSection =>
      enableGoogleAuth ||
      enableFacebookAuth ||
      enableBiometricAuth ||
      enableAppleAuth;

  // ============================================================================
  // OTHER FEATURE FLAGS (Future Use)
  // ============================================================================

  /// Enable/Disable in-app purchases
  static const bool enableInAppPurchases = true;

  /// Enable/Disable video calls
  /// Disabled for development due to Agora SDK NDK compatibility issues

  /// Enable/Disable voice messages
  static const bool enableVoiceMessages = false;

  /// Enable/Disable language learning feature
  /// Enabled — language learning is a core differentiator for App Store positioning
  static const bool enableLanguageLearning = true;

  /// Enable/Disable gamification features (achievements, badges, streaks)
  /// Enabled for full feature experience
  static const bool enableGamification = true;

  /// Enable/Disable analytics tracking
  static const bool enableAnalytics = true;

  /// Enable/Disable crash reporting
  static const bool enableCrashReporting = true;

  /// Enable/Disable performance monitoring
  static const bool enablePerformanceMonitoring = true;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get a summary of enabled authentication methods
  static String getEnabledAuthMethods() {
    final methods = <String>['Email/Password'];

    if (enableGoogleAuth) methods.add('Google');
    if (enableFacebookAuth) methods.add('Facebook');
    if (enableAppleAuth) methods.add('Apple');
    if (enableBiometricAuth) methods.add('Biometric');

    return methods.join(', ');
  }

  /// Print configuration (for debugging)
  static void printConfig() {
    debugPrint('=================================');
    debugPrint('App Configuration ($environment)');
    debugPrint('Build Mode: ${kDebugMode ? "DEBUG" : "RELEASE"}');
    debugPrint('=================================');
    debugPrint('Local Emulators: $useLocalEmulators');
    if (useLocalEmulators) {
      debugPrint('Emulator Host: $emulatorHost');
      debugPrint('  - Auth: $emulatorHost:$authEmulatorPort');
      debugPrint('  - Firestore: $emulatorHost:$firestoreEmulatorPort');
      debugPrint('  - Storage: $emulatorHost:$storageEmulatorPort');
      debugPrint('  - Functions: $emulatorHost:$functionsEmulatorPort');
    } else {
      debugPrint('Connected to: PRODUCTION Firebase');
    }
    debugPrint('---------------------------------');
    debugPrint('Auth Methods: ${getEnabledAuthMethods()}');
    debugPrint('Social Login UI: $showSocialLoginSection');
    debugPrint('In-App Purchases: $enableInAppPurchases');
    debugPrint('Language Learning: $enableLanguageLearning');
    debugPrint('Gamification: $enableGamification');
    debugPrint('Analytics: $enableAnalytics');
    debugPrint('Crash Reporting: $enableCrashReporting');
    debugPrint('Performance Monitoring: $enablePerformanceMonitoring');
    debugPrint('=================================');
  }
}
