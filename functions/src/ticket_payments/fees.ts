/**
 * Ticket payments — the GreenGo service fee (pure, unit-tested). Mirrored for
 * DISPLAY ONLY by lib/features/ticket_payments/domain/ticket_fees.dart; this
 * file is authoritative (createTicketCheckout prices every order with it).
 *
 * Owner rule 2026-10-14, changed the same day: the fee is PAID BY THE SELLER.
 * The buyer pays the listed ticket price only; GreenGo keeps its fee out of
 * that price (Stripe application_fee_amount / Mercado Pago marketplace_fee on
 * the host's direct charge), so the host receives ticket price - fee (minus
 * the provider's own processing fee), per ticket:
 *
 *   rule       fixed   + percent of the ticket price   cap per ticket
 *   silver     US$ 3   + 10 %                          US$ 30
 *   gold       US$ 2   + 10 %                          US$ 28
 *   platinum   US$ 1   + 10 %                          US$ 25  (TEST = platinum)
 *   trial      flat US$ 1 (the host's first paid listing, see below)
 *   (caps raised 2026-10-16 by the owner; they were US$ 10 / 9 / 8)
 *   free ticket (price 0): no fee.
 *   The fee never exceeds the ticket price itself (a fee can't be larger
 *   than the charge it is taken from).
 *
 * The rule follows the HOST's effective tier at checkout time
 * (shared/effectiveTier.ts). A host without an active paid tier (FREE / Base)
 * pays the Silver rule: the most conservative one.
 *
 * Trial ("first paid event $1"): the FIRST paid listing (event OR
 * experience) of a host on which any buyer opens a paid checkout, provided the
 * host has no earlier paid ticket order. It is claimed once, server-side, in
 * payment_accounts/{hostId}.feeTrial = { key: '<kind>_<listingId>', claimedAt }
 * inside the checkout transaction, and never moves afterwards: every later
 * order of THAT listing keeps the $1 fee for the life of the listing, every
 * other listing pays the tier rule. A host who already sold paid tickets
 * before the fee existed gets { key: null } (no trial).
 *
 * Currency: the fixed part and the cap are US$; tickets may be priced in other
 * currencies. They are converted with USD_RATES (a FIXED table, units of the
 * currency per 1 US$, owner-maintained, see below) and rounded to the
 * currency's minor unit. The 10 % is taken on the ticket price in its own
 * currency (no conversion). Unknown currency -> null (checkout refused with
 * `fee_currency_unsupported`).
 */
import { exponentOf } from './currency';

export type FeeRule = 'trial' | 'silver' | 'gold' | 'platinum';

export interface FeeSchedule {
  /** Fixed part per ticket, US$ cents. */
  fixedUsdCents: number;
  /** Percent of the ticket price (in the ticket currency). */
  percent: number;
  /** Max fee per ticket, US$ cents (null = no cap, e.g. the flat trial). */
  capUsdCents: number | null;
}

export const FEE_SCHEDULES: Record<FeeRule, FeeSchedule> = {
  silver: { fixedUsdCents: 300, percent: 10, capUsdCents: 3000 },
  gold: { fixedUsdCents: 200, percent: 10, capUsdCents: 2800 },
  platinum: { fixedUsdCents: 100, percent: 10, capUsdCents: 2500 },
  trial: { fixedUsdCents: 100, percent: 0, capUsdCents: null },
};

/**
 * OWNER: UPDATE THESE RATES. Units of each currency per 1 US$ (mid-market,
 * approximate, 2026-10). Only the fixed part and the cap of the fee are
 * converted, so a few % of drift moves a fee by cents. Lower-case ISO 4217.
 * Must stay in sync with kUsdRates in lib/features/ticket_payments/domain/ticket_fees.dart.
 */
export const USD_RATES: Record<string, number> = {
  usd: 1, eur: 0.92, gbp: 0.79, brl: 5.5, jpy: 150, aud: 1.52, cad: 1.37, chf: 0.88,
  czk: 23, dkk: 6.9, hkd: 7.8, huf: 360, inr: 84, mxn: 18.5, myr: 4.5, nok: 10.8,
  nzd: 1.66, pln: 4, ron: 4.6, sek: 10.5, sgd: 1.34, thb: 35, aed: 3.67, bgn: 1.8,
  ars: 1000, clp: 940, cop: 4100, pen: 3.75, uyu: 40, krw: 1380,
};

/** Tier (shared/effectiveTier.ts EffectiveTier) -> fee rule. */
export function feeRuleForTier(tier: string | null | undefined, trial: boolean): FeeRule {
  if (trial) return 'trial';
  switch ((tier || '').toUpperCase()) {
    case 'PLATINUM':
    case 'TEST':
      return 'platinum';
    case 'GOLD':
      return 'gold';
    default:
      return 'silver';
  }
}

/** US$ cents -> minor units of [currency] (rounded half up); null when no rate. */
export function usdCentsToMinor(usdCents: number, currency: string): number | null {
  const rate = USD_RATES[currency.toLowerCase()];
  if (rate === undefined) return null;
  const major = (usdCents / 100) * rate;
  const f = 10 ** exponentOf(currency);
  return Math.round(Number((major * f).toFixed(6)));
}

/**
 * Fee for ONE ticket of [unitAmount] minor units of [currency] under [rule].
 * 0 for a free ticket; null when the currency has no rate.
 */
export function feePerTicket(rule: FeeRule, unitAmount: number, currency: string): number | null {
  if (!(unitAmount > 0)) return 0;
  const s = FEE_SCHEDULES[rule];
  const fixed = usdCentsToMinor(s.fixedUsdCents, currency);
  if (fixed === null) return null;
  const pct = Math.round((unitAmount * s.percent) / 100);
  const raw = fixed + pct;
  const capped = s.capUsdCents === null ? raw : Math.min(raw, usdCentsToMinor(s.capUsdCents, currency) as number);
  return Math.min(capped, unitAmount);
}

/** One priced line: a ticket type, a price phase ([phaseId]) or the single general ticket. */
export interface FeeLine { typeId: string | null; phaseId?: string; unitAmount: number; quantity: number }

export interface FeeBreakdown {
  rule: FeeRule;
  currency: string;
  /** Sum of the ticket prices = what the buyer pays, minor units. */
  ticketSubtotal: number;
  /** GreenGo service fee for the whole order (paid by the seller), minor units. */
  feeTotal: number;
  /** Fee per ticket when every paid ticket has the same fee, else null (see lines). */
  feePerTicket: number | null;
  /** What the buyer pays: ticketSubtotal (the fee is not added on top). */
  total: number;
  /** What the host receives before the provider's processing fee: ticketSubtotal - feeTotal. */
  hostNet: number;
  lines: Array<FeeLine & { unitFee: number }>;
}

/** Whole-order fee; null when the currency has no rate and a fee is due. */
export function computeOrderFee(rule: FeeRule, currency: string, lines: FeeLine[]): FeeBreakdown | null {
  const out: FeeBreakdown['lines'] = [];
  let subtotal = 0;
  let fee = 0;
  for (const l of lines) {
    const unitFee = feePerTicket(rule, l.unitAmount, currency);
    if (unitFee === null) return null;
    out.push({ ...l, unitFee });
    subtotal += l.unitAmount * l.quantity;
    fee += unitFee * l.quantity;
  }
  const paidFees = new Set(out.filter((l) => l.unitAmount > 0).map((l) => l.unitFee));
  return {
    rule,
    currency: currency.toLowerCase(),
    ticketSubtotal: subtotal,
    feeTotal: fee,
    feePerTicket: paidFees.size === 0 ? 0 : (paidFees.size === 1 ? Array.from(paidFees)[0] : null),
    total: subtotal,
    hostNet: subtotal - fee,
    lines: out,
  };
}

/** Trial key of a listing in payment_accounts/{hostId}.feeTrial.key. */
export function trialKey(kind: 'event' | 'experience', listingId: string): string {
  return `${kind}_${listingId}`;
}

/**
 * Does the trial apply to [key]? [claim] = payment_accounts.feeTrial (undefined
 * when never decided). [hasEarlierPaidOrder] is only consulted when undefined.
 * Returns the decision and the claim to store (null = nothing to write).
 */
export function resolveTrial(
  claim: { key?: string | null } | null | undefined,
  key: string,
  hasEarlierPaidOrder: boolean,
): { trial: boolean; store: { key: string | null } | null } {
  if (claim && typeof claim === 'object' && 'key' in claim) {
    return { trial: claim.key === key, store: null };
  }
  if (hasEarlierPaidOrder) return { trial: false, store: { key: null } };
  return { trial: true, store: { key } };
}

/** What the app shows before checkout (the server re-prices at checkout). */
export function feeQuote(rule: FeeRule, currency: string | null): Record<string, unknown> {
  const s = FEE_SCHEDULES[rule];
  const c = currency ? currency.toLowerCase() : null;
  return {
    rule,
    fixedUsdCents: s.fixedUsdCents,
    percent: s.percent,
    capUsdCents: s.capUsdCents,
    currency: c,
    usdRate: c ? USD_RATES[c] ?? null : null,
  };
}
