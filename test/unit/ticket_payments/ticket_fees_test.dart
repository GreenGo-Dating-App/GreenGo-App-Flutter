import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_fees.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_payments.dart';

/// Display mirror of functions/src/ticket_payments/fees.ts — same cases as
/// functions/__tests__/unit/ticketPaymentsFees.test.ts (the server is
/// authoritative; these keep the two in step).
void main() {
  group('rule by host tier', () {
    test('tiers map to rules; TEST = platinum; no paid tier = silver; trial wins', () {
      expect(ticketFeeRuleForTier('SILVER'), TicketFeeRule.silver);
      expect(ticketFeeRuleForTier('GOLD'), TicketFeeRule.gold);
      expect(ticketFeeRuleForTier('PLATINUM'), TicketFeeRule.platinum);
      expect(ticketFeeRuleForTier('TEST'), TicketFeeRule.platinum);
      expect(ticketFeeRuleForTier('FREE'), TicketFeeRule.silver);
      expect(ticketFeeRuleForTier(null), TicketFeeRule.silver);
      expect(ticketFeeRuleForTier('PLATINUM', trial: true), TicketFeeRule.trial);
      expect(TicketFeeRule.fromWire('gold'), TicketFeeRule.gold);
      expect(TicketFeeRule.fromWire('nope'), isNull);
    });
  });

  group('fee per ticket', () {
    test('fixed + 10 % under the cap (USD)', () {
      expect(ticketFeePerTicket(TicketFeeRule.silver, 2000, 'usd'), 500);
      expect(ticketFeePerTicket(TicketFeeRule.gold, 2000, 'usd'), 400);
      expect(ticketFeePerTicket(TicketFeeRule.platinum, 2000, 'usd'), 300);
    });

    test('caps: US\$10 / 9 / 8', () {
      expect(ticketFeePerTicket(TicketFeeRule.silver, 10000, 'usd'), 1000);
      expect(ticketFeePerTicket(TicketFeeRule.gold, 10000, 'usd'), 900);
      expect(ticketFeePerTicket(TicketFeeRule.platinum, 10000, 'usd'), 800);
      expect(ticketFeePerTicket(TicketFeeRule.silver, 7000, 'usd'), 1000);
    });

    test('trial: flat US\$1; free tickets: no fee', () {
      expect(ticketFeePerTicket(TicketFeeRule.trial, 500, 'usd'), 100);
      expect(ticketFeePerTicket(TicketFeeRule.trial, 100000, 'usd'), 100);
      expect(ticketFeePerTicket(TicketFeeRule.silver, 0, 'usd'), 0);
      expect(ticketFeePerTicket(TicketFeeRule.trial, 0, 'usd'), 0);
    });

    test('rounding to the minor unit', () {
      expect(ticketFeePerTicket(TicketFeeRule.platinum, 1999, 'usd'), 300);
      expect(ticketFeePerTicket(TicketFeeRule.platinum, 1994, 'usd'), 299);
    });

    test('currency conversion of the US\$ parts; zero-decimal currencies', () {
      final brl1 = usdCentsToMinor(100, 'brl')!;
      expect(brl1, (kUsdRates['brl']! * 100).round());
      expect(ticketFeePerTicket(TicketFeeRule.silver, 5000, 'brl'), usdCentsToMinor(300, 'brl')! + 500);
      expect(ticketFeePerTicket(TicketFeeRule.platinum, 100000, 'brl'), usdCentsToMinor(800, 'brl'));
      expect(usdCentsToMinor(100, 'jpy'), kUsdRates['jpy']!.round());
      expect(ticketFeePerTicket(TicketFeeRule.gold, 3000, 'jpy'), 2 * kUsdRates['jpy']!.round() + 300);
      expect(currencyExponent('jpy'), 0);
    });

    test('unknown currency: no quote', () {
      expect(usdCentsToMinor(100, 'xyz'), isNull);
      expect(ticketFeePerTicket(TicketFeeRule.silver, 1000, 'xyz'), isNull);
      expect(ticketFeePerTicket(TicketFeeRule.silver, 0, 'xyz'), 0);
    });
  });

  group('whole order', () {
    test('one price', () {
      final f = computeTicketFee(TicketFeeRule.gold, 'usd', [(unitAmount: 2500, quantity: 3)])!;
      expect(f.subtotal, 7500);
      expect(f.fee, 1350);
      // Seller pays: the buyer's total is the ticket price.
      expect(f.total, 7500);
      expect(f.hostNet, 7500 - 1350);
    });

    test('the fee never exceeds the ticket price', () {
      expect(ticketFeePerTicket(TicketFeeRule.silver, 200, 'usd'), 200);
      expect(ticketFeePerTicket(TicketFeeRule.trial, 50, 'usd'), 50);
    });

    test('mixed ticket types incl. a free one', () {
      final f = computeTicketFee(TicketFeeRule.silver, 'usd', [
        (unitAmount: 15000, quantity: 1),
        (unitAmount: 2000, quantity: 2),
        (unitAmount: 0, quantity: 2),
      ])!;
      expect(f.fee, 1000 + 2 * 500);
      expect(f.subtotal, 19000);
    });

    test('unknown currency -> null', () {
      expect(estimateHostPayout(TicketFeeRule.silver, 100, 'xyz', null), isNull);
      expect(computeTicketFee(TicketFeeRule.silver, 'xyz', [(unitAmount: 100, quantity: 1)]), isNull);
    });
  });

  test('the schedule matches the owner rule', () {
    expect(kTicketFeeSchedules[TicketFeeRule.silver]!.fixedUsdCents, 300);
    expect(kTicketFeeSchedules[TicketFeeRule.silver]!.capUsdCents, 1000);
    expect(kTicketFeeSchedules[TicketFeeRule.gold]!.fixedUsdCents, 200);
    expect(kTicketFeeSchedules[TicketFeeRule.gold]!.capUsdCents, 900);
    expect(kTicketFeeSchedules[TicketFeeRule.platinum]!.fixedUsdCents, 100);
    expect(kTicketFeeSchedules[TicketFeeRule.platinum]!.capUsdCents, 800);
    expect(kTicketFeeSchedules[TicketFeeRule.trial]!.capUsdCents, isNull);
    for (final s in kTicketFeeSchedules.values.where((s) => s.capUsdCents != null)) {
      expect(s.percent, 10);
    }
  });

  test('kUsdRates mirrors USD_RATES in functions/src/ticket_payments/fees.ts', () {
    final ts = File('functions/src/ticket_payments/fees.ts').readAsStringSync();
    final block = RegExp(r'USD_RATES: Record<string, number> = \{([^}]*)\}').firstMatch(ts)!.group(1)!;
    final server = {
      for (final m in RegExp(r'([a-z]{3}): ([0-9.]+)').allMatches(block))
        m.group(1)!: double.parse(m.group(2)!),
    };
    expect(server, isNotEmpty);
    expect(kUsdRates, server);
  });

  group('host payout estimate', () {
    test('price - GreenGo fee - provider fee', () {
      // US$ 20 on Gold: fee US$ 4; Stripe US ~2.9 % + 30c = 58 + 30 = 88c.
      final e = estimateHostPayout(TicketFeeRule.gold, 2000, 'usd', TicketProvider.stripe)!;
      expect(e.greenGoFee, 400);
      expect(e.providerFee, 88);
      expect(e.net, 2000 - 400 - 88);
    });

    test('Mercado Pago BRL ~4.98 %; no provider yet -> no provider fee', () {
      expect(estimateProviderFee(TicketProvider.mercadoPago, 10000, 'brl'), 498);
      final e = estimateHostPayout(TicketFeeRule.platinum, 10000, 'brl', null)!;
      expect(e.providerFee, isNull);
      expect(e.net, 10000 - e.greenGoFee);
    });

    test('never negative', () {
      final e = estimateHostPayout(TicketFeeRule.silver, 100, 'usd', TicketProvider.stripe)!;
      expect(e.net, 0);
    });
  });
}
