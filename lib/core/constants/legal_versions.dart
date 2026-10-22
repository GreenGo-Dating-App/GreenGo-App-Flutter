/// Versions of the legal documents bundled in `assets/legal/*.txt` (copied
/// byte-for-byte from the published greengo-terms-and-conditions and
/// greengo-privacy-policy repos). Update these together with the texts.
///
/// They are stored with every acceptance record (`consents/{uid}.terms` /
/// `.privacy`, field `docVersion`, written server-side by `recordConsent`).
library;

/// Terms and Conditions version shown in-app and recorded at acceptance.
const String kTermsVersion = '5.3.4';

/// Privacy Policy version shown in-app and recorded at acceptance.
const String kPrivacyPolicyVersion = '5.3.2';

/// Effective date of [kPrivacyPolicyVersion] (and of the Terms up to 5.1.0).
/// 5.2.0: in-app checkout only, seller-paid service fee 11.5, business
/// billing data 11.6, guest booking 11.7 - [kPrivacyReacceptFrom]
/// deliberately NOT raised here; whether 5.2.0 triggers re-acceptance is the
/// owner's call.
/// 5.2.1 (16 Oct 2026): Globe discoverability Exact = ~100 m point + distances
/// to the nearest 100 m; an opt-in clarification, no re-acceptance.
/// 5.3.0 (16 Oct 2026 for accounts created from that day - owner decision of
/// 16 Oct 2026; accounts created before stay on 5.2.1 until 15 Nov 2026):
/// trader details 11.8, promotional-use setting 6.4, moderation emails,
/// app alignment. Sign-up records 5.3.0; existing users are NOT asked again.
/// 5.3.1 (17 Oct 2026 for accounts created from 16 Oct 2026; older accounts
/// still move from 5.2.1 on 16 Nov 2026): clarifications to match the app
/// (AI features, Google translation services, stored chat translations, ID
/// document for experiences, unfounded reports, Pix). No re-acceptance.
/// 5.3.2 (22 Oct 2026, same pattern): automatic translation of public content
/// only after AI-services consent (9.2); scheduled deletion of sellers with
/// unrefunded sales (15.1). No re-acceptance.
final DateTime kLegalEffectiveDate = DateTime(2026, 10, 22);

/// Effective date of [kTermsVersion] (5.1.1: section 9.2 - fixed price
/// points per currency; 5.1.2: the 9.2 example uses the current Base price.
/// Both are clarifications; no re-acceptance. 5.2.0: in-app checkout only,
/// seller-paid service fee 11.6, active-listing limits 11.7, guest booking
/// 11.8, Business from Silver 13.7 - [kTermsReacceptFrom] deliberately NOT
/// raised here; whether 5.2.0 triggers re-acceptance is the owner's call.
/// 5.2.1: 7.3 c - cancel a web subscription in Profile > Account Settings >
/// Manage subscription; a clarification, no re-acceptance).
/// 5.3.0: effective 16 Oct 2026 for accounts created on or after that day
/// (owner decision of 16 Oct 2026; sign-up records 5.3.0). Accounts created
/// before stay on 5.2.1 until 15 Nov 2026 and get the advance notice
/// ([kUpcomingTermsVersion]); [kTermsReacceptFrom] is NOT raised, so nobody
/// is asked to re-accept now.
/// 5.3.1 (16 Oct 2026, same day and same effective dates as 5.3.0): GreenGo
/// service fee caps per ticket raised in 11.6 b (Silver US$30, Gold US$28,
/// Platinum US$25; were 10 / 9 / 8). Sign-up records 5.3.1; older accounts
/// still move from 5.2.1 on 16 Nov 2026 and are notified of 5.3.1.
/// [kTermsReacceptFrom] is NOT raised.
/// 5.3.2 (17 Oct 2026 for accounts created from 16 Oct 2026; older accounts
/// still move from 5.2.1 on 16 Nov 2026): clarifications to match the app
/// (AI helpers, no store trials + 2026 launch offer, pre-sale plans, Pix,
/// legacy link orders, ticket price phases 11.2 f / 11.6 b, repeat-offender
/// periods 18.6). Sign-up records 5.3.2; [kTermsReacceptFrom] is NOT raised.
/// 5.3.3 (21 Oct 2026 for accounts created from 16 Oct 2026; older accounts
/// still move from 5.2.1 on 16 Nov 2026): automatic full refunds when a
/// seller cancels a paid Event or an Experience booking (11.2 g, 12.2,
/// 12.5 c), no account deletion while paid sales are not refunded (20.1).
/// Sign-up records 5.3.3; [kTermsReacceptFrom] is NOT raised.
/// 5.3.4 (22 Oct 2026, same pattern): 20.1 scheduled deletion instead of the
/// 5.3.3 refusal (Apple 5.1.1(v)). Sign-up records 5.3.4;
/// [kTermsReacceptFrom] is NOT raised.
final DateTime kTermsEffectiveDate = DateTime(2026, 10, 22);

/// Oldest accepted version that does NOT trigger the "we've updated our
/// Terms" sheet. Raise it only for a MATERIAL change (5.1.0: new Terms 16.9
/// and the private-content warning); a typo-fix release keeps it.
const String kTermsReacceptFrom = '5.1.0';

/// Same as [kTermsReacceptFrom], for the Privacy Policy.
const String kPrivacyReacceptFrom = '5.1.0';

/// Advance notice of the NEXT Terms version for EXISTING accounts (Terms
/// 24.2 a: at least 30 days before an important change takes effect, in the
/// app and by email). Until [kUpcomingTermsEffectiveDate] the app shows a
/// dismissible notice (once per version) linking to [kUpcomingTermsUrl], the
/// public text hosted on the website, to accounts created before
/// [kUpcomingTermsAccountsCreatedBefore]. The email goes out through the
/// admin callable `adminSendTermsChangeNotice` (functions
/// legal/termsNoticeCopy.ts carries the same version, dates and URL).
///
/// 5.3.0 (owner decision of 16 Oct 2026): already the bundled [kTermsVersion]
/// and in force for accounts created from 16 Oct 2026, which never see the
/// notice; accounts created before move from 5.2.1 to 5.3.0 on 16 Nov 2026.
/// 5.3.1 (same day): replaces 5.3.0 in the notice (fee caps raised in 11.6 b);
/// accounts created before 16 Oct 2026 move from 5.2.1 straight to 5.3.1 on
/// 16 Nov 2026. A user who dismissed the 5.3.0 notice sees the 5.3.1 one.
/// 5.3.2 (17 Oct 2026): replaces 5.3.1 in the notice (clarifications + ticket
/// price phases); older accounts move from 5.2.1 to 5.3.2 on 16 Nov 2026.
/// 5.3.3 (21 Oct 2026): replaces 5.3.2 in the notice (automatic refunds when
/// a seller cancels, deletion rule 20.1); older accounts move from 5.2.1 to
/// 5.3.3 on 16 Nov 2026. A user who dismissed the 5.3.2 notice sees 5.3.3.
///
/// When the version takes effect for everyone: raise [kTermsReacceptFrom] if
/// the change is material (the "we've updated our Terms" sheet then asks
/// everyone again and shows that version's bullets,
/// [legalUpdateBulletsVersion]), and clear or replace these constants. Set
/// [kUpcomingTermsVersion] to null when nothing is announced.
// 5.3.4 (22 Oct 2026) replaces 5.3.3 in the notice (scheduled deletion,
// translation consent); older accounts move from 5.2.1 to 5.3.4 on 16 Nov.
const String? kUpcomingTermsVersion = '5.3.4';

/// Date from which [kUpcomingTermsVersion] applies to accounts created before
/// [kUpcomingTermsAccountsCreatedBefore] (16 October 2026 + 30 days).
final DateTime kUpcomingTermsEffectiveDate = DateTime(2026, 11, 16);

/// Accounts created at or after this instant (16 Oct 2026, 00:00 UTC) accepted
/// [kUpcomingTermsVersion] at sign-up; only older accounts get the notice.
final DateTime kUpcomingTermsAccountsCreatedBefore = DateTime.utc(2026, 10, 16);

/// Public page with the text of [kUpcomingTermsVersion] (the website now
/// redirects it to the current Terms page, which is that version).
const String kUpcomingTermsUrl =
    'https://greengochat.com/terms-of-service/upcoming';

/// True while the notice of [kUpcomingTermsVersion] must be shown to an
/// account created at [accountCreatedAt]: a version is announced, its
/// effective date has not come yet, and the account is older than
/// [kUpcomingTermsAccountsCreatedBefore]. An unknown creation time never
/// shows it (new accounts must never see it).
bool upcomingTermsNoticeActive(DateTime now, {DateTime? accountCreatedAt}) {
  final v = kUpcomingTermsVersion;
  if (v == null) return false;
  if (!now.isBefore(kUpcomingTermsEffectiveDate)) return false;
  if (accountCreatedAt == null) return false;
  return accountCreatedAt.isBefore(kUpcomingTermsAccountsCreatedBefore);
}

/// The material version whose "what's new" bullets the re-acceptance sheet
/// shows: the higher of [kTermsReacceptFrom] and [kPrivacyReacceptFrom].
String get legalUpdateBulletsVersion =>
    isLegalVersionAtLeast(kTermsReacceptFrom, kPrivacyReacceptFrom)
        ? kTermsReacceptFrom
        : kPrivacyReacceptFrom;

/// Support e-mail for refunds of a prepaid Membership when a user ends the
/// contract over a Terms change (Terms 24.2 c).
const String kBillingSupportEmail = 'billing@greengochat.com';

final RegExp _semver = RegExp(r'^\d{1,3}(\.\d{1,3}){0,2}$');

/// True when [accepted] is a dotted version (e.g. "5.1.0") at least [min].
/// Anything else - null, empty, the old date labels such as "2026-09-15", or
/// "1.0" - counts as older, so the user is asked to accept the current texts.
bool isLegalVersionAtLeast(String? accepted, String min) {
  final a = accepted?.trim() ?? '';
  if (!_semver.hasMatch(a)) return false;
  List<int> parts(String v) {
    final p = v.split('.').map(int.parse).toList();
    while (p.length < 3) {
      p.add(0);
    }
    return p;
  }

  final x = parts(a);
  final y = parts(min);
  for (var i = 0; i < 3; i++) {
    if (x[i] != y[i]) return x[i] > y[i];
  }
  return true;
}
