import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/paid_listing_access.dart';
import 'package:greengo_chat/features/business/presentation/widgets/paid_business_note.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/ticket_payments/data/ticket_payments_service.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_payments.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/screens/get_paid_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../support/profile_fixtures.dart';

class _MockService extends Mock implements TicketPaymentsService {}

final _future = DateTime.now().add(const Duration(days: 365));
final _past = DateTime.now().subtract(const Duration(days: 365));

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  group('PaidListingAccess (only active business accounts may sell)', () {
    test('active business = isBusiness + effective Platinum', () {
      expect(
          PaidListingAccess.of(buildProfile(
              isBusiness: true,
              membershipTier: MembershipTier.platinum,
              membershipEndDate: _future)),
          PaidListingAccess.allowed);
    });

    test('lapsed Platinum business is paused; personal accounts cannot sell', () {
      expect(
          PaidListingAccess.of(buildProfile(
              isBusiness: true,
              membershipTier: MembershipTier.platinum,
              membershipEndDate: _past)),
          PaidListingAccess.businessPaused);
      expect(
          PaidListingAccess.of(buildProfile(
              membershipTier: MembershipTier.platinum,
              membershipEndDate: _future)),
          PaidListingAccess.notBusiness);
      expect(PaidListingAccess.of(buildProfile()), PaidListingAccess.notBusiness);
      expect(PaidListingAccess.of(null), PaidListingAccess.notBusiness);
      expect(PaidListingAccess.notBusiness.canSell, isFalse);
      expect(PaidListingAccess.businessPaused.canSell, isFalse);
      expect(PaidListingAccess.allowed.canSell, isTrue);
    });

    test('raw document mirror', () {
      expect(
          PaidListingAccess.ofDoc({
            'isBusiness': true,
            'membershipTier': 'PLATINUM',
            'membershipEndDate': _future.toIso8601String(),
          }),
          PaidListingAccess.allowed);
      expect(PaidListingAccess.ofDoc({'membershipTier': 'TEST'}),
          PaidListingAccess.notBusiness);
      expect(PaidListingAccess.ofDoc({'isBusiness': true}),
          PaidListingAccess.businessPaused);
      expect(PaidListingAccess.ofDoc(null), PaidListingAccess.notBusiness);
    });
  });

  group('PaidBusinessNote', () {
    testWidgets('personal account: note + Become a business link', (t) async {
      final l = await _l10n();
      await t.pumpWidget(_app(const Scaffold(
          body: PaidBusinessNote(uid: 'u1', access: PaidListingAccess.notBusiness))));
      expect(find.text(l.paidBusinessOnlyNote), findsOneWidget);
      expect(find.text(l.becomeBusiness), findsOneWidget);
    });

    testWidgets('lapsed business: paused note + Renew Platinum', (t) async {
      final l = await _l10n();
      await t.pumpWidget(_app(const Scaffold(
          body: PaidBusinessNote(uid: 'u1', access: PaidListingAccess.businessPaused))));
      expect(find.text(l.paidBusinessPausedNote), findsOneWidget);
      expect(find.text(l.businessReactivate), findsOneWidget);
    });
  });

  group('GetPaidScreen layout', () {
    late _MockService service;

    setUp(() {
      service = _MockService();
      when(() => service.config()).thenAnswer((_) async => const TicketPaymentsConfig());
      when(() => service.refreshAccounts()).thenAnswer((_) async {});
      when(() => service.watchAccounts(any()))
          .thenAnswer((_) => Stream.value(const PaymentAccounts()));
    });

    Future<void> pump(WidgetTester t) async {
      await t.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(_app(GetPaidScreen(uid: 'u1', service: service)));
      await t.pump();
      await t.pump();
    }

    testWidgets(
        'automatic payments only (no payment links / manual section); fee schedule shown',
        (t) async {
      final l = await _l10n();
      await pump(t);
      expect(find.text(l.tpAutoSectionTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('get-paid-section-auto')), findsOneWidget);
      expect(find.byKey(const ValueKey('get-paid-mercadopago')), findsOneWidget);
      expect(find.byKey(const ValueKey('get-paid-stripe')), findsOneWidget);
      expect(find.byKey(const ValueKey('get-paid-section-manual')), findsNothing);
      expect(find.byKey(const ValueKey('get-paid-payment-methods')), findsNothing);
      // Host side of the GreenGo service fee: 100% of the price + schedule.
      expect(find.text(l.tpGetPaidIntro), findsOneWidget);
      expect(find.text(l.tpFeeHostNote), findsOneWidget);
      expect(find.textContaining(l.tpFeeRuleTrial), findsOneWidget);
      // No legacy link order waiting: no "Payments to confirm" action.
      expect(find.byKey(const ValueKey('get-paid-to-confirm')), findsNothing);
      expect(find.byTooltip(l.tpRefresh), findsOneWidget);
    });
  });
}
