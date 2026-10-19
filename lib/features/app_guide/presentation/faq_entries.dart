import '../../../core/constants/launch_promo.dart';
import '../../../generated/app_localizations.dart';
import '../../coins/domain/entities/coin_transaction.dart';
import '../../ticket_payments/domain/ticket_rules.dart';

/// One question of the App Guide FAQ.
class FaqEntry {
  const FaqEntry({
    required this.id,
    required this.question,
    required this.answer,
  });

  /// Stable id (keys, tests).
  final String id;
  final String question;
  final String answer;
}

/// The App Guide FAQ, localized. Answers mirror the app's real behaviour and
/// the Terms (assets/legal/terms-and-conditions-*.txt); numbers come from the
/// same constants the app and the server use where they exist.
List<FaqEntry> buildFaqEntries(AppLocalizations l) => [
      FaqEntry(
          id: 'translation',
          question: l.xplFaqTranslationQ,
          answer: l.xplFaqTranslationA),
      FaqEntry(
          id: 'tickets', question: l.xplFaqTicketsQ, answer: l.xplFaqTicketsA),
      FaqEntry(
          id: 'cancel_subscription',
          question: l.xplFaqCancelSubQ,
          answer: l.xplFaqCancelSubA),
      FaqEntry(
          id: 'location',
          question: l.xplFaqLocationQ,
          answer: l.xplFaqLocationA),
      FaqEntry(
          id: 'followers',
          question: l.xplFaqFollowersQ,
          answer: l.xplFaqFollowersA),
      FaqEntry(
          id: 'moderation',
          question: l.xplFaqModerationQ,
          answer: l.xplFaqModerationA),
      FaqEntry(
          id: 'report_block',
          question: l.xplFaqReportQ,
          answer: l.xplFaqReportA),
      FaqEntry(
          id: 'delete_account',
          question: l.xplFaqDeleteQ,
          answer: l.xplFaqDeleteA),
      FaqEntry(id: 'phone', question: l.xplFaqPhoneQ, answer: l.xplFaqPhoneA),
      FaqEntry(
          id: 'id_verification', question: l.xplFaqIdQ, answer: l.xplFaqIdA),
      FaqEntry(id: 'coins', question: l.xplFaqCoinsQ, answer: l.xplFaqCoinsA),
      FaqEntry(
        id: 'launch_offer',
        question: l.xplFaqPromoQ,
        answer:
            l.xplFaqPromoA(LaunchPromo.percentOff, LaunchPromo.monthlyPeriods),
      ),
      FaqEntry(
          id: 'business',
          question: l.xplFaqBusinessQ,
          answer: l.xplFaqBusinessA),
      FaqEntry(
          id: 'seller_fees', question: l.xplFaqFeesQ, answer: l.xplFaqFeesA),
      FaqEntry(
        id: 'price_phases',
        question: l.xplFaqPhasesQ,
        answer: l.xplFaqPhasesA(kMaxTicketsPerBuyer),
      ),
      FaqEntry(
          id: 'attendee_names',
          question: l.xplFaqNamesQ,
          answer: l.xplFaqNamesA),
      FaqEntry(
          id: 'guest_booking',
          question: l.xplFaqGuestQ,
          answer: l.xplFaqGuestA),
      FaqEntry(
          id: 'data_export',
          question: l.xplFaqExportQ,
          answer: l.xplFaqExportA),
      FaqEntry(
          id: 'support', question: l.xplFaqSupportQ, answer: l.xplFaqSupportA),
      FaqEntry(
        id: 'ghost_mode',
        question: l.xplFaqGhostQ,
        answer: l.xplFaqGhostA(CoinFeaturePrices.incognito),
      ),
    ];

/// The entries whose question or answer contains every word of [query]
/// (case-insensitive). An empty query returns [entries] unchanged.
List<FaqEntry> filterFaq(List<FaqEntry> entries, String query) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return entries;
  return entries.where((e) {
    final text = '${e.question}\n${e.answer}'.toLowerCase();
    return words.every(text.contains);
  }).toList();
}
