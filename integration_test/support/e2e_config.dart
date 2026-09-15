/// Configuration for the end-to-end suites.
///
/// Everything comes from `--dart-define`, never from a literal in the test
/// tree: these suites sign in as real accounts, and a password committed to
/// git is a password that has to be rotated.
///
/// Example:
/// ```
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/all_tests.dart \
///   -d chrome \
///   --dart-define=E2E_APPROVED_EMAIL=approved@e2e.greengo.test \
///   --dart-define=E2E_APPROVED_PASSWORD=... \
///   --dart-define=E2E_USE_EMULATOR=true
/// ```
class E2EConfig {
  const E2EConfig._();

  /// When true the app under test is expected to be pointed at the local
  /// Firebase emulator suite, and the suites are free to seed and delete data.
  /// Against production they must stay read-only, so destructive tests assert
  /// [requireEmulator] first and fail rather than quietly skipping.
  static const bool useEmulator =
      bool.fromEnvironment('E2E_USE_EMULATOR', defaultValue: true);

  static const String emulatorHost =
      String.fromEnvironment('E2E_EMULATOR_HOST', defaultValue: '127.0.0.1');

  // --- Seeded fixture accounts ----------------------------------------------
  // Six states the access gate can resolve to. Seed them with
  // `tool/e2e_seed.dart` (or the emulator import) before running the suites.

  static const String approvedEmail =
      String.fromEnvironment('E2E_APPROVED_EMAIL', defaultValue: 'approved@e2e.greengo.test');
  static const String approvedPassword =
      String.fromEnvironment('E2E_APPROVED_PASSWORD', defaultValue: 'E2e-Approved!2026');

  /// Second real account, needed by every two-party test (chat, groups, block).
  static const String peerEmail =
      String.fromEnvironment('E2E_PEER_EMAIL', defaultValue: 'peer@e2e.greengo.test');
  static const String peerPassword =
      String.fromEnvironment('E2E_PEER_PASSWORD', defaultValue: 'E2e-Peer!2026');

  static const String pendingEmail =
      String.fromEnvironment('E2E_PENDING_EMAIL', defaultValue: 'pending@e2e.greengo.test');
  static const String pendingPassword =
      String.fromEnvironment('E2E_PENDING_PASSWORD', defaultValue: 'E2e-Pending!2026');

  static const String rejectedEmail =
      String.fromEnvironment('E2E_REJECTED_EMAIL', defaultValue: 'rejected@e2e.greengo.test');
  static const String rejectedPassword =
      String.fromEnvironment('E2E_REJECTED_PASSWORD', defaultValue: 'E2e-Rejected!2026');

  static const String bannedEmail =
      String.fromEnvironment('E2E_BANNED_EMAIL', defaultValue: 'banned@e2e.greengo.test');
  static const String bannedPassword =
      String.fromEnvironment('E2E_BANNED_PASSWORD', defaultValue: 'E2e-Banned!2026');

  static const String adminEmail =
      String.fromEnvironment('E2E_ADMIN_EMAIL', defaultValue: 'admin@e2e.greengo.test');
  static const String adminPassword =
      String.fromEnvironment('E2E_ADMIN_PASSWORD', defaultValue: 'E2e-Admin!2026');

  /// Account with no `profiles/{uid}` document, for the onboarding paths.
  static const String freshEmail =
      String.fromEnvironment('E2E_FRESH_EMAIL', defaultValue: 'fresh@e2e.greengo.test');
  static const String freshPassword =
      String.fromEnvironment('E2E_FRESH_PASSWORD', defaultValue: 'E2e-Fresh!2026');

  // --- Timing ---------------------------------------------------------------

  /// How long a screen gets to appear before a test calls it a failure.
  ///
  /// A re-booted app (every test after the first pumps a fresh root rather
  /// than re-running `main()`) starts from AuthInitial and has to re-resolve
  /// the whole gate — auth stream, profile read, access record, post-login
  /// splash — before the shell appears. 20s was not enough for that on a real
  /// backend; the first runs failed here rather than on anything the app did
  /// wrong.
  static const Duration screenTimeout = Duration(seconds: 45);

  /// Budget asserted by BOOT-01: a logged-in cold start must paint something
  /// real within this. It is the actual bug's acceptance criterion.
  static const Duration bootBudget = Duration(seconds: 15);

  /// How long a live Firestore update gets to reach the other party.
  static const Duration realtimeBudget = Duration(seconds: 10);
}
