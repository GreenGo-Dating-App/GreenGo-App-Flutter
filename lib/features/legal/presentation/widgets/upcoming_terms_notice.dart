import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/legal_versions.dart';
import '../../../../generated/app_localizations.dart';
import 'legal_update_sheet.dart';

/// Terms 24.2 a: advance notice of an important Terms change, in the app.
/// From the announcement ([kUpcomingTermsVersion]) until
/// [kUpcomingTermsEffectiveDate] a sheet says when the Terms change, what
/// changes and links to the new text ([kUpcomingTermsUrl]). "Got it" or
/// "Read the new Terms" dismiss it for that version (per device); closing it
/// any other way shows it again at the next app start.
class UpcomingTermsNotice {
  UpcomingTermsNotice._();

  /// SharedPreferences flag: the notice of [version] was dismissed.
  static String dismissKey(String version) =>
      'legal_upcoming_terms_dismissed_$version';

  static bool _shownThisSession = false;

  /// Resets the once-per-session guard (tests).
  @visibleForTesting
  static void resetSession() => _shownThisSession = false;

  static Future<bool> shouldShow({DateTime? now}) async {
    const v = kUpcomingTermsVersion;
    if (v == null || !upcomingTermsNoticeActive(now ?? DateTime.now())) {
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(dismissKey(v)) != true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> dismiss() async {
    const v = kUpcomingTermsVersion;
    if (v == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(dismissKey(v), true);
    } catch (_) {
      // Best effort: shown again next start.
    }
  }

  /// Shows the notice once per app session while [shouldShow].
  static Future<void> showIfNeeded(
    BuildContext context, {
    DateTime? now,
    Future<bool> Function(Uri url)? openUrl,
  }) async {
    if (_shownThisSession) return;
    if (!await shouldShow(now: now)) return;
    if (!context.mounted || _shownThisSession) return;
    _shownThisSession = true;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UpcomingTermsNoticeBody(openUrl: openUrl),
    );
  }
}

class UpcomingTermsNoticeBody extends StatelessWidget {
  const UpcomingTermsNoticeBody({super.key, this.openUrl});

  /// Opens the public text (tests override it).
  final Future<bool> Function(Uri url)? openUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const version = kUpcomingTermsVersion ?? '';
    final locale = Localizations.localeOf(context).toString();
    String date;
    try {
      date = DateFormat.yMMMMd(locale).format(kUpcomingTermsEffectiveDate);
    } catch (_) {
      date = DateFormat.yMMMMd().format(kUpcomingTermsEffectiveDate);
    }
    final bullets = legalUpdateBullets(l10n, version);
    const bodyStyle =
        TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4);
    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note_outlined,
                        color: AppColors.richGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.legalUpcomingTitle(date),
                        key: const Key('legalUpcomingTitle'),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.legalUpcomingIntro(version, date), style: bodyStyle),
                const SizedBox(height: 4),
                for (final b in bullets)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7, right: 8),
                          child: Icon(Icons.circle,
                              size: 6, color: AppColors.richGold),
                        ),
                        Expanded(child: Text(b, style: bodyStyle)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  l10n.legalUpcomingRights(date, kBillingSupportEmail),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('legalUpcomingRead'),
                    onPressed: () async {
                      await UpcomingTermsNotice.dismiss();
                      final open = openUrl ??
                          (Uri u) =>
                              launchUrl(u, mode: LaunchMode.externalApplication);
                      await open(Uri.parse(kUpcomingTermsUrl));
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.legalUpcomingRead),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('legalUpcomingGotIt'),
                    onPressed: () async {
                      await UpcomingTermsNotice.dismiss();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text(l10n.legalUpcomingGotIt),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
