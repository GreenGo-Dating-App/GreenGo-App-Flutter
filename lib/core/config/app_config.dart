/// App Configuration
///
/// Feature flags to enable/disable authentication methods and other features.
/// Set these flags based on your environment (MVP, Staging, Production)
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Environment name (for debugging)
  static const String environment = 'MVP';

  // ============================================================================
  // LOCAL DEVELOPMENT / EMULATOR SETTINGS
  // ============================================================================

  /// Use Firebase Emulators (running in Docker) for local development
  /// Set to true when developing locally with Docker containers
  /// Set to false when testing against production Firebase
  static const bool useLocalEmulators = true;

  /// Emulator host address
  /// - Use '10.0.2.2' for Android Emulator (points to host machine's localhost)
  /// - Use '127.0.0.1' or 'localhost' for iOS Simulator or Web
  /// - Use your machine's local IP (e.g., '192.168.1.x') for physical devices
  static const String emulatorHost = '10.0.2.2';

  // Firebase Emulator Ports (standard ports)
  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;
  static const int storageEmulatorPort = 9199;
  static const int functionsEmulatorPort = 5001;

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
  static const bool enableVideoCalls = false;

  /// Enable/Disable voice messages
  static const bool enableVoiceMessages = false;

  /// Enable/Disable language learning feature
  /// Set to false for MVP to focus on core dating features
  static const bool enableLanguageLearning = false;

  /// Enable/Disable gamification features (achievements, badges, streaks)
  /// Set to false for MVP to focus on core dating features
  static const bool enableGamification = false;

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
    final List<String> methods = ['Email/Password'];

    if (enableGoogleAuth) methods.add('Google');
    if (enableFacebookAuth) methods.add('Facebook');
    if (enableAppleAuth) methods.add('Apple');
    if (enableBiometricAuth) methods.add('Biometric');

    return methods.join(', ');
  }

  /// Print configuration (for debugging)
  static void printConfig() {
    print('=================================');
    print('App Configuration ($environment)');
    print('=================================');
    print('Local Emulators: $useLocalEmulators');
    if (useLocalEmulators) {
      print('Emulator Host: $emulatorHost');
      print('  - Auth: $emulatorHost:$authEmulatorPort');
      print('  - Firestore: $emulatorHost:$firestoreEmulatorPort');
      print('  - Storage: $emulatorHost:$storageEmulatorPort');
      print('  - Functions: $emulatorHost:$functionsEmulatorPort');
    }
    print('---------------------------------');
    print('Auth Methods: ${getEnabledAuthMethods()}');
    print('Social Login UI: $showSocialLoginSection');
    print('In-App Purchases: $enableInAppPurchases');
    print('Video Calls: $enableVideoCalls');
    print('Language Learning: $enableLanguageLearning');
    print('Gamification: $enableGamification');
    print('Analytics: $enableAnalytics');
    print('=================================');
  }
}
