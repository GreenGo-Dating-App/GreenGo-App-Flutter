import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/app_localizations.dart';
import 'tour_environment.dart';

/// One "What's new" edition: 2-3 localized bullets (icon + text).
class WhatsNewBullet {
  const WhatsNewBullet(this.icon, this.text);
  final IconData icon;
  final String Function(AppLocalizations l10n) text;
}

/// Editions keyed by app version (major.minor.patch, no build number).
///
/// To add an edition: add the version here with 2-3 bullets whose strings
/// live in all 7 ARBs. Users updating from an older version see the newest
/// edition that is <= the running version, once.
final Map<String, List<WhatsNewBullet>> whatsNewEditions = {
  '5.0.43': [
    WhatsNewBullet(Icons.public, (l) => l.whatsNew5043WorldMap),
    WhatsNewBullet(Icons.storefront, (l) => l.whatsNew5043Businesses),
    WhatsNewBullet(Icons.people_outline, (l) => l.whatsNew5043Followers),
  ],
};

/// Decides and shows the once-per-version "What's new" sheet.
class WhatsNew {
  WhatsNew._();

  /// Per-device key holding the last app version the user has "seen".
  static const String prefKey = 'whats_new_last_seen_version';

  /// Compares two `a.b.c[+build]` versions numerically (build ignored).
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    final pa = parts(a);
    final pb = parts(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  /// The edition to show, or null.
  ///
  /// * Fresh install ([lastSeen] null and not [isExistingUser]): nothing —
  ///   those users get the welcome carousel and the main tour instead.
  /// * Otherwise the newest edition newer than [lastSeen] (any, when an
  ///   existing user has never stored one) and not newer than
  ///   [currentVersion].
  static String? editionToShow({
    required String currentVersion,
    required String? lastSeen,
    required bool isExistingUser,
    required Iterable<String> editions,
  }) {
    if (lastSeen == null && !isExistingUser) return null;
    String? best;
    for (final v in editions) {
      if (compareVersions(v, currentVersion) > 0) continue;
      if (lastSeen != null && compareVersions(v, lastSeen) <= 0) continue;
      if (best == null || compareVersions(v, best) > 0) best = v;
    }
    return best;
  }

  /// Records the running version without showing anything (new users).
  static Future<void> recordSeen({String? currentVersion}) async {
    try {
      final version =
          currentVersion ?? (await PackageInfo.fromPlatform()).version;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, version.split('+').first);
    } catch (_) {}
  }

  /// Records the running version and shows the sheet when an edition is due.
  /// [currentVersion] overrides the platform version (tests).
  static Future<bool> maybeShow(
    BuildContext context, {
    required bool isExistingUser,
    String? currentVersion,
  }) async {
    if (!TourEnvironment.enabled) return false;
    final version =
        currentVersion ?? (await PackageInfo.fromPlatform()).version;
    final prefs = await SharedPreferences.getInstance();
    final edition = editionToShow(
      currentVersion: version,
      lastSeen: prefs.getString(prefKey),
      isExistingUser: isExistingUser,
      editions: whatsNewEditions.keys,
    );
    await prefs.setString(prefKey, version.split('+').first);
    if (edition == null || !context.mounted) return false;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WhatsNewSheet(bullets: whatsNewEditions[edition]!),
    );
    return true;
  }
}

/// The small dismissible "What's new" card.
class WhatsNewSheet extends StatelessWidget {
  const WhatsNewSheet({required this.bullets, super.key});

  final List<WhatsNewBullet> bullets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.richGold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.whatsNewTitle,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final b in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(b.icon, color: AppColors.richGold, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        b.text(l10n),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('whats-new-got-it'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.whatsNewGotIt,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
