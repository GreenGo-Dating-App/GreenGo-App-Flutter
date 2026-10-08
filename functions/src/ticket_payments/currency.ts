/**
 * Ticket payments — currency rules (pure, unit-tested).
 *
 *  - Amounts are integer MINOR units + lower-case ISO 4217, always computed on
 *    the server from the listing / booking doc.
 *  - Stripe: unit_amount in minor units (zero-decimal currencies such as JPY,
 *    KRW, CLP have no cents). Minimum charge per currency (Stripe table).
 *    Pix only for BRL on a Brazilian connected account.
 *  - Mercado Pago: unit_price as a decimal number + currency_id, and ONLY the
 *    site currency of the organizer's MP account. Minimum 1.00 (local).
 *  - Link mode: any currency (the organizer confirms).
 */
import { TicketProvider } from './config';

/** Currencies without a minor unit (Stripe "zero-decimal"). */
export const ZERO_DECIMAL = new Set(['bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga', 'pyg', 'rwf',
  'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf']);

export function exponentOf(currency: string): number {
  return ZERO_DECIMAL.has(currency.toLowerCase()) ? 0 : 2;
}

/** Major units (as stored on listings, e.g. 49.9) -> integer minor units. */
export function toMinor(major: number, currency: string): number {
  const f = 10 ** exponentOf(currency);
  // toFixed first: 19.99 * 100 = 1998.9999999999998 must become 1999.
  return Math.round(Number((major * f).toFixed(6)));
}

/** Minor units -> major units (MP unit_price, display). */
export function toMajor(minor: number, currency: string): number {
  return minor / 10 ** exponentOf(currency);
}

/** Mercado Pago site -> the only currency that site charges in. */
export const MP_SITE_CURRENCY: Record<string, string> = {
  MLB: 'brl', MLA: 'ars', MLM: 'mxn', MLC: 'clp', MCO: 'cop', MPE: 'pen', MLU: 'uyu',
};

export function mpCurrencyForSite(siteId: unknown): string | null {
  return typeof siteId === 'string' ? MP_SITE_CURRENCY[siteId.toUpperCase()] ?? null : null;
}

/** Stripe minimum charge amounts, in MAJOR units (stripe.com/docs/currencies#minimum-and-maximum-charge-amounts). */
export const STRIPE_MIN_MAJOR: Record<string, number> = {
  usd: 0.5, aed: 2, aud: 0.5, bgn: 1, brl: 0.5, cad: 0.5, chf: 0.5, czk: 15, dkk: 2.5, eur: 0.5,
  gbp: 0.3, hkd: 4, huf: 175, inr: 0.5, jpy: 50, mxn: 10, myr: 2, nok: 3, nzd: 0.5, pln: 2,
  ron: 2, sek: 3, sgd: 0.5, thb: 10,
};
/** Mercado Pago: 1.00 in the local currency. */
export const MP_MIN_MAJOR = 1;

/** Minimum charge in MINOR units for [provider] + [currency]; 0 = no known minimum. */
export function minimumMinor(provider: TicketProvider, currency: string): number {
  const c = currency.toLowerCase();
  if (provider === 'stripe') {
    const m = STRIPE_MIN_MAJOR[c];
    return m === undefined ? 0 : toMinor(m, c);
  }
  if (provider === 'mercadopago') return toMinor(MP_MIN_MAJOR, c);
  return 0;
}

export type CurrencyCheck =
  | { ok: true }
  | { ok: false; reason: 'currency_not_supported'; expected: string | null }
  | { ok: false; reason: 'amount_below_minimum'; minimum: number };

/**
 * Validates a charge before a checkout is created.
 * [mpCurrency] = the organizer's MP account currency (from the site id).
 */
export function checkCharge(
  provider: TicketProvider,
  currency: string,
  unitAmountMinor: number,
  mpCurrency: string | null,
): CurrencyCheck {
  const c = currency.toLowerCase();
  if (provider === 'mercadopago') {
    if (!mpCurrency || mpCurrency !== c) return { ok: false, reason: 'currency_not_supported', expected: mpCurrency };
  }
  const min = minimumMinor(provider, c);
  if (min > 0 && unitAmountMinor < min) return { ok: false, reason: 'amount_below_minimum', minimum: min };
  return { ok: true };
}

/** Stripe Checkout payment methods: Pix only for BRL on a Brazilian account. */
export function stripePaymentMethodTypes(currency: string, accountCountry: string | null): string[] {
  return currency.toLowerCase() === 'brl' && (accountCountry || '').toUpperCase() === 'BR'
    ? ['card', 'pix']
    : ['card'];
}
