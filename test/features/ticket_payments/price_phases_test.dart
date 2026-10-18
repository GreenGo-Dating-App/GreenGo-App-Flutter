import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/events/data/models/event_model.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/ticket_payments/data/ticket_payments_service.dart';
import 'package:greengo_chat/features/ticket_payments/domain/price_phases.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_fees.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_payments.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/ticket_l10n.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/widgets/buy_ticket_sheet.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/widgets/price_phases_widgets.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:greengo_chat/generated/app_localizations_en.dart';

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

const _eb = PricePhase(id: 'eb', name: PricePhaseName.earlyBird, price: 20, quantity: 2);
const _rg = PricePhase(id: 'rg', name: PricePhaseName.regular, price: 30, quantity: 3);
const _lt = PricePhase(id: 'lt', name: PricePhaseName.late, price: 40, quantity: 2);
const _three = [_eb, _rg, _lt];

PricePhaseError? _v(List<PricePhase> p,
        {int capacity = 0, Map<String, int> sold = const {}, List<PricePhase> original = const []}) =>
    validatePricePhases(p, capacity: capacity, currency: 'brl', sold: sold, original: original);

void main() {
  group('validation (mirrors functions/src/ticket_payments/pricePhases.ts)', () {
    test('valid setup', () => expect(_v(_three), isNull));
    test('prices strictly increasing', () {
      expect(_v([_eb, _rg.copyWith(price: 20)]), PricePhaseError.notIncreasing);
      expect(_v([_rg, _eb]), PricePhaseError.notIncreasing);
    });
    test('price limits, quantity, names once', () {
      expect(_v([_eb.copyWith(price: 0.5)]), PricePhaseError.priceRange);
      expect(_v([_eb.copyWith(price: 1001)]), PricePhaseError.priceRange);
      expect(_v([_eb.copyWith(quantity: 0)]), PricePhaseError.quantity);
      expect(_v([_eb, _rg.copyWith(name: PricePhaseName.earlyBird)]), PricePhaseError.duplicateName);
    });
    test('sum of quantities <= capacity (0 = unlimited)', () {
      expect(_v(_three, capacity: 7), isNull);
      expect(_v(_three, capacity: 6), PricePhaseError.overCapacity);
      expect(_v(_three), isNull);
    });
    test('after sales: keep, same price, not below sold, new phases after the sold ones', () {
      const sold = {'eb': 2, 'rg': 1};
      expect(_v(_three, sold: sold, original: _three), isNull);
      expect(_v([_rg, _lt], sold: sold, original: _three), PricePhaseError.soldPhaseRemoved);
      expect(_v([_eb.copyWith(price: 22), _rg, _lt], sold: sold, original: _three), PricePhaseError.soldPriceChanged);
      expect(_v([_eb, _rg.copyWith(quantity: 0)], sold: sold, original: _three), PricePhaseError.quantity);
      expect(_v([_eb.copyWith(quantity: 1), _rg], sold: sold, original: _three), PricePhaseError.belowSold);
      const inserted = PricePhase(id: 'nw', name: PricePhaseName.presale, price: 25, quantity: 1);
      expect(_v([_eb, inserted, _rg, _lt], sold: sold, original: _three), PricePhaseError.insertedBeforeSold);
      const appended = PricePhase(id: 'nw', name: PricePhaseName.door, price: 60, quantity: 1);
      expect(_v([..._three, appended], sold: sold, original: _three), isNull);
      // A phase without sales may change or go.
      expect(_v([_eb, _rg, _lt.copyWith(price: 45)], sold: sold, original: _three), isNull);
      expect(_v([_eb, _rg], sold: sold, original: _three), isNull);
    });
  });

  group('current phase + orders spanning phases', () {
    test('current = first with tickets left; -1 when all sold out', () {
      expect(currentPricePhaseIndex(_three, const {}), 0);
      expect(currentPricePhaseIndex(_three, const {'eb': 2}), 1);
      expect(currentPricePhaseIndex(_three, const {'eb': 2, 'rg': 3, 'lt': 2}), -1);
      expect(pricePhasesLeft(_three, const {'eb': 5}), [0, 3, 2]);
    });
    test('an order spans phases, each ticket at its phase', () {
      final lines = allocatePricePhases(_three, const {'eb': 1}, 3, 'brl')!;
      expect(lines.map((x) => (x.phase.id, x.unitAmount, x.quantity)).toList(),
          [('eb', 2000, 1), ('rg', 3000, 2)]);
      expect(pricePhaseTotal(lines), 8000);
      expect(allocatePricePhases(_three, const {'eb': 2, 'rg': 3, 'lt': 1}, 2, 'brl'), isNull);
    });
    test('GreenGo fee per ticket on each ticket price (seller pays)', () {
      final lines = allocatePricePhases(_three, const {}, 3, 'brl')!;
      final fee = pricePhaseFee(TicketFeeRule.gold, 'brl', lines)!;
      final a = ticketFeePerTicket(TicketFeeRule.gold, 2000, 'brl')!;
      final b = ticketFeePerTicket(TicketFeeRule.gold, 3000, 'brl')!;
      expect(fee.fee, 2 * a + b);
      expect(fee.total, 7000);
      expect(fee.hostNet, 7000 - 2 * a - b);
    });
    test('map round trip + event model', () {
      expect(PricePhase.fromMap(_eb.toMap()), _eb);
      expect(_eb.toMap()['price'], isA<int>());
      expect(PricePhase.listFrom([_eb.toMap(), {'id': 'x', 'nameKey': 'vip', 'price': 1, 'quantity': 1}, 'junk']), [_eb]);
      final m = EventModel.fromJson({'id': 'e', 'price': 20, 'pricePhases': [_eb.toMap(), _rg.toMap()]});
      expect(m.pricePhases, [_eb, _rg]);
      expect(m.hasPricePhases, isTrue);
      expect(EventModel.fromEntity(m).toJson()['pricePhases'], [_eb.toMap(), _rg.toMap()]);
      expect(EventModel.fromJson(const {'id': 'old', 'price': 20}).pricePhases, isEmpty);
      expect(m.copyWith(clearTicketing: true).pricePhases, isEmpty);
    });
    test('price_changed error text names the new price', () {
      final l = AppLocalizationsEn();
      final t = TicketL10n.error(l, const TicketPaymentException('price_changed', null, {'total': 3000, 'currency': 'brl'}));
      expect(t, startsWith('The price has changed to'));
      expect(t, contains('30'));
      expect(TicketL10n.error(l, const TicketPaymentException('price_phases_invalid')), l.tpErrPricePhasesInvalid);
    });
  });

  group('PricePhasesEditor', () {
    testWidgets('add phases (presets once, sorted), inline errors, payout per phase', (tester) async {
      var last = <PricePhase>[];
      await tester.pumpWidget(_app(PricePhasesEditor(
        initial: const [],
        currency: 'R\$',
        capacity: 10,
        basePrice: 20,
        provider: TicketProvider.stripe,
        feeRule: TicketFeeRule.platinum,
        onChanged: (p) => last = p,
      )));
      expect(find.text('Price phases (early bird…)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('price-phases-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('price-phases-add')));
      await tester.pumpAndSettle();
      expect(last.map((p) => p.name).toList(), [PricePhaseName.earlyBird, PricePhaseName.presale]);
      expect(last.map((p) => p.price).toList(), [20, 25]);
      expect(find.text('Early bird'), findsOneWidget);
      expect(find.text('Presale'), findsOneWidget);
      // Default 10 + 10 tickets > capacity 10.
      expect(find.text('Phases have more tickets than the event capacity'), findsOneWidget);
      await tester.enterText(find.byKey(ValueKey('price-phase-qty-${last[0].id}')), '4');
      await tester.enterText(find.byKey(ValueKey('price-phase-qty-${last[1].id}')), '6');
      await tester.pump();
      expect(find.byKey(const ValueKey('price-phases-error')), findsNothing);
      // A later phase cheaper than the one before.
      await tester.enterText(find.byKey(ValueKey('price-phase-price-${last[1].id}')), '20');
      await tester.pump();
      expect(find.text('Each phase must cost more than the previous one'), findsOneWidget);
      await tester.enterText(find.byKey(ValueKey('price-phase-price-${last[1].id}')), '30');
      await tester.pump();
      expect(find.byKey(const ValueKey('price-phases-error')), findsNothing);
      // Seller payout estimate per phase (fee on that phase's own price).
      expect(find.byKey(ValueKey('price-phase-payout-${last[0].id}')), findsOneWidget);
      expect(find.byKey(ValueKey('price-phase-payout-${last[1].id}')), findsOneWidget);
      // Remove the second phase.
      await tester.tap(find.byKey(ValueKey('price-phase-remove-${last[1].id}')));
      await tester.pumpAndSettle();
      expect(last, hasLength(1));
    });

    testWidgets('a phase that sold is locked: no remove, no price edit, sold count shown', (tester) async {
      await tester.pumpWidget(_app(PricePhasesEditor(
        initial: _three,
        sold: const {'eb': 2},
        currency: 'R\$',
        capacity: 0,
        feeRule: TicketFeeRule.silver,
        onChanged: (_) {},
      )));
      expect(find.text('2 sold'), findsOneWidget);
      final remove = tester.widget<IconButton>(find.byKey(const ValueKey('price-phase-remove-eb')));
      expect(remove.onPressed, isNull);
      final price = tester.widget<TextFormField>(find.byKey(const ValueKey('price-phase-price-eb')));
      expect(price.enabled, isFalse);
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('price-phase-remove-rg'))).onPressed, isNotNull);
      // Quantity below what was sold.
      await tester.enterText(find.byKey(const ValueKey('price-phase-qty-eb')), '1');
      await tester.pump();
      expect(find.text("A phase can't have fewer tickets than it already sold"), findsOneWidget);
    });
  });

  group('buyer', () {
    testWidgets('detail: current phase, N left, next phase, sold-out struck through', (tester) async {
      await tester.pumpWidget(_app(const PricePhasesBuyerView(phases: _three, currency: 'brl', sold: {'eb': 2, 'rg': 1})));
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('2 left at this price'), findsOneWidget);
      expect(find.byKey(const ValueKey('price-phase-next')), findsOneWidget);
      expect(find.textContaining('(Late)'), findsOneWidget);
      final eb = tester.widget<Text>(find.byKey(const ValueKey('price-phase-price-eb')));
      expect(eb.style?.decoration, TextDecoration.lineThrough);
      expect(eb.data, startsWith('Sold out'));
    });

    testWidgets('buy sheet: order spanning phases lists lines per phase and the total', (tester) async {
      final ev = EventModel.fromJson({
        'id': 'e1', 'organizerId': 'org', 'title': 'Samba', 'price': 20, 'currency': 'R\$', 'currencyCode': 'brl',
        'maxAttendees': 0, 'maxTicketsPerUser': null, 'ticketProvider': 'stripe',
        'pricePhases': [_eb.toMap(), _rg.toMap(), _lt.toMap()],
      });
      await tester.pumpWidget(_app(BuyTicketSheet(
        event: ev, uid: 'u1', types: const [], alreadyHeld: 0, phaseSold: const {'eb': 1},
      )));
      await tester.pump();
      expect(find.textContaining('Early bird'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('buy-qty-single-plus')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-qty-single-plus')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-phase-line-eb')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-phase-line-rg')), findsOneWidget);
      expect(find.text('Early bird × 1'), findsOneWidget);
      expect(find.text('Regular × 2'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('buy-total'))).data,
          formatTicketAmount(2000 + 2 * 3000, 'brl'));
    });

    testWidgets('buy sheet: every phase sold out -> cannot continue', (tester) async {
      final ev = EventModel.fromJson({
        'id': 'e2', 'organizerId': 'org', 'title': 'Samba', 'price': 20, 'currency': 'R\$', 'currencyCode': 'brl',
        'maxAttendees': 0, 'maxTicketsPerUser': null, 'ticketProvider': 'stripe', 'pricePhases': [_eb.toMap()],
      });
      await tester.pumpWidget(_app(BuyTicketSheet(
        event: ev, uid: 'u1', types: const [], alreadyHeld: 0, phaseSold: const {'eb': 2},
      )));
      await tester.pump();
      final btn = tester.widget<ElevatedButton>(find.byKey(const ValueKey('buy-continue')));
      expect(btn.onPressed, isNull);
    });
  });

  test('Event entity default has no phases (old events)', () {
    final e = Event(
      id: 'x', organizerId: 'o', organizerName: 'O', title: 't', description: 'd',
      category: EventCategory.social, startDate: DateTime(2026), endDate: DateTime(2026),
      locationName: 'l', maxAttendees: 0, status: EventStatus.published, createdAt: DateTime(2026),
    );
    expect(e.hasPricePhases, isFalse);
  });
}
