import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/qr_checkin_service.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_fees.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_payments.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/widgets/buy_ticket_sheet.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/widgets/ticket_payment_selector.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

const _ready = PaymentAccounts(
  stripe: PayoutStatus.ready,
  mercadoPago: PayoutStatus.ready,
  mercadoPagoCurrency: 'brl',
  stripeCountry: 'BR',
);
const _config = TicketPaymentsConfig(stripe: true, mercadoPago: true);

void main() {
  test('pending pile-up hint (legacy payments to confirm)', () {
    expect(suggestInstantForPending(9), isFalse);
    expect(suggestInstantForPending(10), isTrue);
  });

  group('rules mirrored from the server', () {
    test('payment links are no longer accepted: a link choice is never complete', () {
      expect(needsReconnect(const TicketPaymentChoice(provider: TicketProvider.link, linkMethod: 'pix')), isTrue);
      expect(const TicketPaymentChoice(provider: TicketProvider.link, linkMethod: 'pix').isComplete, isFalse);
      expect(const TicketPaymentChoice(provider: TicketProvider.stripe).isComplete, isTrue);
      expect(needsReconnect(const TicketPaymentChoice(provider: TicketProvider.mercadoPago)), isFalse);
    });
    test('minor units incl. zero-decimal currencies', () {
      expect(toMinorUnits(19.99, 'usd'), 1999);
      expect(toMinorUnits(1500, 'jpy'), 1500);
      expect(toMinorUnits(9990, 'clp'), 9990);
      expect(formatTicketAmount(2550, 'brl', locale: 'pt_BR'), contains('25,50'));
    });
    test('provider blocks: MP currency mismatch, minimums, not connected', () {
      ProviderBlock? b(TicketProvider p, String c, double price, [PaymentAccounts a = _ready]) =>
          providerBlock(p: p, config: _config, accounts: a, currency: c, price: price);
      expect(b(TicketProvider.mercadoPago, 'usd', 10), ProviderBlock.currencyMismatch);
      expect(b(TicketProvider.mercadoPago, 'brl', 10), isNull);
      expect(b(TicketProvider.mercadoPago, 'brl', 0.5), ProviderBlock.belowMinimum);
      expect(b(TicketProvider.stripe, 'usd', 0.4), ProviderBlock.belowMinimum);
      expect(b(TicketProvider.stripe, 'usd', 0.5), isNull);
      expect(b(TicketProvider.stripe, 'usd', 5, const PaymentAccounts()), ProviderBlock.notConnected);
      expect(b(TicketProvider.link, 'xyz', 0.01), isNull);
    });
    test('remaining allowance = min(limit - held, capacity)', () {
      expect(remainingForBuyer(limit: 4, alreadyHeld: 1, remainingCapacity: null), 3);
      expect(remainingForBuyer(limit: 4, alreadyHeld: 0, remainingCapacity: 2), 2);
      expect(remainingForBuyer(limit: null, alreadyHeld: 9, remainingCapacity: 5), 5);
      expect(remainingForBuyer(limit: null, alreadyHeld: 0, remainingCapacity: null), isNull);
      expect(remainingForBuyer(limit: 2, alreadyHeld: 3, remainingCapacity: 10), 0);
    });
    test('scanner recognises paid ticket QR codes', () {
      final c = ScannedCheckInCode.parse('greengo:tk:order1_2:AbCdEfGhIjKlMnOpQrStUv');
      expect(c, isA<PaidTicketCode>());
      expect((c as PaidTicketCode).ticketId, 'order1_2');
      expect(ScannedCheckInCode.parse('greengo:tk:bad'), isNull);
    });
    test('ticket type state', () {
      final now = DateTime(2026, 10, 8, 12);
      expect(ticketTypeState(const TicketType(id: 'a', name: 'A', price: 1, quantity: 2, sold: 2), now), TicketTypeState.soldOut);
      expect(ticketTypeState(TicketType(id: 'a', name: 'A', price: 1, salesStart: now.add(const Duration(days: 1))), now), TicketTypeState.notStarted);
      expect(ticketTypeState(TicketType(id: 'a', name: 'A', price: 1, salesEnd: now.subtract(const Duration(days: 1))), now), TicketTypeState.ended);
      expect(ticketTypeState(const TicketType(id: 'a', name: 'A', price: 1, hidden: true), now), TicketTypeState.unavailable);
      expect(ticketTypeState(const TicketType(id: 'a', name: 'A', price: 1, quantity: 10, sold: 3, held: 2), now), TicketTypeState.onSale);
    });
  });

  group('TicketPaymentSelector', () {
    Widget selector(TicketPaymentChoice value) => _app(TicketPaymentSelector(
          uid: 'u1',
          value: value,
          onChanged: (_) {},
          price: 25,
          currency: 'R\$',
          accounts: _ready,
          config: _config,
          feeRule: TicketFeeRule.gold,
        ));

    testWidgets('only Mercado Pago and Stripe; no payment-link option; fee note + buyer preview', (t) async {
      await t.pumpWidget(selector(const TicketPaymentChoice()));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticket-provider-mercadopago')), findsOneWidget);
      expect(find.byKey(const ValueKey('ticket-provider-stripe')), findsOneWidget);
      expect(find.byKey(const ValueKey('ticket-provider-link')), findsNothing);
      expect(find.byKey(const ValueKey('ticket-fee-host-note')), findsOneWidget);
      // Gold: US$2 (R$ 11,00) + 10 % of R$ 25,00 = R$ 13,50 -> R$ 38,50.
      final preview = (t.widget(find.descendant(
              of: find.byKey(const ValueKey('ticket-fee-host-preview')), matching: find.byType(Text))) as Text)
          .data!;
      expect(preview, contains('13.50'));
      expect(preview, contains('38.50'));
    });

    testWidgets('a legacy link listing shows the discontinued banner', (t) async {
      await t.pumpWidget(selector(const TicketPaymentChoice(provider: TicketProvider.link, linkMethod: 'pix')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticket-link-discontinued')), findsOneWidget);
    });

    testWidgets('MP blocked with a clear message when the listing currency differs', (t) async {
      await t.pumpWidget(_app(const TicketPaymentSelector(
        uid: 'u1',
        value: TicketPaymentChoice(),
        onChanged: _noop,
        price: 25,
        currency: '\$',
        accounts: _ready,
        config: _config,
        feeRule: TicketFeeRule.silver,
      )));
      await t.pumpAndSettle();
      expect(find.textContaining('Mercado Pago only charges in BRL'), findsOneWidget);
    });
  });

  group('BuyTicketSheet', () {
    Event event({int max = 0, int count = 0, int? limit = 4}) => Event(
          id: 'e1',
          organizerId: 'org',
          organizerName: 'Org',
          title: 'Samba',
          description: 'd',
          category: EventCategory.values.first,
          startDate: DateTime(2030),
          endDate: DateTime(2030, 1, 2),
          locationName: 'Lapa',
          maxAttendees: max,
          status: EventStatus.published,
          createdAt: DateTime(2026),
          price: 25,
          currency: 'R\$',
          currencyCode: 'brl',
          ticketProvider: 'stripe',
          attendeeCount: count,
          maxTicketsPerUser: limit,
        );

    testWidgets('quantity stepper stops at the per-person allowance; total recalculates', (t) async {
      await t.pumpWidget(_app(BuyTicketSheet(event: event(), uid: 'u1', types: const [], alreadyHeld: 2)));
      await t.pumpAndSettle();
      expect(find.text('You can buy 2 more tickets'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('buy-qty-single-plus')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-qty-single-value')), findsOneWidget);
      expect((t.widget(find.byKey(const ValueKey('buy-qty-single-value'))) as Text).data, '2');
      final plus = t.widget<IconButton>(find.byKey(const ValueKey('buy-qty-single-plus')));
      expect(plus.onPressed, isNull);
      expect((t.widget(find.byKey(const ValueKey('buy-total'))) as Text).data, contains('50'));
    });

    testWidgets('the GreenGo service fee is shown before paying (trial: US\$1 per ticket)', (t) async {
      await t.pumpWidget(_app(BuyTicketSheet(
          event: event(), uid: 'u1', types: const [], alreadyHeld: 0, feeRule: TicketFeeRule.trial)));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('buy-qty-single-plus')));
      await t.pumpAndSettle();
      // 2 x R$ 25,00 + 2 x R$ 5,50 = R$ 61,00
      expect((t.widget(find.byKey(const ValueKey('ticket-fee-subtotal'))) as Text).data, contains('50.00'));
      expect((t.widget(find.byKey(const ValueKey('ticket-fee-fee'))) as Text).data, contains('11.00'));
      expect((t.widget(find.byKey(const ValueKey('buy-total'))) as Text).data, contains('61.00'));
      expect(find.byKey(const ValueKey('ticket-fee-trial')), findsOneWidget);
    });

    testWidgets('ticket types: sold-out type cannot be added, total sums types', (t) async {
      await t.pumpWidget(_app(BuyTicketSheet(
        event: event(limit: null),
        uid: 'u1',
        alreadyHeld: 0,
        types: const [
          TicketType(id: 'ga', name: 'General', price: 2000),
          TicketType(id: 'vip', name: 'VIP', price: 8000, quantity: 1, sold: 1),
        ],
      )));
      await t.pumpAndSettle();
      expect(t.widget<IconButton>(find.byKey(const ValueKey('buy-type-vip-plus'))).onPressed, isNull);
      await t.tap(find.byKey(const ValueKey('buy-type-ga-plus')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('buy-type-ga-plus')));
      await t.pumpAndSettle();
      expect((t.widget(find.byKey(const ValueKey('buy-total'))) as Text).data, contains('40'));
    });
  });

  testWidgets('selector texts exist in every language', (t) async {
    for (final loc in AppLocalizations.supportedLocales) {
      await t.pumpWidget(_app(
        const TicketPaymentSelector(
          uid: 'u1',
          value: TicketPaymentChoice(),
          onChanged: _noop,
          price: 10,
          currency: '€',
          accounts: PaymentAccounts(),
          config: _config,
          feeRule: TicketFeeRule.platinum,
        ),
        locale: loc,
      ));
      await t.pumpAndSettle();
      final l = AppLocalizations.of(t.element(find.byType(TicketPaymentSelector)))!;
      expect(find.text(l.tpSelectorTitle), findsOneWidget);
    }
  });
}

void _noop(TicketPaymentChoice _) {}
