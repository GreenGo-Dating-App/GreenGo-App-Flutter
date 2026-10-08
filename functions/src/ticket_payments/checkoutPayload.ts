/**
 * Ticket payments — the exact Stripe Checkout / Mercado Pago preference
 * payloads (pure, unit-tested). Everything is built SERVER-SIDE from the
 * listing / booking doc at checkout time: the organizer never creates
 * products or prices in their dashboard, listing edits apply to the next
 * checkout, and nothing the client sends (title, price, image) is used.
 */
import { toMajor } from './currency';

export interface CheckoutInput {
  orderId: string;
  listingKind: 'event' | 'experience';
  listingId: string;
  /** Listing title (+ slot / ticket type), from the server doc. */
  title: string;
  /** Date/time (organizer time zone) + place + slot, from the server doc. */
  description: string | null;
  /** Public https cover image or null. */
  imageUrl: string | null;
  unitAmount: number;
  quantity: number;
  currency: string;
  successUrl: string;
  cancelUrl: string;
  pendingUrl?: string;
  notificationUrl?: string;
  expiresAtMs: number;
  nowMs: number;
  buyerEmail?: string | null;
  /** Buyer UI language (validated against the provider list). */
  locale?: string | null;
  /** Stripe only: ['card'] or ['card', 'pix']. */
  paymentMethodTypes?: string[];
  /** Event ticket types: one line per type (else one line from title/unitAmount/quantity). */
  lines?: CheckoutLine[];
}

export interface CheckoutLine {
  typeId: string;
  name: string;
  description: string | null;
  unitAmount: number;
  quantity: number;
}

function linesOf(i: CheckoutInput): CheckoutLine[] {
  if (i.lines && i.lines.length) return i.lines;
  return [{ typeId: i.listingId, name: i.title, description: i.description, unitAmount: i.unitAmount, quantity: i.quantity }];
}

function totalQty(i: CheckoutInput): number {
  return linesOf(i).reduce((s, l) => s + l.quantity, 0);
}

const clip = (s: string, n: number) => (s.length > n ? `${s.slice(0, n - 1)}…` : s);

/** Printable ASCII without the characters card networks reject. */
export function asciiDescriptor(s: string): string {
  return s
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^A-Za-z0-9 .-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Stripe statement_descriptor_suffix: the full descriptor is "<prefix>* <suffix>"
 * capped at 22 chars, so the suffix is kept to 22 and must contain a letter.
 */
export function statementSuffix(title: string, max = 22): string {
  const s = asciiDescriptor(`GG ${title}`).slice(0, max).trim();
  return /[A-Za-z]/.test(s) ? s : 'GG TICKET';
}

export function publicImage(url: unknown): string | null {
  return typeof url === 'string' && /^https:\/\/[^\s]{4,2000}$/.test(url) ? url : null;
}

const STRIPE_LOCALES = new Set(['auto', 'bg', 'cs', 'da', 'de', 'el', 'en', 'en-GB', 'es', 'es-419', 'et', 'fi',
  'fil', 'fr', 'fr-CA', 'hr', 'hu', 'id', 'it', 'ja', 'ko', 'lt', 'lv', 'ms', 'mt', 'nb', 'nl', 'pl', 'pt',
  'pt-BR', 'ro', 'ru', 'sk', 'sl', 'sv', 'th', 'tr', 'vi', 'zh', 'zh-HK', 'zh-TW']);

export function stripeLocale(locale: unknown): string {
  if (typeof locale !== 'string' || !locale) return 'auto';
  const norm = locale.replace('_', '-');
  if (STRIPE_LOCALES.has(norm)) return norm;
  const base = norm.split('-')[0];
  return STRIPE_LOCALES.has(base) ? base : 'auto';
}

/** Human date/time in the organizer's zone (falls back to UTC). */
export function whenText(startMs: number | null, timeZone: string | null, locale = 'en-GB'): string | null {
  if (startMs === null) return null;
  const opts: Intl.DateTimeFormatOptions = { dateStyle: 'medium', timeStyle: 'short', timeZone: timeZone || 'UTC' };
  try {
    return `${new Date(startMs).toLocaleString(locale, opts)}${timeZone ? '' : ' UTC'}`;
  } catch {
    return `${new Date(startMs).toLocaleString(locale, { ...opts, timeZone: 'UTC' })} UTC`;
  }
}

export function stripeSessionParams(i: CheckoutInput, types: string[]): Record<string, any> {
  const title = clip(i.title.trim() || 'Ticket', 250);
  const meta = { orderId: i.orderId, listingKind: i.listingKind, listingId: i.listingId, greengo: 'ticket' };
  return {
    mode: 'payment',
    payment_method_types: types,
    line_items: linesOf(i).map((l) => {
      const desc = [l.description, i.lines && i.lines.length ? i.description : null].filter(Boolean).join(' · ');
      return {
        quantity: l.quantity,
        price_data: {
          currency: i.currency,
          unit_amount: l.unitAmount,
          product_data: {
            name: clip(l.name.trim() || title, 250),
            ...(desc ? { description: clip(desc, 500) } : {}),
            ...(i.imageUrl ? { images: [i.imageUrl] } : {}),
          },
        },
      };
    }),
    client_reference_id: i.orderId,
    metadata: meta,
    payment_intent_data: {
      metadata: meta,
      description: clip(`${title} × ${totalQty(i)}`, 1000),
      statement_descriptor_suffix: statementSuffix(title),
    },
    success_url: i.successUrl,
    cancel_url: i.cancelUrl,
    // Stripe: at least 30 minutes after creation.
    expires_at: Math.floor(Math.max(i.expiresAtMs, i.nowMs + 30 * 60000 + 30000) / 1000),
    locale: stripeLocale(i.locale),
    ...(i.buyerEmail ? { customer_email: i.buyerEmail } : {}),
  };
}

/** Pix + cards + MP balance; no boleto ("ticket") or ATM. Guest checkout allowed (no `purpose`). */
export function mpPreferenceBody(i: CheckoutInput): Record<string, any> {
  return {
    items: linesOf(i).map((l) => {
      const desc = [l.description, i.lines && i.lines.length ? i.description : null].filter(Boolean).join(' · ');
      return {
        id: i.lines && i.lines.length ? `${i.listingId}_${l.typeId}`.slice(0, 250) : i.listingId,
        title: clip(l.name.trim() || i.title.trim() || 'Ticket', 250),
        ...(desc ? { description: clip(desc, 250) } : {}),
        ...(i.imageUrl ? { picture_url: i.imageUrl } : {}),
        category_id: 'tickets',
        quantity: l.quantity,
        currency_id: i.currency.toUpperCase(),
        unit_price: toMajor(l.unitAmount, i.currency),
      };
    }),
    ...(i.buyerEmail ? { payer: { email: i.buyerEmail } } : {}),
    external_reference: i.orderId,
    metadata: { order_id: i.orderId, listing_kind: i.listingKind, listing_id: i.listingId, greengo: 'ticket' },
    statement_descriptor: asciiDescriptor(`GREENGO ${i.title}`).slice(0, 22).trim(),
    notification_url: i.notificationUrl,
    back_urls: { success: i.successUrl, failure: i.cancelUrl, pending: i.pendingUrl ?? i.successUrl },
    auto_return: 'approved',
    expires: true,
    expiration_date_from: new Date(i.nowMs - 60000).toISOString(),
    expiration_date_to: new Date(i.expiresAtMs).toISOString(),
    date_of_expiration: new Date(i.expiresAtMs).toISOString(),
    payment_methods: { excluded_payment_types: [{ id: 'ticket' }, { id: 'atm' }] },
  };
}
