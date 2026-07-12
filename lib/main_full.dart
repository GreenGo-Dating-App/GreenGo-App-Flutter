import 'core/config/flavor_config.dart';
import 'main.dart' as app;

/// "Full" (dating-enabled) entrypoint — the opt-in build.
///
/// As of v3.0.0 the cultural-exchange, Explore-first, non-dating experience is
/// the universal default (`lib/main.dart` → [AppFlavor.culture], shipped on web,
/// iOS and Android). This entrypoint runs the exact same bootstrap but first
/// flips the flavor to [AppFlavor.full] so every dating-oriented feature
/// (swipe discovery, matching, blind date, date scheduler, second chance,
/// share my date, special modes, virtual gifts, video profiles) is re-enabled.
///
/// It exists so the full product can be re-composed for a future distribution
/// without touching the default build. See `APPLE_APPROVAL_PLAN_v3.0.0.md`.
///
/// Build with:
///   flutter build apk --target lib/main_full.dart
void main() {
  // Select the full (dating-enabled) flavor BEFORE any bootstrap runs, so every
  // consumer of FlavorConfig sees the correct flavor from the first frame.
  FlavorConfig.current = AppFlavor.full;
  FlavorConfig.printConfig();

  // Delegate to the shared bootstrap in main.dart (Firebase init, DI, services,
  // runApp) — identical setup, no duplicated logic.
  app.main();
}
