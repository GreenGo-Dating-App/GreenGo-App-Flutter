/// Environment Configuration
///
/// Provides environment-specific configuration for the GreenGo app.
/// Configuration is set at build time using --dart-define flags.
///
/// Usage:
///   flutter run --dart-define=ENV=development
///   flutter build apk --dart-define=ENV=production
///
/// Available environments:
///   - development: Local development with emulators
///   - staging: Staging server for testing
///   - production: Production server
library;

enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  final Environment environment;
  final String apiBaseUrl;
  final bool useEmulators;
  final String emulatorHost;
  final String firebaseProjectId;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enablePerformanceMonitoring;
  final LogLevel logLevel;

  const EnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.useEmulators,
    required this.emulatorHost,
    required this.firebaseProjectId,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.enablePerformanceMonitoring,
    required this.logLevel,
  });

  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;

  String get environmentName => environment.name.toUpperCase();
}

enum LogLevel { verbose, debug, info, warning, error, none }

/// Current environment configuration
///
/// Set via --dart-define=ENV=<environment>
class Env {
  static const String _envString = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static Environment get current {
    switch (_envString.toLowerCase()) {
      case 'production':
      case 'prod':
        return Environment.production;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'development':
      case 'dev':
      default:
        return Environment.development;
    }
  }

  static EnvironmentConfig get config {
    switch (current) {
      case Environment.production:
        return _productionConfig;
      case Environment.staging:
        return _stagingConfig;
      case Environment.development:
        return _developmentConfig;
    }
  }

  // ============================================================================
  // DEVELOPMENT CONFIGURATION
  // ============================================================================
  static const _developmentConfig = EnvironmentConfig(
    environment: Environment.development,
    apiBaseUrl: 'http://10.0.2.2:5001/greengochat-a9008/us-central1',
    useEmulators: true,
    emulatorHost: '10.0.2.2', // Android emulator host
    firebaseProjectId: 'greengochat-a9008',
    enableAnalytics: false,
    enableCrashReporting: false,
    enablePerformanceMonitoring: false,
    logLevel: LogLevel.verbose,
  );

  // ============================================================================
  // STAGING CONFIGURATION
  // ============================================================================
  static const _stagingConfig = EnvironmentConfig(
    environment: Environment.staging,
    apiBaseUrl: 'https://staging-api.greengo.app',
    useEmulators: false,
    emulatorHost: '',
    firebaseProjectId: 'greengochat-staging', // Separate staging project
    enableAnalytics: true,
    enableCrashReporting: true,
    enablePerformanceMonitoring: true,
    logLevel: LogLevel.debug,
  );

  // ============================================================================
  // PRODUCTION CONFIGURATION
  // ============================================================================
  static const _productionConfig = EnvironmentConfig(
    environment: Environment.production,
    apiBaseUrl: 'https://api.greengo.app',
    useEmulators: false,
    emulatorHost: '',
    firebaseProjectId: 'greengo-chat',
    enableAnalytics: true,
    enableCrashReporting: true,
    enablePerformanceMonitoring: true,
    logLevel: LogLevel.warning,
  );
}

/// Convenience getters for common configuration values
extension EnvironmentExtensions on Env {
  static bool get useEmulators => Env.config.useEmulators;
  static String get apiBaseUrl => Env.config.apiBaseUrl;
  static bool get isProduction => Env.config.isProduction;
  static bool get isDevelopment => Env.config.isDevelopment;
  static String get emulatorHost => Env.config.emulatorHost;
}
