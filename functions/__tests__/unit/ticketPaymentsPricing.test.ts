/**
 * Ticket payments: date-based experience pricing + provider payloads (pure).
 */
import { computeBookingPrice, localDay, resolveDatePrice } from '../../src/experience_bookings/model';
import { mpPreferenceBody, statementSuffix, stripeLocale, stripeSessionParams, CheckoutInput } from '../../src/ticket_payments/checkoutPayload';

const SAT_NOON_SP = Date.UTC(2026, 9, 10, 15, 0); // Sat 10 Oct 2026 12:00 in São Paulo (UTC-3)
const FRI_LATE_SP = Date.UTC(2026, 9, 10, 2, 30); // Fri 9 Oct 23:30 São Paulo = Sat 02:30 UTC

describe('date-based pricing (host time zone)', () => {
  const base = { price: 100, currency: 'R$', availability: { timezone: 'America/Sao_Paulo' } };

  test('weekend detection uses the host zone, not UTC (late-night boundary)', () => {
    expect(localDay(FRI_LATE_SP, 'America/Sao_Paulo')).toEqual({ date: '2026-10-09', weekday: 5 });
    expect(localDay(FRI_LATE_SP, 'UTC').weekday).toBe(6);
    const e = { ...base, weekendPrice: 150 };
    expect(resolveDatePrice(e, FRI_LATE_SP)).toEqual({ value: 100, rule: 'base' });
    expect(resolveDatePrice(e, SAT_NOON_SP)).toEqual({ value: 150, rule: 'weekend' });
  });

  test('custom weekend days (Fri-Sun)', () => {
    const e = { ...base, weekendPrice: 150, weekendDays: [5, 6, 7] };
    expect(resolveDatePrice(e, FRI_LATE_SP).rule).toBe('weekend');
  });

  test('precedence: day override > weekend > base', () => {
    const e = { ...base, weekendPrice: 150, dayOverrides: { '2026-10-10': { priceOverride: 200 } } };
    expect(resolveDatePrice(e, SAT_NOON_SP)).toEqual({ value: 200, rule: 'day' });
    expect(computeBookingPrice(e, 2, SAT_NOON_SP)).toMatchObject({ ok: true, price: { unitAmount: 20000, totalAmount: 40000 } });
    expect(computeBookingPrice(e, 2, FRI_LATE_SP)).toMatchObject({ ok: true, price: { unitAmount: 10000 } });
  });

  test('per_group: the group price follows the same rules', () => {
    const e = { pricingMode: 'per_group', groupPrice: 40000, weekendPrice: 50000, currency: 'R$', maxGroupSize: 8, availability: { timezone: 'America/Sao_Paulo' } };
    expect(computeBookingPrice(e, 5, SAT_NOON_SP)).toMatchObject({ ok: true, price: { totalAmount: 50000 } });
  });
});

describe('provider payloads are built from the listing only', () => {
  const input: CheckoutInput = {
    orderId: 'o1', listingKind: 'event', listingId: 'e1', title: 'Forró na Praça – VIP ★',
    description: 'Sat 10 Oct · Lapa', imageUrl: 'https://cdn.example/c.jpg',
    unitAmount: 1500, quantity: 3, currency: 'jpy',
    successUrl: 'https://x/s', cancelUrl: 'https://x/c', expiresAtMs: 2_000_000, nowMs: 1_000_000,
    buyerEmail: 'b@example.com', locale: 'pt_BR',
  };
  test('Stripe: minor units, quantity, email, reference, ascii descriptor, locale, min expiry', () => {
    const p = stripeSessionParams(input, ['card']);
    expect(p.line_items[0]).toMatchObject({ quantity: 3, price_data: { currency: 'jpy', unit_amount: 1500 } });
    expect(p.line_items[0].price_data.product_data).toMatchObject({ name: input.title, description: input.description, images: [input.imageUrl] });
    expect(p.client_reference_id).toBe('o1');
    expect(p.customer_email).toBe('b@example.com');
    expect(p.locale).toBe('pt-BR');
    expect(p.payment_intent_data.statement_descriptor_suffix).toMatch(/^[A-Za-z0-9 .-]{1,22}$/);
    expect(p.expires_at * 1000).toBeGreaterThanOrEqual(input.nowMs + 30 * 60000);
    expect(p.application_fee_amount).toBeUndefined();
  });
  test('MP: decimal unit_price (zero-decimal stays whole), currency_id, payer, reference, descriptor', () => {
    const b = mpPreferenceBody({ ...input, currency: 'brl', unitAmount: 2550 });
    expect(b.items[0]).toMatchObject({ id: 'e1', quantity: 3, currency_id: 'BRL', unit_price: 25.5, category_id: 'tickets', picture_url: input.imageUrl });
    expect(mpPreferenceBody(input).items[0].unit_price).toBe(1500);
    expect(b.payer).toEqual({ email: 'b@example.com' });
    expect(b.external_reference).toBe('o1');
    expect(b.statement_descriptor.length).toBeLessThanOrEqual(22);
    expect(b.marketplace_fee).toBeUndefined();
  });
  test('helpers', () => {
    expect(statementSuffix('★★★')).toBe('GG');
    expect(statementSuffix('Ação Noturna São João')).toMatch(/^GG Acao Noturna Sao/);
    expect(stripeLocale('xx')).toBe('auto');
    expect(stripeLocale('de_DE')).toBe('de');
  });
});
