class TestConfig {
  static const bool useMockData = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const String mockApiUrl = 'http://localhost:8080';

  static const String firestoreEmulatorHost = 'localhost';
  static const int firestoreEmulatorPort = 8081;

  static const String authEmulatorHost = 'localhost';
  static const int authEmulatorPort = 9099;

  static const String storageEmulatorHost = 'localhost';
  static const int storageEmulatorPort = 9199;
}
