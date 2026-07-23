import 'package:flutter/foundation.dart' show debugPrint;

/// App build flavor.
///
/// GreenGo ships from a single Flutter codebase. As of v3.0.0 the
/// cultural-exchange, Explore-first, **non-dating** experience is the default
/// on every platform (web, iOS and Android):
/// - [culture] — dating mechanics OFF. The universal default (`main.dart`).
/// - [full]    — dating mechanics ON. Opt-in build (`main_full.dart`) that
///   re-enables the swipe/matching product for a future "full" distribution.
///
/// See `APPLE_APPROVAL_PLAN_v3.0.0.md` (§2 "UNIFY EVERYWHERE").
enum AppFlavor {
  /// Cultural-exchange build — every dating-oriented feature disabled.
  /// This is the global default across web, iOS and Android.
  culture,

  /// Full product — every dating-oriented feature enabled. Opt-in only.
  full,
}

/// Flavor Configuration
///
/// Central, dependency-free switch that lets the app consult which build it is
/// running as and gate dating-oriented features accordingly. The active flavor
/// is selected by the entrypoint before `runApp`:
/// - `main.dart`      → [AppFlavor.culture] (the default — no override needed)
/// - `main_full.dart` → [AppFlavor.full]   (opt-in, re-enables dating)
///
/// Feature code branches on [exploreFirst] (Explore-first shell) and the
/// individual `enable*` flags to hide/strip dating features when running as
/// [AppFlavor.culture].
class FlavorConfig {
  // Private constructor to prevent instantiation.
  FlavorConfig._();

  /// The active build flavor. Defaults to [AppFlavor.culture] so the
  /// cultural-exchange experience is the safe, universal default; the opt-in
  /// `main_full.dart` entrypoint overrides this at startup.
  static AppFlavor current = AppFlavor.culture;

  /// Whether the current flavor is the full (dating-enabled) product.
  static bool get isFull => current == AppFlavor.full;

  /// Whether the current flavor is the cultural-exchange (dating-off) build.
  static bool get isCulture => current == AppFlavor.culture;

  // ============================================================================
  // DATING FEATURE FLAGS
  //
  // All true on [AppFlavor.full], all false on [AppFlavor.culture].
  // ============================================================================

  /// Swipe-deck people discovery (like / super-like / nope).
  static bool get enableSwipeDiscovery => isFull;

  /// Mutual-like "match" mechanic and the matches surface.
  static bool get enableMatching => isFull;

  /// Video profiles.
  static bool get enableVideoProfiles => isFull;

  // ============================================================================
  // CONVENIENCE
  // ============================================================================

  /// Whether the app should present the Explore-first glass shell (the default)
  /// instead of the swipe DiscoveryScreen home. True whenever the swipe deck is
  /// disabled — i.e. on the [AppFlavor.culture] build.
  static bool get exploreFirst => !enableSwipeDiscovery;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Print the active flavor configuration (for debugging).
  static void printConfig() {
    debugPrint('=================================');
    debugPrint('Flavor Configuration');
    debugPrint('Active Flavor: ${current.name}');
    debugPrint('Explore-first: $exploreFirst');
    debugPrint('---------------------------------');
    debugPrint('Swipe Discovery: $enableSwipeDiscovery');
    debugPrint('Matching: $enableMatching');
    debugPrint('Video Profiles: $enableVideoProfiles');
    debugPrint('=================================');
  }
}
