/**
 * Ticket payments: the GreenGo service fee (pure, ./src/ticket_payments/fees.ts)
 * and how it reaches the Stripe / Mercado Pago payloads.
 */
import {
  FEE_SCHEDULES,
  USD_RATES,
  computeOrderFee,
  feePerTicket,
  feeQuote,
  feeRuleForTier,
  resolveTrial,
  trialKey,
  usdCentsToMinor,
} from '../../src/ticket_payments/fees';
import { CheckoutInput, mpPreferenceBody, stripeSessionParams } from '../../src/ticket_payments/checkoutPayload';

describe('fee rule by host tier', () => {
  test('tiers map to rules; TEST = platinum; no paid tier = silver', () => {
    expect(feeRuleForTier('SILVER', false)).toBe('silver');
    expect(feeRuleForTier('GOLD', false)).toBe('gold');
    expect(feeRuleForTier('PLATINUM', false)).toBe('platinum');
    expect(feeRuleForTier('TEST', false)).toBe('platinum');
    expect(feeRuleForTier('FREE', false)).toBe('silver');
    expect(feeRuleForTier(null, false)).toBe('silver');
    expect(feeRuleForTier('PLATINUM', true)).toBe('trial');
  });

  test('schedule matches the owner rule', () => {
    expect(FEE_SCHEDULES.silver).toEqual({ fixedUsdCents: 300, percent: 10, capUsdCents: 3000 });
    expect(FEE_SCHEDULES.gold).toEqual({ fixedUsdCents: 200, percent: 10, capUsdCents: 2800 });
    expect(FEE_SCHEDULES.platinum).toEqual({ fixedUsdCents: 100, percent: 10, capUsdCents: 2500 });
    expect(FEE_SCHEDULES.trial).toEqual({ fixedUsdCents: 100, percent: 0, capUsdCents: null });
  });
});

describe('fee per ticket (USD)', () => {
  test('fixed + 10 %, under the cap', () => {
    expect(feePerTicket('silver', 2000, 'usd')).toBe(300 + 200); // $20 -> $5
    expect(feePerTicket('gold', 2000, 'usd')).toBe(200 + 200); // $4
    expect(feePerTicket('platinum', 2000, 'usd')).toBe(100 + 200); // $3
  });

  test('caps: $30 silver, $28 gold, $25 platinum (owner rule 2026-10-16)', () => {
    // $100: under every cap now
    expect(feePerTicket('silver', 10000, 'usd')).toBe(1300); // 3 + 10
    expect(feePerTicket('gold', 10000, 'usd')).toBe(1200); // 2 + 10
    expect(feePerTicket('platinum', 10000, 'usd')).toBe(1100); // 1 + 10
    // $500: capped
    expect(feePerTicket('silver', 50000, 'usd')).toBe(3000); // 3 + 50 = 53 -> 30
    expect(feePerTicket('gold', 50000, 'usd')).toBe(2800); // 2 + 50 = 52 -> 28
    expect(feePerTicket('platinum', 50000, 'usd')).toBe(2500); // 1 + 50 = 51 -> 25
    // exactly at the cap
    expect(feePerTicket('silver', 27000, 'usd')).toBe(3000);
    expect(feePerTicket('gold', 26000, 'usd')).toBe(2800);
    expect(feePerTicket('platinum', 24000, 'usd')).toBe(2500);
    expect(feePerTicket('silver', 27010, 'usd')).toBe(3000);
  });

  test('trial is a flat $1 whatever the price', () => {
    expect(feePerTicket('trial', 500, 'usd')).toBe(100);
    expect(feePerTicket('trial', 100000, 'usd')).toBe(100);
  });

  test('the fee never exceeds the ticket price (it is taken from the charge)', () => {
    expect(feePerTicket('silver', 200, 'usd')).toBe(200); // 3 + 0.2 > 2 -> 2
    expect(feePerTicket('trial', 50, 'usd')).toBe(50);
  });

  test('free ticket: no fee (trial included)', () => {
    expect(feePerTicket('silver', 0, 'usd')).toBe(0);
    expect(feePerTicket('trial', 0, 'usd')).toBe(0);
  });

  test('10 % rounds to the minor unit', () => {
    expect(feePerTicket('platinum', 1999, 'usd')).toBe(100 + 200); // 199.9 -> 200
    expect(feePerTicket('platinum', 1994, 'usd')).toBe(100 + 199); // 199.4 -> 199
  });
});

describe('currency conversion of the US$ parts', () => {
  test('fixed + cap converted, 10 % taken in the ticket currency', () => {
    expect(usdCentsToMinor(100, 'brl')).toBe(Math.round(USD_RATES.brl * 100));
    // R$ 50,00 silver: 3 USD + 5,00 BRL
    const fixed = usdCentsToMinor(300, 'brl') as number;
    expect(feePerTicket('silver', 5000, 'brl')).toBe(fixed + 500);
    // R$ 1000,00 platinum: 1 USD + R$ 100,00, under the 25 USD cap
    expect(feePerTicket('platinum', 100000, 'brl')).toBe((usdCentsToMinor(100, 'brl') as number) + 10000);
    // R$ 5000,00: capped at 30 / 28 / 25 USD in BRL
    expect(feePerTicket('silver', 500000, 'brl')).toBe(usdCentsToMinor(3000, 'brl'));
    expect(feePerTicket('gold', 500000, 'brl')).toBe(usdCentsToMinor(2800, 'brl'));
    expect(feePerTicket('platinum', 500000, 'brl')).toBe(usdCentsToMinor(2500, 'brl'));
    // the fee never exceeds a cheap ticket's price in another currency
    expect(feePerTicket('silver', 1000, 'brl')).toBe(1000);
  });

  test('zero-decimal currencies round to whole units', () => {
    expect(usdCentsToMinor(100, 'jpy')).toBe(USD_RATES.jpy);
    expect(Number.isInteger(feePerTicket('gold', 3333, 'jpy'))).toBe(true);
    expect(feePerTicket('gold', 3000, 'jpy')).toBe(2 * USD_RATES.jpy + 300);
    expect(feePerTicket('trial', 3000, 'clp')).toBe(USD_RATES.clp);
    expect(feePerTicket('gold', 100000, 'jpy')).toBe(28 * USD_RATES.jpy); // capped at 28 USD
  });

  test('unknown currency -> null (checkout refused)', () => {
    expect(usdCentsToMinor(100, 'xyz')).toBeNull();
    expect(feePerTicket('silver', 1000, 'xyz')).toBeNull();
    expect(computeOrderFee('silver', 'xyz', [{ typeId: null, unitAmount: 1000, quantity: 1 }])).toBeNull();
    // ... but a free ticket in an unknown currency owes nothing
    expect(feePerTicket('silver', 0, 'xyz')).toBe(0);
  });
});

describe('whole order', () => {
  test('one price: fee per ticket x quantity, paid by the seller (buyer total = subtotal)', () => {
    const f = computeOrderFee('gold', 'usd', [{ typeId: null, unitAmount: 2500, quantity: 3 }])!;
    expect(f).toMatchObject({
      rule: 'gold', ticketSubtotal: 7500, feePerTicket: 450, feeTotal: 1350, total: 7500, hostNet: 7500 - 1350,
    });
  });

  test('mixed ticket types: per-line fee, free types owe nothing', () => {
    const f = computeOrderFee('silver', 'usd', [
      { typeId: 'vip', unitAmount: 15000, quantity: 1 },
      { typeId: 'std', unitAmount: 2000, quantity: 2 },
      { typeId: 'kid', unitAmount: 0, quantity: 2 },
    ])!;
    expect(f.lines.map((l) => l.unitFee)).toEqual([1800, 500, 0]); // $150: 3 + 15 (under the $30 cap)
    expect(f.feeTotal).toBe(1800 + 2 * 500);
    expect(f.ticketSubtotal).toBe(19000);
    expect(f.feePerTicket).toBeNull(); // differs per type
    expect(f.total).toBe(19000);
    expect(f.hostNet).toBe(19000 - 2800);
  });

  test('trial: same fee for every paid type', () => {
    const f = computeOrderFee('trial', 'usd', [
      { typeId: 'a', unitAmount: 15000, quantity: 1 },
      { typeId: 'b', unitAmount: 2000, quantity: 2 },
    ])!;
    expect(f.feePerTicket).toBe(100);
    expect(f.feeTotal).toBe(300);
  });
});

describe('first paid listing trial', () => {
  const k = trialKey('event', 'e1');

  test('first claim goes to the listing, and stays there', () => {
    expect(resolveTrial(undefined, k, false)).toEqual({ trial: true, store: { key: k } });
    expect(resolveTrial({ key: k }, k, false)).toEqual({ trial: true, store: null });
    expect(resolveTrial({ key: k }, trialKey('event', 'e2'), false)).toEqual({ trial: false, store: null });
    // experiences share the same single trial
    expect(resolveTrial({ key: k }, trialKey('experience', 'x1'), false).trial).toBe(false);
  });

  test('a host who already sold paid tickets gets no trial', () => {
    expect(resolveTrial(undefined, k, true)).toEqual({ trial: false, store: { key: null } });
    expect(resolveTrial({ key: null }, k, false)).toEqual({ trial: false, store: null });
  });

  test('a decided claim never consults the order history again', () => {
    expect(resolveTrial({ key: k }, k, true).trial).toBe(true);
  });
});

describe('fee in the provider payloads', () => {
  const input: CheckoutInput = {
    orderId: 'o1', listingKind: 'event', listingId: 'e1', title: 'Samba night', description: null,
    imageUrl: null, unitAmount: 2500, quantity: 2, currency: 'usd',
    successUrl: 'https://x/s', cancelUrl: 'https://x/c', expiresAtMs: 2_000_000_000_000, nowMs: 1_999_990_000_000,
    feeAmount: 900,
  };

  test('Stripe: buyer pays the tickets only; the fee is kept via application_fee_amount', () => {
    const p = stripeSessionParams(input, ['card']);
    expect(p.line_items).toHaveLength(1);
    expect(p.payment_intent_data.application_fee_amount).toBe(900);
    const total = p.line_items.reduce((s: number, l: any) => s + l.quantity * l.price_data.unit_amount, 0);
    expect(total).toBe(2500 * 2);
  });

  test('Mercado Pago: no fee item; marketplace_fee (major units) kept from the host', () => {
    const b = mpPreferenceBody({ ...input, currency: 'brl' });
    expect(b.items).toHaveLength(1);
    expect(b.marketplace_fee).toBe(9);
  });

  test('no fee: payloads unchanged (no fee line, no application fee)', () => {
    const p = stripeSessionParams({ ...input, feeAmount: 0 }, ['card']);
    expect(p.line_items).toHaveLength(1);
    expect('application_fee_amount' in p.payment_intent_data).toBe(false);
    const b = mpPreferenceBody({ ...input, feeAmount: undefined });
    expect(b.items).toHaveLength(1);
    expect('marketplace_fee' in b).toBe(false);
  });
});

describe('client quote', () => {
  test('carries the rule parameters and the currency rate', () => {
    expect(feeQuote('gold', 'BRL')).toEqual({
      rule: 'gold', fixedUsdCents: 200, percent: 10, capUsdCents: 2800, currency: 'brl', usdRate: USD_RATES.brl,
    });
    expect(feeQuote('trial', null)).toMatchObject({ rule: 'trial', currency: null, usdRate: null });
  });
});
