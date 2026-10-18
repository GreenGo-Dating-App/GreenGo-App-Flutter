/**
 * Ticket price phases (pure, ./src/ticket_payments/pricePhases.ts): validation,
 * current phase, orders spanning phases, editing after sales, per-ticket fee.
 */
import {
  MAX_PRICE_PHASES,
  PHASE_NAME_KEYS,
  PricePhase,
  allocatePhases,
  currentPhaseIndex,
  phaseEditError,
  phaseLineCounts,
  phaseName,
  phasesLeft,
  readPricePhases,
  validatePricePhases,
} from '../../src/ticket_payments/pricePhases';
import { computeOrderFee, feePerTicket } from '../../src/ticket_payments/fees';
import { phaseSoldDelta } from '../../src/ticket_payments/orders';

const P = (id: string, nameKey: string, price: number, quantity: number) => ({ id, nameKey, price, quantity });
const THREE = [P('a', 'earlyBird', 20, 2), P('b', 'regular', 30, 5), P('c', 'late', 40, 3)];

function phases(raw: any[], cap = 0): PricePhase[] {
  const v = validatePricePhases(raw, cap, 'brl');
  if (v.ok === false) throw new Error(v.reason);
  return v.phases;
}

describe('validatePricePhases', () => {
  test('a valid setup passes, in list order', () => {
    expect(phases(THREE).map((p) => p.id)).toEqual(['a', 'b', 'c']);
  });
  test('absent / empty = no phases', () => {
    expect(readPricePhases(undefined)).toBeNull();
    expect(readPricePhases([])).toBeNull();
    expect(readPricePhases('x')).toBeNull();
    expect(readPricePhases(THREE)).toHaveLength(3);
  });
  test.each([
    [[P('a', 'earlyBird', 20, 2), P('b', 'regular', 20, 2)], 'phase_prices_not_increasing'],
    [[P('a', 'earlyBird', 30, 2), P('b', 'regular', 20, 2)], 'phase_prices_not_increasing'],
    [[P('a', 'earlyBird', 0.5, 2)], 'phase_price_out_of_range'],
    [[P('a', 'earlyBird', 1001, 2)], 'phase_price_out_of_range'],
    [[P('a', 'earlyBird', 10, 0)], 'invalid_phase_quantity'],
    [[P('a', 'earlyBird', 10, 1.5)], 'invalid_phase_quantity'],
    [[P('a', 'earlyBird', 10, 1), P('b', 'earlyBird', 20, 1)], 'duplicate_phase_name'],
    [[P('a', 'vipNight', 10, 1)], 'invalid_phase_name'],
    [[P('a', 'earlyBird', 10, 1), P('a', 'regular', 20, 1)], 'invalid_phase_id'],
    [[P('bad id!', 'earlyBird', 10, 1)], 'invalid_phase_id'],
    [[null], 'invalid_phase'],
  ])('%j -> %s', (raw, reason) => {
    const v = validatePricePhases(raw as any[], 0, 'brl');
    expect(v.ok).toBe(false);
    expect((v as any).reason).toBe(reason);
  });
  test('sum of quantities <= capacity (capacity 0 = unlimited)', () => {
    expect(validatePricePhases(THREE, 10, 'brl').ok).toBe(true);
    expect((validatePricePhases(THREE, 9, 'brl') as any).reason).toBe('phases_exceed_capacity');
    expect(validatePricePhases(THREE, 0, 'brl').ok).toBe(true);
  });
  test('at most MAX_PRICE_PHASES', () => {
    const many = Array.from({ length: MAX_PRICE_PHASES + 1 }, (_, i) => P(`p${i}`, PHASE_NAME_KEYS[i % 7], 10 + i, 1));
    expect((validatePricePhases(many, 0, 'brl') as any).reason).toBe('too_many_phases');
  });
  test('increasing is decided in minor units (zero-decimal currency)', () => {
    // 10.2 and 10.4 JPY both round to 10 yen: not increasing.
    expect((validatePricePhases([P('a', 'earlyBird', 10.2, 1), P('b', 'regular', 10.4, 1)], 0, 'jpy') as any).reason)
      .toBe('phase_prices_not_increasing');
  });
});

describe('current phase + allocation', () => {
  const ps = phases(THREE);
  test('the current phase is the first one with tickets left', () => {
    expect(currentPhaseIndex(ps, {})).toBe(0);
    expect(currentPhaseIndex(ps, { a: 2 })).toBe(1);
    expect(currentPhaseIndex(ps, { a: 2, b: 5 })).toBe(2);
    expect(currentPhaseIndex(ps, { a: 2, b: 5, c: 3 })).toBe(-1);
    // A released early-bird ticket comes back at its own price.
    expect(currentPhaseIndex(ps, { a: 1, b: 5 })).toBe(0);
    expect(phasesLeft(ps, { a: 5, b: -3 })).toEqual([0, 5, 3]);
  });
  test('an order spanning phases prices each ticket at its phase', () => {
    expect(allocatePhases(ps, {}, 3, 'brl')).toEqual([
      { phaseId: 'a', nameKey: 'earlyBird', unitAmount: 2000, quantity: 2 },
      { phaseId: 'b', nameKey: 'regular', unitAmount: 3000, quantity: 1 },
    ]);
    expect(allocatePhases(ps, { a: 2, b: 4 }, 2, 'brl')).toEqual([
      { phaseId: 'b', nameKey: 'regular', unitAmount: 3000, quantity: 1 },
      { phaseId: 'c', nameKey: 'late', unitAmount: 4000, quantity: 1 },
    ]);
  });
  test('not enough tickets left across phases -> null (sold out)', () => {
    expect(allocatePhases(ps, { a: 2, b: 5, c: 2 }, 2, 'brl')).toBeNull();
    expect(allocatePhases(ps, { a: 2, b: 5, c: 3 }, 1, 'brl')).toBeNull();
  });
  test('phase line counts for releases', () => {
    expect(phaseLineCounts([{ phaseId: 'a', quantity: 2 }, { phaseId: 'b', quantity: 1 }, { phaseId: 'a', quantity: 1 }]))
      .toEqual({ a: 3, b: 1 });
    expect(phaseLineCounts(null)).toEqual({});
  });
  test('phaseSoldDelta releases / re-adds from the read counters, never below 0', () => {
    const lines = [{ phaseId: 'a', quantity: 2 }, { phaseId: 'b', quantity: 1 }];
    expect(phaseSoldDelta({ phaseSold: { a: 2, b: 3 } }, lines, -1)).toEqual({ phaseSold: { a: 0, b: 2 } });
    expect(phaseSoldDelta({ phaseSold: { a: 1 } }, lines, -1)).toEqual({ phaseSold: { a: 0, b: 0 } });
    expect(phaseSoldDelta({}, lines, 1)).toEqual({ phaseSold: { a: 2, b: 1 } });
    expect(phaseSoldDelta({ phaseSold: { a: 1 } }, null, -1)).toEqual({});
  });
});

describe('editing after sales start', () => {
  const ps = phases(THREE);
  const locks = { a: 2000, b: 3000 };
  test('unchanged setup with sales is fine', () => {
    expect(phaseEditError(ps, { a: 2, b: 1 }, locks, 'brl')).toBeNull();
  });
  test('a phase with sales cannot be removed', () => {
    expect(phaseEditError(phases([THREE[1], THREE[2]]), { a: 2 }, locks, 'brl')).toBe('phase_with_sales_removed');
  });
  test('its price cannot change', () => {
    expect(phaseEditError(phases([P('a', 'earlyBird', 22, 2), THREE[1], THREE[2]]), { a: 1 }, locks, 'brl'))
      .toBe('phase_with_sales_price_changed');
  });
  test('its quantity cannot go below what it sold', () => {
    expect(phaseEditError(phases([P('a', 'earlyBird', 20, 1), THREE[1], THREE[2]]), { a: 2 }, locks, 'brl'))
      .toBe('phase_quantity_below_sold');
  });
  test('a phase without sales can be edited / removed', () => {
    expect(phaseEditError(phases([THREE[0], P('b', 'regular', 35, 9)]), { a: 2 }, { a: 2000 }, 'brl')).toBeNull();
    expect(phaseEditError(phases([THREE[0]]), { a: 2, b: 0 }, locks, 'brl')).toBeNull();
  });
  test('new phases go after the last phase that sold', () => {
    const inserted = phases([THREE[0], P('n', 'presale', 25, 2), THREE[1], THREE[2]]);
    expect(phaseEditError(inserted, { a: 2, b: 1 }, locks, 'brl')).toBe('phase_inserted_before_sold');
    const appended = phases([...THREE, P('n', 'door', 50, 2)]);
    expect(phaseEditError(appended, { a: 2, b: 1 }, locks, 'brl')).toBeNull();
    // A released phase that sold before (has a lock) is not "new".
    expect(phaseEditError(ps, { a: 0, b: 2 }, locks, 'brl')).toBeNull();
  });
});

describe('GreenGo fee per ticket on each ticket\'s own phase price (seller pays)', () => {
  test('lines per phase', () => {
    const lines = allocatePhases(phases(THREE), {}, 3, 'brl')!;
    const fee = computeOrderFee('gold', 'brl', lines.map((x) => ({ typeId: null, phaseId: x.phaseId, unitAmount: x.unitAmount, quantity: x.quantity })))!;
    const fa = feePerTicket('gold', 2000, 'brl')!;
    const fb = feePerTicket('gold', 3000, 'brl')!;
    expect(fa).not.toBe(fb);
    expect(fee.ticketSubtotal).toBe(2 * 2000 + 3000);
    expect(fee.total).toBe(fee.ticketSubtotal); // the buyer pays the ticket prices only
    expect(fee.feeTotal).toBe(2 * fa + fb);
    expect(fee.feePerTicket).toBeNull();
    expect(fee.hostNet).toBe(fee.ticketSubtotal - fee.feeTotal);
    expect(fee.lines.map((l) => l.phaseId)).toEqual(['a', 'b']);
  });
});

describe('preset names for provider checkout lines', () => {
  test('localized with English fallback', () => {
    expect(phaseName('earlyBird', 'en')).toBe('Early bird');
    expect(phaseName('door', 'pt-BR')).toBe('Na porta');
    expect(phaseName('presale', 'xx')).toBe('Presale');
    expect(phaseName('nope', 'de')).toBe('Ticket');
  });
});
