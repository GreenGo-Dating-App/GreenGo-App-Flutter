// Owner rule (2026-10-12): "Silver, Gold and Platinum have payment links in
// Account settings. That is visible only when the tier is Silver, Gold or
// Platinum." Client side of the gate (the server side is covered by
// functions/__tests__/security/payment-links-tier.emulator.test.ts).
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/services/tier_entitlements.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/profile/domain/entities/payment_links.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/features/profile/domain/payment_links_access.dart';
import 'package:greengo_chat/features/profile/domain/repositories/profile_repository.dart';
import 'package:greengo_chat/features/profile/presentation/widgets/payment_links_locked_card.dart';
import 'package:greengo_chat/features/profile/presentation/widgets/payment_links_settings_entry.dart';
import 'package:greengo_chat/features/ticket_payments/data/ticket_payments_service.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_payments.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/screens/get_paid_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/profile_fixtures.dart';

class _MockProfiles extends Mock implements ProfileRepository {}

class _MockService extends Mock implements TicketPaymentsService {}

final _future = DateTime.now().add(const Duration(days: 30));
final _past = DateTime.now().subtract(const Duration(days: 1));
const _links = PaymentLinks({
  PaymentMethod.pix: 'me@pix.example',
  PaymentMethod.paypal: 'myname',
});

Profile _p(MembershipTier tier,
        {DateTime? end, bool base = false, PaymentLinks? links = _links}) =>
    buildProfile(
      userId: 'u1',
      membershipTier: tier,
      membershipEndDate: end,
      hasBaseMembership: base,
      baseMembershipEndDate: base ? _future : null,
    ).copyWith(paymentLinks: links);

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  group('who may hold / show payment links', () {
    test('Silver, Gold, Platinum and TEST only', () {
      expect(paymentLinksAllowedForTier(MembershipTier.free), isFalse);
      expect(paymentLinksAllowedForTier(MembershipTier.silver), isTrue);
      expect(paymentLinksAllowedForTier(MembershipTier.gold), isTrue);
      expect(paymentLinksAllowedForTier(MembershipTier.platinum), isTrue);
      expect(paymentLinksAllowedForTier(MembershipTier.test), isTrue);
    });

    test('EFFECTIVE tier: an expired Gold or a Base-only user is not allowed', () {
      expect(paymentLinksAllowed(_p(MembershipTier.gold, end: _future)), isTrue);
      expect(paymentLinksAllowed(_p(MembershipTier.gold, end: _past)), isFalse);
      expect(paymentLinksAllowed(_p(MembershipTier.free, base: true)), isFalse);
      expect(paymentLinksAllowed(_p(MembershipTier.test)), isTrue);
      expect(
          paymentLinksAllowedFromDoc({
            'membershipTier': 'PLATINUM',
            'membershipEndDate': _future.toIso8601String(),
          }),
          isTrue);
      expect(
          paymentLinksAllowedFromDoc({
            'membershipTier': 'SILVER',
            'membershipEndDate': _past.toIso8601String(),
          }),
          isFalse);
      expect(paymentLinksAllowedFromDoc(null), isFalse);
    });

    test('profile display: links only while the owner tier is paid', () {
      expect(visiblePaymentLinks(_p(MembershipTier.silver, end: _future)), _links);
      expect(visiblePaymentLinks(_p(MembershipTier.platinum, end: _past)), isNull);
      expect(visiblePaymentLinks(_p(MembershipTier.free)), isNull);
      expect(
          visiblePaymentLinks(
              _p(MembershipTier.gold, end: _future, links: const PaymentLinks())),
          isNull);
    });

    test('comparison table promises payment links for Silver, Gold, Platinum', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final rows = TierEntitlements.comparisonRows(l10n, travelCoinsPerDay: 100);
      final row = rows.firstWhere((r) => r.label == l10n.tierPaymentLinksRow);
      expect(row.values, [
        TierEntitlements.noMark,
        TierEntitlements.yesMark,
        TierEntitlements.yesMark,
        TierEntitlements.yesMark,
      ]);
    });
  });

  group('profile save never re-writes links it may not write', () {
    const stored = {'pix': 'me@pix.example', 'paypal': 'myname', 'wise': null};
    test('unchanged (null keys ignored) -> not sent', () {
      expect(
          shouldWritePaymentLinks(
              stored: stored,
              next: {'pix': 'me@pix.example', 'paypal': 'myname', 'kofi': null},
              allowed: true),
          isFalse);
    });
    test('eligible owner: any change is sent', () {
      expect(
          shouldWritePaymentLinks(
              stored: stored, next: {'pix': 'new@pix.example'}, allowed: true),
          isTrue);
      expect(shouldWritePaymentLinks(stored: null, next: {'pix': 'a@b.co'}, allowed: true),
          isTrue);
    });
    test('lapsed owner: removals are sent, additions / stale copies are not', () {
      expect(
          shouldWritePaymentLinks(stored: stored, next: {'pix': 'me@pix.example'}, allowed: false),
          isTrue);
      expect(shouldWritePaymentLinks(stored: stored, next: null, allowed: false), isTrue);
      expect(
          shouldWritePaymentLinks(
              stored: stored, next: {...stored, 'wise': 'x'}, allowed: false),
          isFalse);
      // The server already hid them (public field gone); the app still has
      // the old copy in memory.
      expect(shouldWritePaymentLinks(stored: null, next: stored, allowed: false), isFalse);
    });
  });

  test('hidden copy parser (profiles_private.paymentLinksHidden)', () {
    expect(
        hiddenPaymentLinksFromPrivate({
          'paymentLinksHidden': {'pix': 'me@pix.example', 'paypal': 'myname', 'gone': 'x', 'wise': ''},
        }),
        _links);
    expect(hiddenPaymentLinksFromPrivate({'paymentLinksHidden': {}}), isNull);
    expect(hiddenPaymentLinksFromPrivate(null), isNull);
  });

  group('Account settings entry', () {
    Future<void> pump(WidgetTester t, Profile p, {PaymentLinks? hidden}) =>
        t.pumpWidget(_app(Scaffold(
          body: PaymentLinksSettingsEntry(
            profile: p,
            onOpen: () {},
            hiddenLinks: () => hidden,
          ),
        )));

    testWidgets('Silver / Gold / Platinum: visible with the normal subtitle', (t) async {
      final l = lookupAppLocalizations(const Locale('en'));
      for (final tier in [MembershipTier.silver, MembershipTier.gold, MembershipTier.platinum]) {
        await pump(t, _p(tier, end: _future));
        expect(find.byKey(const ValueKey('account-settings-payment-methods')), findsOneWidget);
        expect(find.text(l.paymentMethodsSettingsSubtitle), findsOneWidget);
      }
    });

    testWidgets('active Platinum business: still in Account settings', (t) async {
      await t.pumpWidget(_app(Scaffold(
        body: PaymentLinksSettingsEntry(
          profile: buildProfile(
              userId: 'u1',
              isBusiness: true,
              membershipTier: MembershipTier.platinum,
              membershipEndDate: _future),
          onOpen: () {},
          hiddenLinks: () => null,
        ),
      )));
      expect(find.byKey(const ValueKey('account-settings-payment-methods')), findsOneWidget);
    });

    testWidgets('FREE / Base without saved links: not visible', (t) async {
      await pump(t, _p(MembershipTier.free, links: null));
      expect(find.byKey(const ValueKey('account-settings-payment-methods')), findsNothing);
      await pump(t, _p(MembershipTier.free, base: true, links: null));
      expect(find.byKey(const ValueKey('account-settings-payment-methods')), findsNothing);
    });

    testWidgets('lapsed tier with hidden links: entry says "Available with ..."', (t) async {
      final l = lookupAppLocalizations(const Locale('en'));
      await pump(t, _p(MembershipTier.gold, end: _past, links: null), hidden: _links);
      expect(find.byKey(const ValueKey('account-settings-payment-methods')), findsOneWidget);
      expect(find.text(l.paymentLinksTierLocked), findsOneWidget);
    });
  });

  group('editor gating (Get paid / Payment methods page)', () {
    late _MockProfiles profiles;
    late _MockService service;

    setUp(() {
      profiles = _MockProfiles();
      service = _MockService();
      when(() => service.config()).thenAnswer((_) async => const TicketPaymentsConfig());
      when(() => service.refreshAccounts()).thenAnswer((_) async {});
      when(() => service.watchAccounts(any()))
          .thenAnswer((_) => Stream.value(const PaymentAccounts()));
    });

    Future<void> pump(WidgetTester t, Profile p,
        {PaymentLinks? hidden, VoidCallback? onUpgrade, bool methodsOnly = true}) async {
      when(() => profiles.getProfile(any()))
          .thenAnswer((_) async => Right<Failure, Profile>(p));
      await t.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(_app(GetPaidScreen(
        uid: 'u1',
        service: service,
        profileRepository: profiles,
        paymentMethodsOnly: methodsOnly,
        hiddenLinksLoader: (_) async => hidden,
        onUpgrade: onUpgrade,
      )));
      await t.pump();
      await t.pump();
      await t.pump();
    }

    testWidgets('Gold: the editor', (t) async {
      await pump(t, _p(MembershipTier.gold, end: _future));
      expect(find.byKey(const ValueKey('get-paid-payment-methods')), findsOneWidget);
      expect(find.byKey(const ValueKey('payment-links-locked')), findsNothing);
    });

    testWidgets('FREE: no editor, upsell + upgrade CTA', (t) async {
      final l = lookupAppLocalizations(const Locale('en'));
      var upgrades = 0;
      await pump(t, _p(MembershipTier.free, links: null), onUpgrade: () => upgrades++);
      expect(find.byKey(const ValueKey('get-paid-payment-methods')), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(l.paymentLinksTierLocked), findsOneWidget);
      expect(find.text(l.paymentLinksTierUpsellBody), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('payment-links-upgrade')));
      expect(upgrades, 1);
    });

    testWidgets('expired: saved links greyed (read-only) + "Available with ..."', (t) async {
      final l = lookupAppLocalizations(const Locale('en'));
      await pump(t, _p(MembershipTier.platinum, end: _past, links: null), hidden: _links);
      expect(find.byKey(const ValueKey('get-paid-payment-methods')), findsNothing);
      expect(find.text(l.paymentLinksTierLocked), findsOneWidget);
      expect(find.text(l.paymentLinksTierLockedBody), findsOneWidget);
      final list = find.byKey(const ValueKey('payment-links-locked-list'));
      expect(t.widget<Opacity>(list).opacity, lessThan(1));
      expect(find.descendant(of: list, matching: find.text('Pix')), findsOneWidget);
      expect(find.descendant(of: list, matching: find.text('me@pix.example')), findsOneWidget);
      expect(find.text(l.upgrade), findsOneWidget);
    });

    testWidgets('lapsed business Get paid: providers stay, manual methods locked', (t) async {
      await pump(
          t,
          buildProfile(
              userId: 'u1',
              isBusiness: true,
              membershipTier: MembershipTier.platinum,
              membershipEndDate: _past),
          methodsOnly: false);
      expect(find.byKey(const ValueKey('get-paid-stripe')), findsOneWidget);
      expect(find.byKey(const ValueKey('payment-links-locked')), findsOneWidget);
      expect(find.byKey(const ValueKey('get-paid-payment-methods')), findsNothing);
    });
  });

  group('7 locales', () {
    for (final loc in const [
      Locale('en'),
      Locale('de'),
      Locale('es'),
      Locale('fr'),
      Locale('it'),
      Locale('pt'),
      Locale('pt', 'BR'),
    ]) {
      testWidgets('locked card renders translated text ($loc)', (t) async {
        final l = lookupAppLocalizations(loc);
        for (final s in [
          l.paymentLinksTierLocked,
          l.paymentLinksTierLockedBody,
          l.paymentLinksTierUpsellBody,
          l.tierPaymentLinksRow,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
        if (loc.languageCode != 'en') {
          final en = lookupAppLocalizations(const Locale('en'));
          expect(l.paymentLinksTierLockedBody, isNot(en.paymentLinksTierLockedBody));
        }
        await t.pumpWidget(_app(
            const Scaffold(body: PaymentLinksLockedCard(uid: 'u1', hidden: _links)),
            locale: loc));
        await t.pump();
        expect(find.text(l.paymentLinksTierLocked), findsOneWidget);
        expect(find.text(l.paymentLinksTierLockedBody), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  });
}
