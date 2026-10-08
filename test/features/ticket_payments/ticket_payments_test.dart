import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/qr_checkin_service.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
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
  group('payment mode advice (audience size)', () {
    test('large or unlimited -> instant recommended; small -> link simplest; free -> none', () {
      expect(adviseTicketPayment(capacity: 30, price: 10), TicketPaymentAdvice.instantRecommended);
      expect(adviseTicketPayment(capacity: 200, price: 10), TicketPaymentAdvice.instantRecommended);
      expect(adviseTicketPayment(capacity: null, price: 10), TicketPaymentAdvice.instantRecommended);
      expect(adviseTicketPayment(capacity: 0, price: 10), TicketPaymentAdvice.instantRecommended);
      expect(adviseTicketPayment(capacity: 29, price: 10), TicketPaymentAdvice.linkSimplest);
      expect(adviseTicketPayment(capacity: 8, price: 10, threshold: 5), TicketPaymentAdvice.instantRecommended);
      expect(adviseTicketPayment(capacity: 100, price: 0), TicketPaymentAdvice.none);
    });
    test('soft warning only for manual on a large listing; pending pile-up hint', () {
      expect(warnManualForLarge(TicketPaymentAdvice.instantRecommended, TicketProvider.link), isTrue);
      expect(warnManualForLarge(TicketPaymentAdvice.instantRecommended, TicketProvider.stripe), isFalse);
      expect(warnManualForLarge(TicketPaymentAdvice.linkSimplest, TicketProvider.link), isFalse);
      expect(suggestInstantForPending(9), isFalse);
      expect(suggestInstantForPending(10), isTrue);
    });
  });

  group('rules mirrored from the server', () {
    test('manual methods never include pasted Stripe / Mercado Pago links', () {
      final m = manualTicketMethods(['pix', 'stripe', 'mercadoPago', 'paypal']);
      expect(m, ['pix', 'paypal', kTicketMethodCash, kTicketMethodBankTransfer]);
      expect(needsReconnect(const TicketPaymentChoice(provider: TicketProvider.link, linkMethod: 'stripe')), isTrue);
      expect(needsReconnect(const TicketPaymentChoice(provider: TicketProvider.link, linkMethod: 'pix')), isFalse);
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
    Widget selector(int? capacity, TicketPaymentChoice value, {ValueChanged<TicketPaymentChoice>? onChanged}) =>
        _app(TicketPaymentSelector(
          uid: 'u1',
          value: value,
          onChanged: onChanged ?? (_) {},
          capacity: capacity,
          price: 25,
          currency: 'R\$',
          accounts: _ready,
          config: _config,
          profileMethodKeys: const ['pix', 'stripe', 'mercadoPago'],
        ));

    testWidgets('large audience: instant first with Recommended badge', (t) async {
      await t.pumpWidget(selector(100, const TicketPaymentChoice()));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticket-advice-instantRecommended')), findsOneWidget);
      final mp = t.getTopLeft(find.byKey(const ValueKey('ticket-provider-mercadopago')));
      final link = t.getTopLeft(find.byKey(const ValueKey('ticket-provider-link')));
      expect(mp.dy < link.dy, isTrue);
      expect(find.text('Recommended'), findsNWidgets(2));
    });

    testWidgets('small group: manual link first with No setup badge', (t) async {
      await t.pumpWidget(selector(6, const TicketPaymentChoice()));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticket-advice-linkSimplest')), findsOneWidget);
      final mp = t.getTopLeft(find.byKey(const ValueKey('ticket-provider-mercadopago')));
      final link = t.getTopLeft(find.byKey(const ValueKey('ticket-provider-link')));
      expect(link.dy < mp.dy, isTrue);
      expect(find.text('No setup'), findsOneWidget);
    });

    testWidgets('manual on a large listing shows the soft warning; methods exclude Stripe/MP links', (t) async {
      await t.pumpWidget(selector(80, const TicketPaymentChoice(provider: TicketProvider.link, linkMethod: 'pix')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticket-manual-warning')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('ticket-link-method')));
      await t.pumpAndSettle();
      expect(find.text('Pix'), findsWidgets);
      expect(find.text('Stripe'), findsOneWidget); // the instant tile only
      expect(find.text('Cash (before the event)'), findsWidgets);
    });

    testWidgets('MP blocked with a clear message when the listing currency differs', (t) async {
      await t.pumpWidget(_app(const TicketPaymentSelector(
        uid: 'u1',
        value: TicketPaymentChoice(),
        onChanged: _noop,
        capacity: 100,
        price: 25,
        currency: '\$',
        accounts: _ready,
        config: _config,
        profileMethodKeys: [],
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
          ticketProvider: 'link',
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
        TicketPaymentSelector(
          uid: 'u1',
          value: const TicketPaymentChoice(),
          onChanged: _noop,
          capacity: 5,
          price: 10,
          currency: '€',
          accounts: const PaymentAccounts(),
          config: _config,
          profileMethodKeys: const [],
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
