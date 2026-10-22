// Terms 24.2: advance notice of an upcoming version (a), re-acceptance sheet
// with the TERMS effective date and per-version bullets (b, d), and the
// "I don't accept - close my account" option (c).
// Owner decision of 16 Oct 2026: 5.3.0 is the bundled version (new accounts
// accept it at sign-up); only accounts created before 16 Oct 2026 get the
// notice that it applies to them from 16 Nov 2026. 5.3.1 (same day, fee caps
// raised in 11.6 b) replaced 5.3.0 with the same dates.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/legal_versions.dart';
import 'package:greengo_chat/core/services/consent_recorder.dart';
import 'package:greengo_chat/features/legal/presentation/widgets/legal_update_sheet.dart';
import 'package:greengo_chat/features/legal/presentation/widgets/upcoming_terms_notice.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetLegalUpdateSheetSession();
    UpcomingTermsNotice.resetSession();
  });

  final oldAccount = DateTime.utc(2026, 9, 1);
  final newAccount = DateTime.utc(2026, 10, 16, 8);

  group('upcoming version constants', () {
    test('5.3.4: bundled for new accounts, announced 30 days ahead for existing ones', () {
      expect(kTermsVersion, '5.3.4');
      expect(kPrivacyPolicyVersion, '5.3.2');
      expect(kTermsEffectiveDate, DateTime(2026, 10, 22));
      expect(kLegalEffectiveDate, DateTime(2026, 10, 22));
      expect(kUpcomingTermsVersion, '5.3.4');
      expect(kUpcomingTermsEffectiveDate, DateTime(2026, 11, 16));
      expect(kUpcomingTermsAccountsCreatedBefore, DateTime.utc(2026, 10, 16));
      expect(kUpcomingTermsUrl, 'https://greengochat.com/terms-of-service/upcoming');
      expect(
          kUpcomingTermsEffectiveDate.difference(DateTime(2026, 10, 16)).inDays, greaterThanOrEqualTo(30));
    });

    test('notice active for accounts created before 16 Oct 2026, until the effective date', () {
      bool on(DateTime now, DateTime? created) =>
          upcomingTermsNoticeActive(now, accountCreatedAt: created);
      expect(on(DateTime(2026, 10, 16), oldAccount), isTrue);
      expect(on(DateTime(2026, 11, 15, 23, 59), oldAccount), isTrue);
      expect(on(DateTime(2026, 11, 16), oldAccount), isFalse);
      expect(on(DateTime(2027), oldAccount), isFalse);
      expect(on(DateTime(2026, 10, 16), DateTime.utc(2026, 10, 15, 23, 59)), isTrue);
      // New accounts (they accepted 5.3.x at sign-up) and unknown ones: never.
      expect(on(DateTime(2026, 10, 20), DateTime.utc(2026, 10, 16)), isFalse);
      expect(on(DateTime(2026, 10, 20), newAccount), isFalse);
      expect(on(DateTime(2026, 10, 20), null), isFalse);
    });

    test('thresholds unchanged (owner decides); bullets follow the threshold', () {
      expect(kTermsReacceptFrom, '5.1.0');
      expect(kPrivacyReacceptFrom, '5.1.0');
      expect(legalUpdateBulletsVersion, '5.1.0');
    });
  });

  testWidgets('per-version bullets: 5.1.0 (3), 5.3.0 (5), 5.3.1 (6), 5.3.2 (7), 5.3.3 (8), 5.3.4 (10), unknown none', (tester) async {
    await tester.pumpWidget(_app(const SizedBox()));
    final l10n = AppLocalizations.of(tester.element(find.byType(SizedBox)))!;
    expect(legalUpdateBullets(l10n, '5.1.0'), [
      l10n.legalUpdateBulletPrivateContent,
      l10n.legalUpdateBulletWarning,
      l10n.legalUpdateBulletOrientation,
    ]);
    final b530 = legalUpdateBullets(l10n, '5.3.0');
    expect(b530, hasLength(5));
    expect(b530.first, contains('1 week of Base'));
    expect(b530[1], contains('10 and 1,000 Coins'));
    final b531 = legalUpdateBullets(l10n, '5.3.1');
    expect(b531, hasLength(6));
    expect(b531.take(5), b530);
    expect(b531.last, l10n.legalUpdate531BulletFeeCaps);
    expect(b531.last, contains('US\$30'));
    expect(b531.last, contains('US\$28'));
    expect(b531.last, contains('US\$25'));
    final b532 = legalUpdateBullets(l10n, '5.3.2');
    expect(b532, hasLength(7));
    expect(b532.take(6), b531);
    expect(b532.last, l10n.legalUpdate532BulletPhases);
    expect(b532.last, contains('50%'));
    final b533 = legalUpdateBullets(l10n, '5.3.3');
    expect(b533, hasLength(8));
    expect(b533.take(7), b532);
    expect(b533.last, l10n.legalUpdate533BulletRefunds);
    expect(b533.last, contains('refund'));
    final b534 = legalUpdateBullets(l10n, '5.3.4');
    expect(b534, hasLength(10));
    expect(b534.take(8), b533);
    expect(b534[8], l10n.legalUpdate534BulletDeletion);
    expect(b534.last, l10n.legalUpdate534BulletTranslation);
    expect(legalUpdateBullets(l10n, '9.9.9'), isEmpty);
    expect(legalUpdateBullets(l10n, null), isEmpty);
  });

  testWidgets('re-acceptance sheet shows the TERMS effective date', (tester) async {
    final r = ConsentRecorder(callable: (p) async {}, currentUid: () => 'u1');
    await tester.pumpWidget(_app(LegalUpdateSheetBody(recorder: r)));
    final l10n = AppLocalizations.of(tester.element(find.byType(LegalUpdateSheetBody)))!;
    final date = DateFormat.yMMMMd('en').format(kTermsEffectiveDate);
    expect(find.text(l10n.legalUpdateIntro(kTermsVersion, date)), findsOneWidget);
    expect(find.byKey(const Key('legalUpdateCloseAccount')), findsOneWidget);
  });

  testWidgets('"I don\'t accept - close my account": explanation, then onCloseAccount', (tester) async {
    final r = ConsentRecorder(callable: (p) async {}, currentUid: () => 'u1');
    var signedOut = false;
    var closing = false;
    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
        onPressed: () => showLegalUpdateSheetIfNeeded(
          context,
          onSignOut: () => signedOut = true,
          onCloseAccount: () => closing = true,
          recorder: r,
          gate: LegalUpdateGate(recorder: r, currentUid: () => 'u1', readConsents: (_) async => null),
        ),
        child: const Text('go'),
      ),
    )));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('legalUpdateCloseAccount')));
    await tester.tap(find.byKey(const Key('legalUpdateCloseAccount')));
    await tester.pumpAndSettle();
    final body = tester.widget<Text>(find.byKey(const Key('legalUpdateCloseAccountBody'))).data!;
    expect(body, contains('billing@greengochat.com'));
    expect(body, contains('free of charge'));

    // Cancel keeps the sheet.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalUpdateSheetBody), findsOneWidget);

    await tester.tap(find.byKey(const Key('legalUpdateCloseAccount')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('legalUpdateCloseAccountContinue')));
    await tester.pumpAndSettle();
    expect(find.byType(LegalUpdateSheetBody), findsNothing);
    expect(closing, isTrue);
    expect(signedOut, isFalse);
  });

  group('upcoming Terms notice', () {
    final recorder = ConsentRecorder(callable: (p) async {}, currentUid: () => 'u1');

    Future<void> open(WidgetTester tester, {Future<bool> Function(Uri)? openUrl}) async {
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () => UpcomingTermsNotice.showIfNeeded(context,
              now: DateTime(2026, 10, 20),
              accountCreatedAt: oldAccount,
              recorder: recorder,
              openUrl: openUrl),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows date, what changes and the rights; Got it dismisses this version', (tester) async {
      await open(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(UpcomingTermsNoticeBody)))!;
      final date = DateFormat.yMMMMd('en').format(kUpcomingTermsEffectiveDate);
      expect(find.text(l10n.legalUpcomingTitle(date)), findsOneWidget);
      expect(find.text(l10n.legalUpdate530BulletTraders), findsOneWidget);
      expect(find.text(l10n.legalUpdate531BulletFeeCaps), findsOneWidget);
      expect(find.text(l10n.legalUpdate532BulletPhases), findsOneWidget);
      expect(find.text(l10n.legalUpdate533BulletRefunds), findsOneWidget);
      expect(find.text(l10n.legalUpdate534BulletDeletion), findsOneWidget);
      expect(find.text(l10n.legalUpdate534BulletTranslation), findsOneWidget);
      expect(find.textContaining('billing@greengochat.com'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('legalUpcomingGotIt')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('legalUpcomingGotIt')));
      await tester.pumpAndSettle();
      expect(find.byType(UpcomingTermsNoticeBody), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(UpcomingTermsNotice.dismissKey('5.3.4')), isTrue);
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 10, 21), accountCreatedAt: oldAccount, recorder: recorder),
          isFalse);
    });

    testWidgets('Read opens the public text', (tester) async {
      Uri? opened;
      await open(tester, openUrl: (u) async {
        opened = u;
        return true;
      });
      await tester.ensureVisible(find.byKey(const Key('legalUpcomingRead')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('legalUpcomingRead')));
      await tester.pumpAndSettle();
      expect(opened.toString(), kUpcomingTermsUrl);
      expect(find.byType(UpcomingTermsNoticeBody), findsNothing);
    });

    test('not shown after the effective date', () async {
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 10, 20), accountCreatedAt: oldAccount, recorder: recorder),
          isTrue);
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 11, 16), accountCreatedAt: oldAccount, recorder: recorder),
          isFalse);
    });

    test('never shown to accounts created from 16 Oct 2026', () async {
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 10, 20), accountCreatedAt: newAccount, recorder: recorder),
          isFalse);
    });

    test('not shown once this device accepted 5.3.4; still shown with 5.2.1, 5.3.0 to 5.3.3', () async {
      await recorder.rememberDocVersion(ConsentTypes.terms, '5.2.1');
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 10, 20), accountCreatedAt: oldAccount, recorder: recorder),
          isTrue);
      await recorder.rememberDocVersion(ConsentTypes.terms, '5.3.0');
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 10, 20), accountCreatedAt: oldAccount, recorder: recorder),
          isTrue);
      await recorder.rememberDocVersion(ConsentTypes.terms, '5.3.1');
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 10, 20), accountCreatedAt: oldAccount, recorder: recorder),
          isTrue);
      await recorder.rememberDocVersion(ConsentTypes.terms, '5.3.2');
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 10, 20), accountCreatedAt: oldAccount, recorder: recorder),
          isTrue);
      await recorder.rememberDocVersion(ConsentTypes.terms, '5.3.3');
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 10, 20), accountCreatedAt: oldAccount, recorder: recorder),
          isTrue);
      await recorder.rememberDocVersion(ConsentTypes.terms, '5.3.4');
      expect(
          await UpcomingTermsNotice.shouldShow(
              now: DateTime(2026, 10, 20), accountCreatedAt: oldAccount, recorder: recorder),
          isFalse);
    });

    testWidgets('a new account never gets the sheet', (tester) async {
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () => UpcomingTermsNotice.showIfNeeded(context,
              now: DateTime(2026, 10, 20), accountCreatedAt: newAccount, recorder: recorder),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.byType(UpcomingTermsNoticeBody), findsNothing);
    });
  });
}
