/**
 * Ticket payments — orders, tickets and seat holds, for BOTH modes:
 *
 *  A) "link" (default, zero setup): the organizer's own payment method
 *     (Profile > Payment methods key, or cash / bank transfer). The buyer gets a
 *     short code (GG-XXXXXX) to put in the payment description, pays outside
 *     GreenGo, taps "I've paid" (optional receipt image), and the ORGANIZER
 *     confirms or rejects. GreenGo does not verify link payments.
 *       pending_payment -> awaiting_confirmation -> paid | rejected | expired
 *  B) "instant": connected Stripe / Mercado Pago; the provider webhook confirms.
 *       creating -> pending -> paid | expired | cancelled | failed
 *  then paid -> refunded | disputed (provider webhook).
 *
 * The QR (tickets/{id}) exists ONLY once the order is paid, in both modes.
 *
 * ticket_orders/{orderId}   server-only writes; buyer + organizer read.
 *   kind 'event' | 'experience', listingId, bookingId, buyerId, organizerId,
 *   provider 'stripe' | 'mercadopago' | 'link', mode 'instant' | 'link',
 *   quantity, unitAmount, totalAmount (minor units FROM THE SERVER-SIDE LISTING /
 *   BOOKING, never the client), currency, status, expiresAt (hold end),
 *   code (link), payment { method, value, instructions } (link snapshot),
 *   receiptPath, sentAt, remindAt, rejectReason, checkoutUrl, providerRef,
 *   seatHeld, ticketId, title, startsAt, platform, createdAt, updatedAt, paidAt
 * tickets/{ticketId = orderId}  server-only; ONLY the buyer reads (holds the QR).
 * ticket_codes/{code}  server-only: code uniqueness ({ orderId }).
 * ticket_inventory/event_{eventId}  server-only: { held } seats held by open
 *   orders. Capacity = attendeeCount (server-maintained for paid events) + held.
 * payment_events/{provider}_{eventId}  webhook idempotency.
 *
 * Experiences: the booking (status confirmed, payment.mode 'online') already
 * holds the seat; the order tracks the payment. When paid the booking gets
 * payment.status 'paid' and the QR is released.
 */
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { HttpsError } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import * as cfg from './config';
import { COL, TicketProvider, isProvider, isTicketProvider } from './config';
import { accountReady, clientPlatform, fail, mpAccessTokenFor, returnUrl } from './accounts';
import {
  ProviderError,
  mpCreatePreference,
  mpSearchPayments,
  stripeCreateCheckout,
  stripeExpireSession,
  stripeRetrieveSession,
  stripeRefund,
  mpRefund,
  ticketDeps,
  toMajor,
  toMinor,
} from './providers';
import { ticketQrPayload } from './tokens';
import { ticketKey } from './keys';
import { checkCharge, stripePaymentMethodTypes } from './currency';
import { CheckoutInput, publicImage, whenText } from './checkoutPayload';
import { emitNotification } from '../notifications/notifyHelpers';
import { lt, rawText } from '../shared/i18n';

const db = () => admin.firestore();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const now = () => ticketDeps.now();
const HOUR = 3600 * 1000;
const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

export const OPEN_STATUSES = ['creating', 'pending', 'pending_payment', 'awaiting_confirmation'] as const;
const OPEN = new Set<string>(OPEN_STATUSES);

export function msOf(v: unknown): number | null {
  if (v instanceof admin.firestore.Timestamp) return v.toMillis();
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  if (typeof v === 'string') { const t = Date.parse(v); return Number.isNaN(t) ? null : t; }
  if (v && typeof (v as any).toMillis === 'function') return (v as any).toMillis();
  return null;
}

const SYMBOLS: Record<string, string> = { '$': 'usd', 'us$': 'usd', '€': 'eur', '£': 'gbp', 'r$': 'brl', '¥': 'jpy' };
export function isoCurrency(code: unknown, symbol: unknown): string | null {
  for (const c of [code, symbol]) {
    if (typeof c !== 'string') continue;
    const v = c.trim().toLowerCase();
    if (/^[a-z]{3}$/.test(v)) return v;
    if (SYMBOLS[v]) return SYMBOLS[v];
  }
  return null;
}

/** Paid event = price > 0 or a ticket provider set (mirrors firestore.rules isPaidEvent). */
export function isPaidEvent(ev: Record<string, any> | undefined | null): boolean {
  if (!ev) return false;
  const p = ev.price;
  return (typeof p === 'number' && p > 0) || ev.ticketProvider != null;
}

export function inventoryRef(eventId: string) {
  return db().collection(COL.inventory).doc(`event_${eventId}`);
}

/** Human payment reference: GG- + 6 chars without 0/O, 1/I/L, U. */
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTVWXYZ23456789';
export function newPaymentCode(): string {
  const b = crypto.randomBytes(6);
  let s = '';
  for (let i = 0; i < 6; i++) s += CODE_ALPHABET[b[i] % CODE_ALPHABET.length];
  return `GG-${s}`;
}
export const PAYMENT_CODE_RE = /^GG-[ABCDEFGHJKMNPQRSTVWXYZ2-9]{6}$/;

export interface OrderLine {
  typeId: string;
  name: string;
  description: string | null;
  unitAmount: number;
  quantity: number;
}

interface Listing {
  kind: 'event' | 'experience';
  listingId: string;
  bookingId: string | null;
  organizerId: string;
  provider: TicketProvider;
  linkMethod: string | null;
  instructions: string | null;
  unitAmount: number;
  /** Tickets in this order (per_group experiences: 1). */
  quantity: number;
  /** People per ticket (per_group experiences: the party size). */
  partySize: number;
  currency: string;
  title: string;
  startsAtMs: number | null;
  place: string | null;
  timeZone: string | null;
  imageUrl: string | null;
  limit: number | null;
  slotLabel: string | null;
}

function cleanInstructions(v: unknown): string | null {
  if (typeof v !== 'string') return null;
  const t = v.trim().slice(0, 500);
  return t.length ? t : null;
}

/** The method snapshot the buyer pays with (link mode), or a failure reason. */
export function linkPaymentSnapshot(
  method: string | null,
  profile: Record<string, any> | undefined,
  instructions: string | null,
): { method: string; value: string | null; instructions: string | null } | null {
  if (!method || !cfg.isLinkMethod(method)) return null;
  if (method === 'cash') return { method, value: null, instructions };
  if (method === 'bankTransfer') return instructions ? { method, value: null, instructions } : null;
  const raw = profile?.paymentLinks?.[method];
  const value = typeof raw === 'string' ? raw.trim() : '';
  if (!value || value.length > 300) return null;
  return { method, value, instructions };
}

// ─────────────────────────────────────────────────────────── create order / checkout

/** Per-user ticket limit of a listing: missing = default, null / 0 = none. */
export function perUserLimit(l: Record<string, any>): number | null {
  if (!('maxTicketsPerUser' in l)) return cfg.DEFAULT_MAX_TICKETS_PER_USER;
  const v = l.maxTicketsPerUser;
  if (v === null || v === 0) return null;
  return Number.isInteger(v) && v >= 1 && v <= 100 ? v : cfg.DEFAULT_MAX_TICKETS_PER_USER;
}

/** Per buyer + listing counter: { held (open orders), owned (paid) } in tickets. */
export function holdingsRef(kind: string, listingId: string, uid: string) {
  return db().collection(COL.holdings).doc(`${kind}_${listingId}_${uid}`);
}

export const TICKET_TYPES = 'ticket_types';
export const MAX_ORDER_ITEMS = 20;

/** Requested event items: [{ typeId, qty }] (merged, validated); null = legacy single type. */
export function parseItems(raw: unknown): Array<{ typeId: string; qty: number }> | null {
  if (raw === undefined || raw === null) return null;
  if (!Array.isArray(raw) || raw.length === 0 || raw.length > MAX_ORDER_ITEMS) fail('invalid-argument', 'invalid_items');
  const m = new Map<string, number>();
  for (const it of raw as any[]) {
    const id = it?.typeId;
    const q = it?.qty;
    if (typeof id !== 'string' || !ID_RE.test(id) || !Number.isInteger(q) || q < 0 || q > cfg.MAX_QUANTITY) {
      fail('invalid-argument', 'invalid_items');
    }
    if (q > 0) m.set(id, (m.get(id) || 0) + q);
  }
  if (m.size === 0) fail('invalid-argument', 'invalid_items');
  return Array.from(m.entries()).map(([typeId, qty]) => ({ typeId, qty }));
}

/** Can [t] be bought at [nowMs]? Returns a reason code or null. */
export function typeSaleError(t: Record<string, any> | undefined, nowMs: number): string | null {
  if (!t) return 'ticket_type_not_found';
  if (t.active === false || t.hidden === true) return 'ticket_type_unavailable';
  const s = msOf(t.salesStart);
  const e = msOf(t.salesEnd);
  if (s !== null && nowMs < s) return 'ticket_type_sales_not_started';
  if (e !== null && nowMs > e) return 'ticket_type_sales_ended';
  return null;
}

export function ticketIdsFor(orderId: string, quantity: number): string[] {
  return Array.from({ length: Math.max(1, quantity) }, (_, i) => `${orderId}_${i + 1}`);
}

/**
 * Buyer: data { kind: 'event' | 'experience', id, bookingId? (experience),
 * quantity? (event tickets), platform? 'app' | 'web', locale? }.
 * Instant -> { orderId, mode: 'instant', checkoutUrl, expiresAt, provider, amount, currency, quantity, reused }.
 * Link    -> { orderId, mode: 'link', code, amount, currency, payment, expiresAt, quantity, reused }.
 * Price, currency, title, description and image ALWAYS come from the
 * server-side listing / booking doc; client-sent values are ignored.
 */
export async function createTicketCheckout(uid: string, data: any, email: string | null): Promise<Record<string, unknown>> {
  const kind = data?.kind;
  const id = data?.id;
  if (kind !== 'event' && kind !== 'experience') fail('invalid-argument', 'invalid_kind');
  if (typeof id !== 'string' || !ID_RE.test(id)) fail('invalid-argument', 'invalid_id');
  const platform = clientPlatform(data?.platform);
  const locale = typeof data?.locale === 'string' ? data.locale.slice(0, 10) : null;
  const bookingId = kind === 'experience' ? data?.bookingId : null;
  if (kind === 'experience' && (typeof bookingId !== 'string' || !ID_RE.test(bookingId))) {
    fail('invalid-argument', 'invalid_booking_id');
  }
  const items = kind === 'event' ? parseItems(data?.items) : null;
  const reqQty = items ? items.reduce((s, i) => s + i.qty, 0) : (kind === 'event' ? (data?.quantity ?? 1) : 1);
  if (!Number.isInteger(reqQty) || reqQty < 1 || reqQty > cfg.MAX_QUANTITY) fail('invalid-argument', 'invalid_quantity');

  const orders = db().collection(COL.orders);
  const orderRef = orders.doc();
  const t0 = now();
  const codes = [newPaymentCode(), newPaymentCode(), newPaymentCode()];

  const res = await db().runTransaction(async (tx) => {
    const listingRef = kind === 'event'
      ? db().collection('events').doc(id)
      : db().collection('user_experiences').doc(id);
    const bookingRef = bookingId ? db().collection('bookings').doc(bookingId) : null;
    const invRef = kind === 'event' ? inventoryRef(id) : null;
    const holdRef = holdingsRef(kind, id, uid);
    const openQ = orders.where('buyerId', '==', uid).where('listingId', '==', id)
      .where('status', 'in', [...OPEN_STATUSES]).limit(5);
    const typeRefs = items ? items.map((i) => listingRef.collection(TICKET_TYPES).doc(i.typeId)) : [];
    const [lSnap, bSnap, invSnap, holdSnap, openSnap, ...typeSnaps] = await Promise.all([
      tx.get(listingRef),
      bookingRef ? tx.get(bookingRef) : Promise.resolve(null),
      invRef ? tx.get(invRef) : Promise.resolve(null),
      tx.get(holdRef),
      tx.get(openQ),
      ...typeRefs.map((r) => tx.get(r)),
    ]) as any[];
    if (!lSnap.exists) fail('not-found', 'listing_not_found');
    const l = lSnap.data() as Record<string, any>;

    let listing: Listing;
    let lines: OrderLine[] | null = null;
    if (kind === 'event') {
      // Ticket types: price, sales window, per-type stock and per-type limit
      // all from the server docs; the client only says which types and how many.
      if (items) {
        const cur0 = isoCurrency(l.currencyCode, l.currency);
        if (!cur0) fail('failed-precondition', 'currency_missing');
        const hTypes = (holdSnap.data()?.types || {}) as Record<string, any>;
        lines = items.map((it, idx) => {
          const t = typeSnaps[idx].data() as Record<string, any> | undefined;
          const err = typeSaleError(t, t0);
          if (err) fail('failed-precondition', err, { typeId: it.typeId });
          const price = Number(t!.price);
          if (!Number.isSafeInteger(price) || price < 0) fail('failed-precondition', 'invalid_price', { typeId: it.typeId });
          const cap = t!.quantity === null || t!.quantity === undefined ? null : Number(t!.quantity);
          const used = (Number(t!.sold) || 0) + (Number(t!.held) || 0);
          if (cap !== null && used + it.qty > cap) {
            fail('resource-exhausted', 'ticket_type_sold_out', { typeId: it.typeId, remaining: Math.max(0, cap - used) });
          }
          const per = Number.isInteger(t!.maxPerUser) && t!.maxPerUser > 0 ? t!.maxPerUser : null;
          const mine = (Number(hTypes[it.typeId]?.held) || 0) + (Number(hTypes[it.typeId]?.owned) || 0);
          if (per !== null && mine + it.qty > per) {
            fail('failed-precondition', 'ticket_type_limit_reached', { typeId: it.typeId, remaining: Math.max(0, per - mine) });
          }
          return {
            typeId: it.typeId, name: String(t!.name || 'Ticket').slice(0, 80),
            description: typeof t!.description === 'string' ? t!.description.slice(0, 300) : null,
            unitAmount: price, quantity: it.qty,
          };
        });
      }
      if (!lines && !(typeof l.price === 'number' && l.price > 0)) fail('failed-precondition', 'not_paid_listing');
      if (!isTicketProvider(l.ticketProvider)) fail('failed-precondition', 'organizer_payments_not_ready');
      if (l.status === 'cancelled' || l.status === 'draft') fail('failed-precondition', 'listing_not_on_sale');
      const end = msOf(l.endDate) ?? msOf(l.startDate);
      if (end !== null && end < t0) fail('failed-precondition', 'listing_ended');
      if (l.organizerId === uid) fail('failed-precondition', 'own_listing');
      const currency = isoCurrency(l.currencyCode, l.currency);
      if (!currency) fail('failed-precondition', 'currency_missing');
      const place = [l.locationName, l.address, l.city].filter((x) => typeof x === 'string' && x.trim()).join(', ');
      listing = {
        kind, listingId: id, bookingId: null, organizerId: String(l.organizerId), provider: l.ticketProvider,
        linkMethod: typeof l.ticketLinkMethod === 'string' ? l.ticketLinkMethod : null,
        instructions: cleanInstructions(l.ticketPaymentInstructions),
        unitAmount: lines ? Math.max(...lines.map((x) => x.unitAmount)) : toMinor(l.price, currency),
        quantity: reqQty, partySize: 1, currency,
        title: String(l.title || 'Event'), startsAtMs: msOf(l.startDate),
        place: place || null, timeZone: typeof l.timeZone === 'string' ? l.timeZone : null,
        imageUrl: publicImage(l.imageUrl), limit: perUserLimit(l), slotLabel: null,
      };
    } else {
      const b = bSnap?.data() as Record<string, any> | undefined;
      if (!b || b.experienceId !== id) fail('not-found', 'booking_not_found');
      if (b.guestId !== uid) fail('permission-denied', 'not_guest');
      if (b.status !== 'confirmed') fail('failed-precondition', 'not_confirmed', { status: b.status });
      if (b.payment?.mode !== 'online' || !isTicketProvider(b.payment?.provider)) fail('failed-precondition', 'not_paid_listing');
      if (b.payment?.status === 'paid') fail('already-exists', 'already_has_ticket');
      const start = msOf(b.slotStart);
      if (start !== null && start < t0) fail('failed-precondition', 'listing_ended');
      const currency = String(b.price?.currency || '').toLowerCase();
      if (!/^[a-z]{3}$/.test(currency) || !(b.price?.totalAmount > 0)) fail('failed-precondition', 'currency_missing');
      const guests = Math.max(1, Number(b.guests) || 1);
      const perGroup = b.pricingMode === 'per_group';
      const maxG = Number(b.maxGroupSize ?? l.maxGroupSize) || guests;
      const place = [l.meetingPoint, l.locationName, l.city].filter((x) => typeof x === 'string' && x.trim()).join(', ');
      listing = {
        kind, listingId: id, bookingId, organizerId: String(b.hostId), provider: b.payment.provider,
        linkMethod: typeof b.payment.linkMethod === 'string' ? b.payment.linkMethod : (typeof l.paymentLinkMethod === 'string' ? l.paymentLinkMethod : null),
        instructions: cleanInstructions(l.paymentInstructions),
        // per_person: one ticket per guest at the unit price; per_group: ONE
        // group ticket at the fixed group price, whatever the party size.
        unitAmount: perGroup ? Number(b.price.totalAmount) : Number(b.price.unitAmount),
        quantity: perGroup ? 1 : guests,
        partySize: perGroup ? guests : 1,
        currency,
        title: perGroup
          ? `${String(b.experienceTitle || l.title || 'Experience')} – group of up to ${maxG}`
          : String(b.experienceTitle || l.title || 'Experience'),
        startsAtMs: start,
        place: place || null, timeZone: typeof l.timeZone === 'string' ? l.timeZone : null,
        imageUrl: publicImage(l.mainPhotoUrl), limit: perUserLimit(l),
        slotLabel: perGroup ? `Party of ${guests}` : null,
      };
    }
    const totalAmount = lines
      ? lines.reduce((s, x) => s + x.unitAmount * x.quantity, 0)
      : listing.unitAmount * listing.quantity;
    const isFreeOrder = !!lines && totalAmount === 0;
    if (!isFreeOrder && (!Number.isSafeInteger(listing.unitAmount) || listing.unitAmount <= 0)) fail('failed-precondition', 'invalid_price');
    if (isFreeOrder) listing.provider = 'free' as any;

    // Readiness of the organizer's payment setup.
    let payment: ReturnType<typeof linkPaymentSnapshot> = null;
    let stripeCountry: string | null = null;
    const codeSnaps = listing.provider === 'link'
      ? await Promise.all(codes.map((c) => tx.get(db().collection(COL.codes).doc(c))))
      : [];
    if (isFreeOrder) {
      // Only free ticket types: no payment, the tickets are issued right away.
    } else if (listing.provider === 'link') {
      const prof = (await tx.get(db().collection('profiles').doc(listing.organizerId))).data();
      payment = linkPaymentSnapshot(listing.linkMethod, prof, listing.instructions);
      if (!payment) fail('failed-precondition', 'organizer_payments_not_ready', { provider: 'link' });
    } else {
      const acct = (await tx.get(db().collection(COL.accounts).doc(listing.organizerId))).data();
      if (!isProvider(listing.provider) || !cfg.providerConfigured(listing.provider) || !accountReady(acct, listing.provider)) {
        fail('failed-precondition', 'organizer_payments_not_ready', { provider: listing.provider });
      }
      stripeCountry = acct?.stripe?.country ?? null;
      const minUnit = lines ? Math.min(...lines.filter((x) => x.unitAmount > 0).map((x) => x.unitAmount)) : listing.unitAmount;
      const chk = checkCharge(listing.provider as any, listing.currency, minUnit, acct?.mercadoPago?.currency ?? null);
      if (chk.ok === false) {
        fail('failed-precondition', chk.reason, chk.reason === 'currency_not_supported'
          ? { expected: chk.expected, currency: listing.currency }
          : { minimum: chk.minimum, currency: listing.currency });
      }
    }

    // One live order per buyer + listing: reuse it while it is still usable,
    // otherwise supersede it (its holds are released in this transaction).
    let freedSeats = 0;
    let freedHolds = 0;
    const superseded: Array<Array<Record<string, any>>> = [];
    for (const d of openSnap.docs) {
      const o = d.data();
      if ((o.bookingId ?? null) !== (listing.bookingId ?? null)) continue;
      const exp = msOf(o.expiresAt) ?? 0;
      const sameShape = o.quantity === listing.quantity && o.provider === listing.provider
        && JSON.stringify(o.items ?? null) === JSON.stringify(lines ?? null);
      if (sameShape && o.provider === 'link' && exp > t0) return { reused: true, orderId: d.id, order: o, listing };
      if (sameShape && o.checkoutUrl && exp - t0 > 5 * 60000) return { reused: true, orderId: d.id, order: o, listing };
      tx.update(d.ref, { status: 'cancelled', cancelReason: 'superseded', seatHeld: false, updatedAt: ts(t0) });
      if (o.seatHeld) {
        freedHolds += Number(o.quantity) || 1;
        if (o.kind === 'event') freedSeats += Number(o.quantity) || 1;
        if (Array.isArray(o.items) && o.items.length) superseded.push(o.items);
      }
    }

    // Per-user limit: paid tickets + live holds (counter doc, race-safe).
    const h = holdSnap.data() || {};
    const heldNow = Math.max(0, (Number(h.held) || 0) - freedHolds);
    const owned = Math.max(0, Number(h.owned) || 0);
    if (listing.limit !== null && owned + heldNow + listing.quantity > listing.limit) {
      fail('failed-precondition', 'ticket_limit_reached', {
        limit: listing.limit, remaining: Math.max(0, listing.limit - owned - heldNow),
      });
    }
    if (kind === 'event') {
      const held = Math.max(0, (Number(invSnap?.data()?.held) || 0) - freedSeats);
      const max = Math.floor(Number(l.maxAttendees) || 0);
      const going = Math.max(0, Math.floor(Number(l.attendeeCount) || 0));
      if (max > 0 && going + held + listing.quantity > max) {
        fail('resource-exhausted', 'sold_out', { remaining: Math.max(0, max - going - held) });
      }
      tx.set(invRef!, { held: held + listing.quantity, updatedAt: ts(t0) }, { merge: true });
    }
    // Per-type stock + per-type per-user holds (superseded orders released first).
    const typesHold: Record<string, any> = { ...((holdSnap.data()?.types || {}) as Record<string, any>) };
    const freedByType = new Map<string, number>();
    for (const its of superseded) for (const x of its) freedByType.set(x.typeId, (freedByType.get(x.typeId) || 0) + Number(x.quantity || 0));
    if (lines) {
      lines.forEach((x, idx) => {
        const t = typeSnaps[idx].data() as Record<string, any>;
        const freed = freedByType.get(x.typeId) || 0;
        tx.update(typeRefs[idx], { held: Math.max(0, (Number(t.held) || 0) - freed) + x.quantity, updatedAt: ts(t0) });
        const cur = typesHold[x.typeId] || {};
        typesHold[x.typeId] = { held: Math.max(0, (Number(cur.held) || 0) - freed) + x.quantity, owned: Number(cur.owned) || 0 };
      });
    }
    for (const [typeId, freed] of freedByType) {
      if (lines?.some((x) => x.typeId === typeId)) continue;
      const cur = typesHold[typeId] || {};
      typesHold[typeId] = { held: Math.max(0, (Number(cur.held) || 0) - freed), owned: Number(cur.owned) || 0 };
      tx.set(listingRef.collection(TICKET_TYPES).doc(typeId), { held: admin.firestore.FieldValue.increment(-freed) }, { merge: true });
    }
    tx.set(holdRef, {
      kind, listingId: id, uid, held: heldNow + listing.quantity, owned, types: typesHold, updatedAt: ts(t0),
    }, { merge: true });

    const isLink = listing.provider === 'link';
    if (isFreeOrder) {
      // Issued right after the transaction (markOrderPaid with provider 'free').
    }
    const expiresAtMs = isLink
      ? t0 + cfg.LINK_HOLD_HOURS * HOUR
      : t0 + cfg.HOLD_MINUTES * 60000 + cfg.STRIPE_EXPIRY_MARGIN_SECONDS * 1000;
    let code: string | null = null;
    if (isLink) {
      const free = codeSnaps.findIndex((s) => !s.exists);
      if (free < 0) fail('aborted', 'code_collision');
      code = codes[free];
      tx.set(db().collection(COL.codes).doc(code), { orderId: orderRef.id, createdAt: ts(t0) });
    }
    const order = {
      kind, listingId: id, bookingId: listing.bookingId, buyerId: uid, organizerId: listing.organizerId,
      provider: listing.provider, mode: isLink ? 'link' : 'instant',
      quantity: listing.quantity, partySize: listing.partySize, unitAmount: listing.unitAmount,
      // Stored at order time: later price edits never change it.
      priceRule: kind === 'experience' ? (bSnap?.data()?.priceRule ?? 'base') : 'base',
      totalAmount, currency: listing.currency, items: lines,
      status: isLink ? 'pending_payment' : (isFreeOrder ? 'pending' : 'creating'), expiresAt: ts(expiresAtMs), seatHeld: true,
      code, payment: payment ?? null, receiptPath: null, sentAt: null, remindAt: null,
      checkoutUrl: null, providerRef: {}, ticketId: null, ticketIds: [], title: listing.title.slice(0, 200),
      startsAt: listing.startsAtMs !== null ? ts(listing.startsAtMs) : null,
      platform, createdAt: ts(t0), updatedAt: ts(t0),
    };
    tx.set(orderRef, order);
    return { reused: false, orderId: orderRef.id, order, listing, stripeCountry };
  });

  const o = res.order as Record<string, any>;
  if (o.provider === 'free' && !res.reused) {
    await markOrderPaid(res.orderId, { provider: 'free' as any, amount: 0, currency: o.currency, ref: {}, source: 'organizer' });
    return { orderId: res.orderId, mode: 'free', amount: 0, currency: o.currency, quantity: o.quantity, reused: false };
  }
  if (o.provider === 'link') return linkView(res.orderId, o, res.reused);
  if (res.reused) {
    return {
      orderId: res.orderId, mode: 'instant', checkoutUrl: o.checkoutUrl, expiresAt: iso(o.expiresAt),
      provider: o.provider, amount: o.totalAmount, currency: o.currency, quantity: o.quantity, reused: true,
    };
  }

  const L = res.listing;
  const orderId = res.orderId;
  const expiresAtMs = msOf(o.expiresAt) as number;
  const when = whenText(L.startsAtMs, L.timeZone);
  const input: CheckoutInput = {
    orderId,
    listingKind: L.kind,
    listingId: L.listingId,
    title: L.title,
    description: [when, L.place, L.slotLabel].filter(Boolean).join(' · ') || null,
    imageUrl: L.imageUrl,
    unitAmount: L.unitAmount,
    quantity: L.quantity,
    currency: L.currency,
    successUrl: returnUrl({ k: 'order', o: orderId, r: 'success', p: platform }),
    cancelUrl: returnUrl({ k: 'order', o: orderId, r: 'cancel', p: platform }),
    pendingUrl: returnUrl({ k: 'order', o: orderId, r: 'pending', p: platform }),
    notificationUrl: `${cfg.mpWebhookUrl()}?o=${encodeURIComponent(orderId)}`,
    expiresAtMs,
    nowMs: now(),
    buyerEmail: email,
    locale,
    paymentMethodTypes: stripePaymentMethodTypes(L.currency, (res as any).stripeCountry ?? null),
    lines: Array.isArray(o.items) && o.items.length
      ? (o.items as OrderLine[]).filter((x) => x.unitAmount > 0 || o.items.length === 1)
        .map((x) => ({ ...x, name: `${L.title} – ${x.name}` }))
      : undefined,
  };
  try {
    let checkoutUrl: string;
    let providerRef: Record<string, unknown>;
    if (L.provider === 'stripe') {
      const acct = (await db().collection(COL.accounts).doc(L.organizerId).get()).data();
      const accountId = String(acct?.stripe?.accountId);
      const s = await stripeCreateCheckout(accountId, input);
      checkoutUrl = s.url;
      providerRef = { stripeAccountId: accountId, stripeSessionId: s.id };
    } else {
      const token = await mpAccessTokenFor(L.organizerId);
      const p = await mpCreatePreference(token, input);
      checkoutUrl = p.url;
      providerRef = { mpPreferenceId: p.id };
    }
    await orderRef.update({ status: 'pending', checkoutUrl, providerRef, updatedAt: ts(now()) });
    return {
      orderId, mode: 'instant', checkoutUrl, expiresAt: new Date(expiresAtMs).toISOString(), provider: L.provider,
      amount: o.totalAmount, currency: o.currency, quantity: o.quantity, reused: false,
    };
  } catch (e) {
    console.error(`[tickets] checkout for ${orderId} failed:`, (e as Error)?.message);
    await closeOrder(orderId, 'failed', { failReason: e instanceof ProviderError ? e.reason : 'provider_error' });
    if (e instanceof HttpsError) throw e;
    fail('unavailable', 'provider_unavailable', { provider: L.provider });
  }
}

function iso(v: unknown): string | null {
  const m = msOf(v);
  return m === null ? null : new Date(m).toISOString();
}

function linkView(orderId: string, o: Record<string, any>, reused: boolean): Record<string, unknown> {
  return {
    orderId, mode: 'link', provider: 'link', status: o.status, code: o.code,
    amount: o.totalAmount, currency: o.currency, quantity: o.quantity, payment: o.payment ?? null,
    expiresAt: iso(o.expiresAt), reused,
  };
}

// ─────────────────────────────────────────────────────────── close / release

/** open -> expired | cancelled | failed | rejected, releasing seat + per-user holds. */
export async function closeOrder(
  orderId: string,
  to: 'expired' | 'cancelled' | 'failed' | 'rejected',
  patch: Record<string, unknown> = {},
  only?: ReadonlyArray<string>,
): Promise<boolean> {
  const ref = db().collection(COL.orders).doc(orderId);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const o = snap.data();
    if (!o || !OPEN.has(o.status) || (only && !only.includes(o.status))) return false;
    const q = Math.max(1, Number(o.quantity) || 1);
    const inv = o.seatHeld && o.kind === 'event' ? await tx.get(inventoryRef(o.listingId)) : null;
    const hold = o.seatHeld ? await tx.get(holdingsRef(o.kind, o.listingId, o.buyerId)) : null;
    tx.update(ref, { ...patch, status: to, seatHeld: false, remindAt: null, updatedAt: ts(now()) });
    if (o.seatHeld) releaseTypeHolds(tx, o, hold, 'held');
    if (inv) tx.set(inv.ref, { held: Math.max(0, (Number(inv.data()?.held) || 0) - q), updatedAt: ts(now()) }, { merge: true });
    if (hold) tx.set(hold.ref, { held: Math.max(0, (Number(hold.data()?.held) || 0) - q), updatedAt: ts(now()) }, { merge: true });
    return true;
  });
}

/**
 * Per-type counters for an order's items: 'held' (open order released),
 * 'sold' (refund / dispute of a paid order), 'toSold' (held -> sold on payment).
 * Writes only (FieldValue.increment), so it can run after the reads.
 */
function releaseTypeHolds(
  tx: FirebaseFirestore.Transaction,
  o: Record<string, any>,
  hold: FirebaseFirestore.DocumentSnapshot | null,
  what: 'held' | 'sold' | 'toSold' | 'addSold',
): void {
  const items: OrderLine[] = Array.isArray(o.items) ? o.items : [];
  if (o.kind !== 'event' || !items.length) return;
  const inc = admin.firestore.FieldValue.increment;
  const typesUpdate: Record<string, unknown> = {};
  for (const x of items) {
    const ref = db().collection('events').doc(o.listingId).collection(TICKET_TYPES).doc(x.typeId);
    // set+merge: never aborts the transaction if the organizer deleted the type.
    if (what === 'held') tx.set(ref, { held: inc(-x.quantity) }, { merge: true });
    else if (what === 'sold') tx.set(ref, { sold: inc(-x.quantity) }, { merge: true });
    else if (what === 'addSold') tx.set(ref, { sold: inc(x.quantity) }, { merge: true });
    else tx.set(ref, { held: inc(-x.quantity), sold: inc(x.quantity) }, { merge: true });
    if (hold) {
      if (what === 'held') typesUpdate[`types.${x.typeId}.held`] = inc(-x.quantity);
      else if (what === 'sold') typesUpdate[`types.${x.typeId}.owned`] = inc(-x.quantity);
      else {
        if (what === 'toSold') typesUpdate[`types.${x.typeId}.held`] = inc(-x.quantity);
        typesUpdate[`types.${x.typeId}.owned`] = inc(x.quantity);
      }
    }
  }
  if (hold && Object.keys(typesUpdate).length) tx.update(hold.ref, typesUpdate);
}

// ─────────────────────────────────────────────────────────── paid

export interface PaidEvidence {
  provider: TicketProvider;
  amount: number;       // minor units actually paid (link: the order total, as confirmed by the organizer)
  currency: string;     // lower-case ISO
  ref: Record<string, unknown>;
  source: 'webhook' | 'sync' | 'organizer';
}

/**
 * Idempotent: order -> paid, one tickets/{orderId}_{n} per ticket (each with
 * its own signed QR, single-use at the door), attendee 'going' / booking paid.
 * Refuses (returns 'mismatch') when amount / currency / provider differ from
 * what the server priced. Accepts a LATE payment (order expired / cancelled /
 * rejected): the buyer paid, so tickets are issued (lateOverCapacity if full).
 */
export async function markOrderPaid(orderId: string, ev: PaidEvidence): Promise<'paid' | 'already' | 'mismatch' | 'not_found' | 'closed'> {
  const key = await ticketKey();
  const ref = db().collection(COL.orders).doc(orderId);
  const result = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return { r: 'not_found' as const };
    const o = snap.data() as Record<string, any>;
    if (o.status === 'paid') return { r: 'already' as const };
    if (o.status === 'refunded' || o.status === 'disputed') return { r: 'closed' as const };
    if (o.provider !== ev.provider || o.totalAmount !== ev.amount || String(o.currency).toLowerCase() !== ev.currency) {
      return { r: 'mismatch' as const, o };
    }
    const t = now();
    const q = Math.max(1, Number(o.quantity) || 1);
    const ids = ticketIdsFor(orderId, q);
    const holdSnap = await tx.get(holdingsRef(o.kind, o.listingId, o.buyerId));
    let lateOverCapacity = false;
    if (o.kind === 'event') {
      const evRef = db().collection('events').doc(o.listingId);
      const attRef = evRef.collection('attendees').doc(o.buyerId);
      const [evSnap, attSnap, invSnap, prof] = await Promise.all([
        tx.get(evRef), tx.get(attRef), tx.get(inventoryRef(o.listingId)),
        tx.get(db().collection('profiles').doc(o.buyerId)),
      ]);
      const e = evSnap.data() || {};
      const held = Number(invSnap.data()?.held) || 0;
      const going = Math.max(0, Math.floor(Number(e.attendeeCount) || 0));
      const max = Math.floor(Number(e.maxAttendees) || 0);
      if (!o.seatHeld && max > 0 && going + held + q > max) lateOverCapacity = true;
      if (o.seatHeld) tx.set(invSnap.ref, { held: Math.max(0, held - q), updatedAt: ts(t) }, { merge: true });
      const p = prof.data() || {};
      const photos = Array.isArray(p.photoUrls) ? p.photoUrls : [];
      const prior = attSnap.data() || {};
      const ticketCount = (prior.status === 'going' ? Math.max(0, Number(prior.ticketCount) || 0) : 0) + q;
      tx.set(attRef, {
        eventId: o.listingId,
        userId: o.buyerId,
        userName: String(prior.userName || p.displayName || p.nickname || 'Guest'),
        userPhotoUrl: prior.userPhotoUrl ?? (typeof photos[0] === 'string' ? photos[0] : null),
        status: 'going',
        rsvpDate: prior.rsvpDate ?? ts(t),
        isApproved: true,
        isInvisible: prior.isInvisible ?? false,
        isAnonymous: prior.isAnonymous ?? false,
        muteNotifications: prior.muteNotifications ?? false,
        visibleToOrganizerOnly: prior.visibleToOrganizerOnly ?? false,
        checkedIn: prior.checkedIn ?? false,
        checkedInAt: prior.checkedInAt ?? null,
        // Party = every ticket this person bought (each ticket still has its own QR).
        guestCount: Math.max(0, ticketCount - 1),
        ticketCount,
        tierId: prior.tierId ?? null,
        ticketId: prior.status === 'going' && prior.ticketId ? prior.ticketId : ids[0],
        ticketStatus: 'valid',
        paidAt: ts(t),
      }, { merge: true });
      // Paid events count SEATS (server-maintained; clients cannot write it).
      tx.update(evRef, { attendeeCount: going + q });
    } else {
      const bRef = db().collection('bookings').doc(o.bookingId);
      const b = (await tx.get(bRef)).data();
      if (b) {
        tx.update(bRef, {
          payment: {
            ...(b.payment || {}),
            status: 'paid',
            orderId,
            ticketIds: ids,
            paidAt: ts(t),
            hostConfirmedPaidAt: b.payment?.hostConfirmedPaidAt ?? ts(t),
          },
          updatedAt: ts(t),
        });
      }
    }
    releaseTypeHolds(tx, o, null, o.seatHeld ? 'toSold' : 'addSold');
    const h = holdSnap.data() || {};
    const typesOwned: Record<string, any> = { ...((h.types || {}) as Record<string, any>) };
    for (const x of (Array.isArray(o.items) ? o.items : []) as OrderLine[]) {
      const cur = typesOwned[x.typeId] || {};
      typesOwned[x.typeId] = {
        held: o.seatHeld ? Math.max(0, (Number(cur.held) || 0) - x.quantity) : Number(cur.held) || 0,
        owned: (Number(cur.owned) || 0) + x.quantity,
      };
    }
    tx.set(holdSnap.ref, {
      types: typesOwned,
      kind: o.kind, listingId: o.listingId, uid: o.buyerId,
      held: o.seatHeld ? Math.max(0, (Number(h.held) || 0) - q) : Math.max(0, Number(h.held) || 0),
      owned: Math.max(0, Number(h.owned) || 0) + q,
      updatedAt: ts(t),
    }, { merge: true });
    tx.update(ref, {
      status: 'paid', paidAt: ts(t), seatHeld: false, ticketId: ids[0], ticketIds: ids, paidVia: ev.source, remindAt: null,
      providerRef: { ...(o.providerRef || {}), ...ev.ref },
      ...(lateOverCapacity ? { lateOverCapacity: true } : {}),
      ...(ev.ref.stripePaymentIntentId ? { stripePaymentIntentId: ev.ref.stripePaymentIntentId } : {}),
      ...(ev.ref.mpPaymentId ? { mpPaymentId: ev.ref.mpPaymentId } : {}),
      updatedAt: ts(t),
    });
    // Ticket type per seat (items in order); legacy single type -> null.
    const typeOf: Array<OrderLine | null> = [];
    for (const x of (Array.isArray(o.items) ? o.items : []) as OrderLine[]) for (let k = 0; k < x.quantity; k++) typeOf.push(x);
    ids.forEach((tid, i) => {
      const tt = typeOf[i] ?? null;
      tx.set(db().collection(COL.tickets).doc(tid), {
        ticketTypeId: tt?.typeId ?? null, ticketTypeName: tt?.name ?? null,
        ticketId: tid, orderId, index: i + 1, of: q,
        kind: o.kind, listingId: o.listingId, bookingId: o.bookingId ?? null,
        buyerId: o.buyerId, organizerId: o.organizerId,
        partySize: Math.max(1, Number(o.partySize) || 1),
        status: 'valid', qrPayload: ticketQrPayload(key, tid),
        title: o.title ?? null, startsAt: o.startsAt ?? null,
        unitAmount: tt ? tt.unitAmount : o.unitAmount, priceRule: o.priceRule ?? 'base', currency: o.currency, provider: o.provider, code: o.code ?? null,
        issuedAt: ts(t), checkedInAt: null,
      });
    });
    return { r: 'paid' as const, o };
  });
  if (result.r === 'mismatch') {
    console.error(`[tickets] order ${orderId}: payment evidence does not match (provider/amount/currency)`);
    await db().collection(COL.orders).doc(orderId).set({
      mismatchAt: ts(now()), mismatch: { provider: ev.provider, amount: ev.amount, currency: ev.currency },
    }, { merge: true }).catch(() => undefined);
  }
  if (result.r === 'paid') await notifyPaid(orderId, result.o!, ev.source === 'organizer');
  return result.r;
}

async function notifyPaid(orderId: string, o: Record<string, any>, byOrganizer: boolean): Promise<void> {
  const data = { action: 'ticket', orderId, kind: String(o.kind), listingId: String(o.listingId) };
  const title = String(o.title || '');
  try {
    await emitNotification({ recipientId: o.buyerId, type: 'ticket_ready', title: lt('notifServerTicketReady'), body: rawText(title), data });
    if (!byOrganizer) {
      await emitNotification({
        recipientId: o.organizerId, type: 'ticket_sold', title: lt('notifServerTicketSold'), body: rawText(title),
        data: { ...data, action: o.kind === 'event' ? 'event' : 'booking' },
      });
    }
  } catch (e) {
    console.error('[tickets] paid notification failed:', (e as Error)?.message);
  }
}

// ─────────────────────────────────────────────────────────── link mode: buyer + organizer

function requireOrderId(v: unknown): string {
  if (typeof v !== 'string' || !ID_RE.test(v)) fail('invalid-argument', 'invalid_order_id');
  return v;
}

/**
 * Buyer: "I've paid" (link mode). data { orderId, receiptPath? } where the
 * receipt (optional) was uploaded to ticket_receipts/{orderId}/... (storage.rules:
 * buyer writes images <= 5 MB; buyer + organizer read).
 */
export async function markTicketPaymentSent(uid: string, data: any): Promise<Record<string, unknown>> {
  const orderId = requireOrderId(data?.orderId);
  const receipt = data?.receiptPath;
  if (receipt !== undefined && receipt !== null) {
    if (typeof receipt !== 'string' || !receipt.startsWith(`ticket_receipts/${orderId}/`) || receipt.length > 300 || receipt.includes('..')) {
      fail('invalid-argument', 'invalid_receipt');
    }
  }
  const ref = db().collection(COL.orders).doc(orderId);
  const t = now();
  const r = await db().runTransaction(async (tx) => {
    const o = (await tx.get(ref)).data();
    if (!o || o.buyerId !== uid) fail('not-found', 'order_not_found');
    if (o.provider !== 'link') fail('failed-precondition', 'not_link_order');
    if (o.status === 'awaiting_confirmation') {
      if (receipt && receipt !== o.receiptPath) tx.update(ref, { receiptPath: receipt, updatedAt: ts(t) });
      return { changed: false, o };
    }
    if (o.status !== 'pending_payment') fail('failed-precondition', 'not_pending', { status: o.status });
    const exp = Math.max(msOf(o.expiresAt) ?? 0, t + cfg.CONFIRM_WINDOW_HOURS * HOUR);
    tx.update(ref, {
      status: 'awaiting_confirmation', sentAt: ts(t), receiptPath: receipt ?? null,
      expiresAt: ts(exp), remindAt: ts(t + cfg.REMIND_AFTER_HOURS * HOUR), updatedAt: ts(t),
    });
    return { changed: true, o };
  });
  if (r.changed) {
    await emitNotification({
      recipientId: r.o.organizerId, type: 'ticket_payment_to_confirm', title: lt('notifServerPaymentToConfirm'),
      body: rawText(`${r.o.title || ''} · ${r.o.code || ''}`.trim()),
      data: { action: 'ticket_confirm', orderId },
    }).catch(() => undefined);
  }
  return { orderId, status: 'awaiting_confirmation' };
}

const CONFIRMABLE = new Set(['pending_payment', 'awaiting_confirmation', 'expired', 'rejected']);

/** Organizer: confirm one or many link payments. data { orderId } | { orderIds: [...] (<= 50) }. */
export async function confirmTicketPayment(uid: string, data: any): Promise<Record<string, unknown>> {
  const ids: string[] = Array.isArray(data?.orderIds) ? data.orderIds : [data?.orderId];
  if (ids.length === 0 || ids.length > 50) fail('invalid-argument', 'invalid_order_ids');
  ids.forEach(requireOrderId);
  const results: Record<string, string> = {};
  for (const orderId of Array.from(new Set(ids))) {
    const o = (await db().collection(COL.orders).doc(orderId).get()).data();
    if (!o || o.organizerId !== uid) {
      if (ids.length === 1) fail('permission-denied', 'not_organizer');
      results[orderId] = 'not_organizer';
      continue;
    }
    if (o.provider !== 'link') { results[orderId] = 'not_link_order'; continue; }
    if (o.status === 'paid') { results[orderId] = 'already'; continue; }
    if (!CONFIRMABLE.has(o.status)) { results[orderId] = `not_confirmable_${o.status}`; continue; }
    results[orderId] = await markOrderPaid(orderId, {
      provider: 'link', amount: o.totalAmount, currency: String(o.currency).toLowerCase(),
      ref: { confirmedBy: uid, confirmedAt: new Date(now()).toISOString() }, source: 'organizer',
    });
  }
  return { results };
}

/** Organizer: "not received". data { orderId, reason }. Seat released, buyer told why. */
export async function rejectTicketPayment(uid: string, data: any): Promise<Record<string, unknown>> {
  const orderId = requireOrderId(data?.orderId);
  const reason = typeof data?.reason === 'string' ? data.reason.trim().slice(0, 300) : '';
  const o = (await db().collection(COL.orders).doc(orderId).get()).data();
  if (!o || o.organizerId !== uid) fail('permission-denied', 'not_organizer');
  if (o.provider !== 'link') fail('failed-precondition', 'not_link_order');
  const done = await closeOrder(orderId, 'rejected', { rejectReason: reason || null, rejectedAt: ts(now()) },
    ['pending_payment', 'awaiting_confirmation']);
  if (!done) fail('failed-precondition', 'not_pending', { status: o.status });
  await emitNotification({
    recipientId: o.buyerId, type: 'ticket_payment_rejected', title: lt('notifServerPaymentNotConfirmed'),
    body: rawText(reason || String(o.title || '')), data: { action: 'ticket', orderId },
  }).catch(() => undefined);
  return { orderId, status: 'rejected' };
}

/** Scheduled: remind organizers of payments waiting for them (one push per organizer). */
export async function remindDueConfirmations(limit = 300): Promise<number> {
  const due = await db().collection(COL.orders)
    .where('status', '==', 'awaiting_confirmation')
    .where('remindAt', '<=', ts(now()))
    .orderBy('remindAt')
    .limit(limit)
    .get();
  const byOrg = new Map<string, number>();
  const batch = db().batch();
  for (const d of due.docs) {
    const org = String(d.data().organizerId);
    byOrg.set(org, (byOrg.get(org) || 0) + 1);
    batch.update(d.ref, { remindAt: ts(now() + cfg.REMIND_EVERY_HOURS * HOUR) });
  }
  if (due.size) await batch.commit();
  for (const [org, n] of byOrg) {
    await emitNotification({
      recipientId: org, type: 'ticket_payment_to_confirm', title: lt('notifServerPaymentsWaiting'),
      body: lt('srvPaymentsWaitingCount', { count: n }), data: { action: 'ticket_confirm', count: String(n) },
    }).catch(() => undefined);
  }
  return byOrg.size;
}

// ─────────────────────────────────────────────────────────── refunds / disputes

/** Full refund or dispute: every ticket of the order invalid, QR rejected at the door, seats + allowance freed. */
export async function markOrderReversed(orderId: string, to: 'refunded' | 'disputed', ref: Record<string, unknown> = {}): Promise<boolean> {
  const oref = db().collection(COL.orders).doc(orderId);
  const changed = await db().runTransaction(async (tx) => {
    const snap = await tx.get(oref);
    const o = snap.data();
    if (!o) return false;
    if (o.status === to || (o.status === 'refunded' && to === 'disputed')) return false;
    const t = now();
    const q = Math.max(1, Number(o.quantity) || 1);
    const ids: string[] = Array.isArray(o.ticketIds) && o.ticketIds.length ? o.ticketIds : ticketIdsFor(orderId, q);
    const tSnaps = await Promise.all(ids.map((id) => tx.get(db().collection(COL.tickets).doc(id))));
    const wasPaid = o.status === 'paid';
    const wasOpen = OPEN.has(o.status) && o.seatHeld;
    const inv = wasOpen && o.kind === 'event' ? await tx.get(inventoryRef(o.listingId)) : null;
    const hold = wasPaid || wasOpen ? await tx.get(holdingsRef(o.kind, o.listingId, o.buyerId)) : null;
    if (o.kind === 'event' && wasPaid) {
      const evRef = db().collection('events').doc(o.listingId);
      const attRef = evRef.collection('attendees').doc(o.buyerId);
      const [evSnap, attSnap] = await Promise.all([tx.get(evRef), tx.get(attRef)]);
      const a = attSnap.data();
      if (a && a.status === 'going') {
        const left = Math.max(0, (Number(a.ticketCount) || q) - q);
        if (left === 0) tx.delete(attRef);
        else {
          const remainingId = ids.includes(a.ticketId) ? null : a.ticketId;
          tx.update(attRef, { ticketCount: left, guestCount: Math.max(0, left - 1), ticketId: remainingId ?? a.ticketId });
        }
      }
      const going = Math.max(0, Math.floor(Number(evSnap.data()?.attendeeCount) || 0));
      if (evSnap.exists) tx.update(evRef, { attendeeCount: Math.max(0, going - q) });
    } else if (o.kind === 'experience' && o.bookingId) {
      const bRef = db().collection('bookings').doc(o.bookingId);
      const b = (await tx.get(bRef)).data();
      if (b && b.payment?.orderId === orderId) {
        tx.update(bRef, { payment: { ...b.payment, status: to }, updatedAt: ts(t) });
      }
    }
    if (inv) tx.set(inv.ref, { held: Math.max(0, (Number(inv.data()?.held) || 0) - q) }, { merge: true });
    if (wasPaid || wasOpen) releaseTypeHolds(tx, o, null, wasPaid ? 'sold' : 'held');
    if (hold && Array.isArray(o.items) && o.items.length) {
      const types: Record<string, any> = { ...((hold.data()?.types || {}) as Record<string, any>) };
      for (const x of o.items as OrderLine[]) {
        const cur = types[x.typeId] || {};
        types[x.typeId] = wasPaid
          ? { held: Number(cur.held) || 0, owned: Math.max(0, (Number(cur.owned) || 0) - x.quantity) }
          : { held: Math.max(0, (Number(cur.held) || 0) - x.quantity), owned: Number(cur.owned) || 0 };
      }
      tx.set(hold.ref, { types }, { merge: true });
    }
    if (hold) {
      const h = hold.data() || {};
      tx.set(hold.ref, wasPaid
        ? { owned: Math.max(0, (Number(h.owned) || 0) - q), updatedAt: ts(t) }
        : { held: Math.max(0, (Number(h.held) || 0) - q), updatedAt: ts(t) }, { merge: true });
    }
    tx.update(oref, { status: to, seatHeld: false, [`${to}At`]: ts(t), reversalRef: ref, updatedAt: ts(t) });
    for (const s of tSnaps) if (s.exists) tx.update(s.ref, { status: to, invalidatedAt: ts(t) });
    return true;
  });
  if (changed) {
    const o = (await oref.get()).data() || {};
    await emitNotification({
      recipientId: o.buyerId, type: 'ticket_refunded',
      title: to === 'refunded' ? lt('notifServerTicketRefunded') : lt('notifServerTicketDisputed'),
      body: rawText(String(o.title || '')), data: { action: 'ticket', orderId },
    }).catch(() => undefined);
  }
  return changed;
}

/**
 * The ORGANIZER removed the date/time (or cancelled): give the money back.
 *  - instant + paid: refund through the provider API on the organizer's own
 *    account (Stripe refunds.create with stripeAccount / MP POST
 *    /v1/payments/{id}/refunds with the organizer token), idempotent per
 *    order; the refund webhook then invalidates the tickets. A provider error
 *    leaves refund.status 'refund_required' and tells the organizer.
 *  - link + paid: refund.status 'refund_owed' (the organizer pays back
 *    outside GreenGo) + a reminder to the organizer.
 *  - still open: the order is cancelled and its holds released.
 * Recorded on the order as `refund: { status, providerRefundId?, reason, at }`.
 */
export async function requestOrderRefund(orderId: string, reason: string): Promise<string> {
  const ref = db().collection(COL.orders).doc(orderId);
  const o = (await ref.get()).data();
  if (!o) return 'not_found';
  if (OPEN.has(o.status)) {
    await closeOrder(orderId, 'cancelled', { cancelReason: reason });
    return 'cancelled';
  }
  if (o.status !== 'paid') return o.status;
  if (o.refund?.status === 'requested' || o.refund?.status === 'refund_owed') return o.refund.status;
  const t = ts(now());
  let refund: Record<string, unknown>;
  try {
    if (o.provider === 'stripe' && o.stripePaymentIntentId && o.providerRef?.stripeAccountId) {
      const id = await stripeRefund(o.providerRef.stripeAccountId, o.stripePaymentIntentId, orderId);
      refund = { status: 'requested', providerRefundId: id, reason, at: t };
    } else if (o.provider === 'mercadopago' && o.mpPaymentId) {
      const id = await mpRefund(await mpAccessTokenFor(o.organizerId), String(o.mpPaymentId), orderId);
      refund = { status: 'requested', providerRefundId: id, reason, at: t };
    } else {
      refund = { status: 'refund_owed', reason, at: t };
    }
  } catch (e) {
    console.error(`[tickets] refund ${orderId} failed:`, (e as Error)?.message);
    refund = { status: 'refund_required', reason, at: t, error: e instanceof ProviderError ? e.reason : 'provider_error' };
  }
  await ref.set({ refund, updatedAt: t }, { merge: true });
  if (refund.status !== 'requested') {
    await emitNotification({
      recipientId: o.organizerId, type: 'ticket_refund_owed', title: lt('notifServerRefundToPayBack'),
      body: rawText(`${o.title || ''} · ${o.code || ''}`.trim()), data: { action: 'ticket_confirm', orderId },
    }).catch(() => undefined);
  }
  return String(refund.status);
}

// ─────────────────────────────────────────────────────────── sync / cancel / expire

/** Instant mode: asks the provider directly (webhook late or lost). Returns the order status. */
export async function syncOrderWithProvider(orderId: string): Promise<string> {
  const ref = db().collection(COL.orders).doc(orderId);
  const o = (await ref.get()).data();
  if (!o) return 'not_found';
  if (o.provider === 'link') return o.status;
  if (!OPEN.has(o.status) && o.status !== 'expired' && o.status !== 'cancelled') return o.status;
  try {
    if (o.provider === 'stripe' && o.providerRef?.stripeSessionId && cfg.stripeConfigured()) {
      const s = await stripeRetrieveSession(o.providerRef.stripeAccountId, o.providerRef.stripeSessionId);
      if (s.payment_status === 'paid' && s.metadata?.orderId === orderId) {
        await markOrderPaid(orderId, {
          provider: 'stripe', amount: Number(s.amount_total), currency: String(s.currency).toLowerCase(),
          ref: { stripePaymentIntentId: typeof s.payment_intent === 'string' ? s.payment_intent : (s.payment_intent as any)?.id ?? null },
          source: 'sync',
        });
      }
    } else if (o.provider === 'mercadopago' && cfg.mercadoPagoConfigured()) {
      const token = await mpAccessTokenFor(o.organizerId);
      const pays = await mpSearchPayments(token, orderId);
      const ok = pays.find((p) => p.status === 'approved' && p.externalReference === orderId);
      if (ok) {
        await markOrderPaid(orderId, {
          provider: 'mercadopago', amount: toMinor(ok.amount, ok.currency), currency: ok.currency,
          ref: { mpPaymentId: ok.id }, source: 'sync',
        });
      }
    }
  } catch (e) {
    console.error(`[tickets] sync ${orderId} failed:`, (e as Error)?.message);
  }
  return (await ref.get()).data()?.status ?? 'unknown';
}

export async function syncTicketOrder(uid: string, data: any): Promise<Record<string, unknown>> {
  const orderId = requireOrderId(data?.orderId);
  const o = (await db().collection(COL.orders).doc(orderId).get()).data();
  if (!o || o.buyerId !== uid) fail('not-found', 'order_not_found');
  const status = await syncOrderWithProvider(orderId);
  return { orderId, status };
}

export async function cancelTicketOrder(uid: string, data: any): Promise<Record<string, unknown>> {
  const orderId = requireOrderId(data?.orderId);
  const o = (await db().collection(COL.orders).doc(orderId).get()).data();
  if (!o || o.buyerId !== uid) fail('not-found', 'order_not_found');
  // Paid in the meantime? Then it is not cancellable.
  const st = await syncOrderWithProvider(orderId);
  if (!OPEN.has(st)) return { orderId, status: st };
  await closeOrder(orderId, 'cancelled', { cancelReason: 'buyer' });
  if (o.provider === 'stripe' && o.providerRef?.stripeSessionId && cfg.stripeConfigured()) {
    stripeExpireSession(o.providerRef.stripeAccountId, o.providerRef.stripeSessionId).catch(() => undefined);
  }
  return { orderId, status: 'cancelled' };
}

/** Scheduled every 5 min: release holds of open orders past expiresAt (both modes). */
export async function expireDueOrders(limit = 300): Promise<number> {
  const due = await db().collection(COL.orders)
    .where('status', 'in', [...OPEN_STATUSES])
    .where('expiresAt', '<=', ts(now()))
    .orderBy('expiresAt')
    .limit(limit)
    .get();
  let n = 0;
  for (const d of due.docs) {
    const st = d.data().provider === 'link' ? d.data().status : await syncOrderWithProvider(d.id);
    if (OPEN.has(st) && await closeOrder(d.id, 'expired')) {
      n++;
      const o = d.data();
      if (o.provider === 'link') {
        await emitNotification({
          recipientId: o.buyerId, type: 'ticket_order_expired', title: lt('notifServerTicketReservationExpired'),
          body: rawText(String(o.title || '')), data: { action: 'ticket', orderId: d.id },
        }).catch(() => undefined);
      }
    }
  }
  return n;
}

export { toMajor };
