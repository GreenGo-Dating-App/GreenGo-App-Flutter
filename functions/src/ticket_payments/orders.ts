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
  ticketDeps,
  toMajor,
  toMinor,
} from './providers';
import { ticketQrPayload } from './tokens';
import { ticketKey } from './keys';
import { emitNotification } from '../notifications/notifyHelpers';

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

interface Listing {
  kind: 'event' | 'experience';
  listingId: string;
  bookingId: string | null;
  organizerId: string;
  provider: TicketProvider;
  linkMethod: string | null;
  instructions: string | null;
  unitAmount: number;
  quantity: number;
  currency: string;
  title: string;
  startsAtMs: number | null;
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

/**
 * Buyer: data { kind: 'event' | 'experience', id, bookingId? (experience),
 * quantity? (event), platform? 'app' | 'web' }.
 * Instant -> { orderId, mode: 'instant', checkoutUrl, expiresAt, provider, reused }.
 * Link    -> { orderId, mode: 'link', code, amount, currency, payment, expiresAt, reused }.
 */
export async function createTicketCheckout(uid: string, data: any, email: string | null): Promise<Record<string, unknown>> {
  const kind = data?.kind;
  const id = data?.id;
  if (kind !== 'event' && kind !== 'experience') fail('invalid-argument', 'invalid_kind');
  if (typeof id !== 'string' || !ID_RE.test(id)) fail('invalid-argument', 'invalid_id');
  const platform = clientPlatform(data?.platform);
  const bookingId = kind === 'experience' ? data?.bookingId : null;
  if (kind === 'experience' && (typeof bookingId !== 'string' || !ID_RE.test(bookingId))) {
    fail('invalid-argument', 'invalid_booking_id');
  }
  const qty = kind === 'event' ? (data?.quantity ?? 1) : 1;
  if (!Number.isInteger(qty) || qty < 1 || qty > cfg.MAX_QUANTITY) fail('invalid-argument', 'invalid_quantity');

  const orders = db().collection(COL.orders);
  const orderRef = orders.doc();
  const t0 = now();
  const codes = [newPaymentCode(), newPaymentCode(), newPaymentCode()];

  const res = await db().runTransaction(async (tx) => {
    const listingRef = kind === 'event'
      ? db().collection('events').doc(id)
      : db().collection('user_experiences').doc(id);
    const bookingRef = bookingId ? db().collection('bookings').doc(bookingId) : null;
    const attRef = kind === 'event' ? db().collection('events').doc(id).collection('attendees').doc(uid) : null;
    const invRef = kind === 'event' ? inventoryRef(id) : null;
    const openQ = orders.where('buyerId', '==', uid).where('listingId', '==', id)
      .where('status', 'in', [...OPEN_STATUSES]).limit(5);
    const [lSnap, bSnap, aSnap, invSnap, openSnap] = await Promise.all([
      tx.get(listingRef),
      bookingRef ? tx.get(bookingRef) : Promise.resolve(null),
      attRef ? tx.get(attRef) : Promise.resolve(null),
      invRef ? tx.get(invRef) : Promise.resolve(null),
      tx.get(openQ),
    ]);
    if (!lSnap.exists) fail('not-found', 'listing_not_found');
    const l = lSnap.data() as Record<string, any>;

    let listing: Listing;
    if (kind === 'event') {
      if (!(typeof l.price === 'number' && l.price > 0)) fail('failed-precondition', 'not_paid_listing');
      if (!isTicketProvider(l.ticketProvider)) fail('failed-precondition', 'organizer_payments_not_ready');
      if (l.status === 'cancelled' || l.status === 'draft') fail('failed-precondition', 'listing_not_on_sale');
      const end = msOf(l.endDate) ?? msOf(l.startDate);
      if (end !== null && end < t0) fail('failed-precondition', 'listing_ended');
      if (l.organizerId === uid) fail('failed-precondition', 'own_listing');
      const maxQ = 1 + Math.max(0, Math.floor(Number(l.guestsAllowedPerAttendee) || 0));
      if (qty > maxQ) fail('invalid-argument', 'invalid_quantity', { max: maxQ });
      const currency = isoCurrency(l.currencyCode, l.currency);
      if (!currency) fail('failed-precondition', 'currency_missing');
      const a = aSnap?.data();
      if (a && a.status === 'going') fail('already-exists', 'already_has_ticket');
      listing = {
        kind, listingId: id, bookingId: null, organizerId: String(l.organizerId), provider: l.ticketProvider,
        linkMethod: typeof l.ticketLinkMethod === 'string' ? l.ticketLinkMethod : null,
        instructions: cleanInstructions(l.ticketPaymentInstructions),
        unitAmount: toMinor(l.price, currency), quantity: qty, currency, title: String(l.title || 'Event'),
        startsAtMs: msOf(l.startDate),
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
      listing = {
        kind, listingId: id, bookingId, organizerId: String(b.hostId), provider: b.payment.provider,
        linkMethod: typeof b.payment.linkMethod === 'string' ? b.payment.linkMethod : (typeof l.paymentLinkMethod === 'string' ? l.paymentLinkMethod : null),
        instructions: cleanInstructions(l.paymentInstructions),
        unitAmount: Number(b.price.unitAmount), quantity: Number(b.guests) || 1, currency,
        title: String(b.experienceTitle || l.title || 'Experience'), startsAtMs: start,
      };
    }
    if (!Number.isSafeInteger(listing.unitAmount) || listing.unitAmount <= 0) fail('failed-precondition', 'invalid_price');

    // Readiness of the organizer's payment setup.
    let payment: ReturnType<typeof linkPaymentSnapshot> = null;
    const codeSnaps = listing.provider === 'link'
      ? await Promise.all(codes.map((c) => tx.get(db().collection(COL.codes).doc(c))))
      : [];
    if (listing.provider === 'link') {
      const prof = (await tx.get(db().collection('profiles').doc(listing.organizerId))).data();
      payment = linkPaymentSnapshot(listing.linkMethod, prof, listing.instructions);
      if (!payment) fail('failed-precondition', 'organizer_payments_not_ready', { provider: 'link' });
    } else {
      const acct = (await tx.get(db().collection(COL.accounts).doc(listing.organizerId))).data();
      if (!isProvider(listing.provider) || !cfg.providerConfigured(listing.provider) || !accountReady(acct, listing.provider)) {
        fail('failed-precondition', 'organizer_payments_not_ready', { provider: listing.provider });
      }
    }

    // One live order per buyer + listing: reuse it while it is still usable.
    let freedHolds = 0;
    for (const d of openSnap.docs) {
      const o = d.data();
      if ((o.bookingId ?? null) !== (listing.bookingId ?? null)) continue;
      const exp = msOf(o.expiresAt) ?? 0;
      const sameShape = o.quantity === listing.quantity && o.provider === listing.provider;
      if (sameShape && o.provider === 'link' && exp > t0) return { reused: true, orderId: d.id, order: o, listing };
      if (sameShape && o.checkoutUrl && exp - t0 > 5 * 60000) return { reused: true, orderId: d.id, order: o, listing };
      tx.update(d.ref, { status: 'cancelled', cancelReason: 'superseded', seatHeld: false, updatedAt: ts(t0) });
      if (o.seatHeld) freedHolds += 1;
    }

    if (kind === 'event') {
      const held = Math.max(0, (Number(invSnap?.data()?.held) || 0) - freedHolds);
      const max = Math.floor(Number(l.maxAttendees) || 0);
      const going = Math.max(0, Math.floor(Number(l.attendeeCount) || 0));
      if (max > 0 && going + held + 1 > max) fail('resource-exhausted', 'sold_out');
      tx.set(invRef!, { held: held + 1, updatedAt: ts(t0) }, { merge: true });
    }

    const isLink = listing.provider === 'link';
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
      quantity: listing.quantity, unitAmount: listing.unitAmount,
      totalAmount: listing.unitAmount * listing.quantity, currency: listing.currency,
      status: isLink ? 'pending_payment' : 'creating', expiresAt: ts(expiresAtMs), seatHeld: kind === 'event',
      code, payment: payment ?? null, receiptPath: null, sentAt: null, remindAt: null,
      checkoutUrl: null, providerRef: {}, ticketId: null, title: listing.title.slice(0, 200),
      startsAt: listing.startsAtMs !== null ? ts(listing.startsAtMs) : null,
      platform, createdAt: ts(t0), updatedAt: ts(t0),
    };
    tx.set(orderRef, order);
    return { reused: false, orderId: orderRef.id, order, listing };
  });

  const o = res.order as Record<string, any>;
  if (o.provider === 'link') return linkView(res.orderId, o, res.reused);
  if (res.reused) {
    return { orderId: res.orderId, mode: 'instant', checkoutUrl: o.checkoutUrl, expiresAt: iso(o.expiresAt), provider: o.provider, reused: true };
  }

  const L = res.listing;
  const orderId = res.orderId;
  const expiresAtMs = msOf(o.expiresAt) as number;
  const input = {
    orderId,
    title: L.title,
    unitAmount: L.unitAmount,
    quantity: L.quantity,
    currency: L.currency,
    successUrl: returnUrl({ k: 'order', o: orderId, r: 'success', p: platform }),
    cancelUrl: returnUrl({ k: 'order', o: orderId, r: 'cancel', p: platform }),
    expiresAtMs,
    buyerEmail: email,
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
      const p = await mpCreatePreference(token, {
        ...input,
        notificationUrl: `${cfg.mpWebhookUrl()}?o=${encodeURIComponent(orderId)}`,
        pendingUrl: returnUrl({ k: 'order', o: orderId, r: 'pending', p: platform }),
      });
      checkoutUrl = p.url;
      providerRef = { mpPreferenceId: p.id };
    }
    await orderRef.update({ status: 'pending', checkoutUrl, providerRef, updatedAt: ts(now()) });
    return { orderId, mode: 'instant', checkoutUrl, expiresAt: new Date(expiresAtMs).toISOString(), provider: L.provider, reused: false };
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
    amount: o.totalAmount, currency: o.currency, payment: o.payment ?? null,
    expiresAt: iso(o.expiresAt), reused,
  };
}

// ─────────────────────────────────────────────────────────── close / release

/** open -> expired | cancelled | failed | rejected, releasing the event seat hold. */
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
    const inv = o.seatHeld && o.kind === 'event' ? await tx.get(inventoryRef(o.listingId)) : null;
    tx.update(ref, { ...patch, status: to, seatHeld: false, remindAt: null, updatedAt: ts(now()) });
    if (inv) tx.set(inv.ref, { held: Math.max(0, (Number(inv.data()?.held) || 0) - 1), updatedAt: ts(now()) }, { merge: true });
    return true;
  });
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
 * Idempotent: order -> paid, ticket issued, attendee 'going' / booking paid.
 * Refuses (returns 'mismatch') when amount / currency / provider differ from
 * what the server priced. Accepts a LATE payment (order expired / cancelled /
 * rejected): the buyer paid, so the ticket is issued (lateOverCapacity if full).
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
    const ticketRef = db().collection(COL.tickets).doc(orderId);
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
      const wasGoing = attSnap.data()?.status === 'going';
      const max = Math.floor(Number(e.maxAttendees) || 0);
      if (!o.seatHeld && max > 0 && going + held + 1 > max) lateOverCapacity = true;
      if (o.seatHeld) tx.set(invSnap.ref, { held: Math.max(0, held - 1), updatedAt: ts(t) }, { merge: true });
      const p = prof.data() || {};
      const photos = Array.isArray(p.photoUrls) ? p.photoUrls : [];
      const prior = attSnap.data() || {};
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
        guestCount: Math.max(0, (Number(o.quantity) || 1) - 1),
        tierId: prior.tierId ?? null,
        ticketId: orderId,
        ticketStatus: 'valid',
        paidAt: ts(t),
      }, { merge: true });
      if (!wasGoing) tx.update(evRef, { attendeeCount: going + 1 });
    } else {
      const bRef = db().collection('bookings').doc(o.bookingId);
      const b = (await tx.get(bRef)).data();
      if (b) {
        tx.update(bRef, {
          payment: {
            ...(b.payment || {}),
            status: 'paid',
            orderId,
            paidAt: ts(t),
            hostConfirmedPaidAt: b.payment?.hostConfirmedPaidAt ?? ts(t),
          },
          updatedAt: ts(t),
        });
      }
    }
    tx.update(ref, {
      status: 'paid', paidAt: ts(t), seatHeld: false, ticketId: orderId, paidVia: ev.source, remindAt: null,
      providerRef: { ...(o.providerRef || {}), ...ev.ref },
      ...(lateOverCapacity ? { lateOverCapacity: true } : {}),
      ...(ev.ref.stripePaymentIntentId ? { stripePaymentIntentId: ev.ref.stripePaymentIntentId } : {}),
      ...(ev.ref.mpPaymentId ? { mpPaymentId: ev.ref.mpPaymentId } : {}),
      updatedAt: ts(t),
    });
    tx.set(ticketRef, {
      orderId, kind: o.kind, listingId: o.listingId, bookingId: o.bookingId ?? null,
      buyerId: o.buyerId, organizerId: o.organizerId, quantity: o.quantity,
      status: 'valid', qrPayload: ticketQrPayload(key, orderId),
      title: o.title ?? null, startsAt: o.startsAt ?? null,
      amount: o.totalAmount, currency: o.currency, provider: o.provider, code: o.code ?? null,
      issuedAt: ts(t), checkedInAt: null,
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
    await emitNotification({ recipientId: o.buyerId, type: 'ticket_ready', title: 'Your ticket is ready', body: title, data });
    if (!byOrganizer) {
      await emitNotification({
        recipientId: o.organizerId, type: 'ticket_sold', title: 'Ticket sold', body: title,
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
      recipientId: r.o.organizerId, type: 'ticket_payment_to_confirm', title: 'Payment to confirm',
      body: `${r.o.title || ''} · ${r.o.code || ''}`.trim(),
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
    recipientId: o.buyerId, type: 'ticket_payment_rejected', title: 'Payment not confirmed',
    body: reason || String(o.title || ''), data: { action: 'ticket', orderId },
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
      recipientId: org, type: 'ticket_payment_to_confirm', title: 'Payments waiting for your confirmation',
      body: `${n}`, data: { action: 'ticket_confirm', count: String(n) },
    }).catch(() => undefined);
  }
  return byOrg.size;
}

// ─────────────────────────────────────────────────────────── refunds / disputes

/** Full refund or dispute: ticket invalid, QR rejected at the door, seat freed. */
export async function markOrderReversed(orderId: string, to: 'refunded' | 'disputed', ref: Record<string, unknown> = {}): Promise<boolean> {
  const oref = db().collection(COL.orders).doc(orderId);
  const changed = await db().runTransaction(async (tx) => {
    const snap = await tx.get(oref);
    const o = snap.data();
    if (!o) return false;
    if (o.status === to || (o.status === 'refunded' && to === 'disputed')) return false;
    const t = now();
    const tRef = db().collection(COL.tickets).doc(orderId);
    const tSnap = await tx.get(tRef);
    const inv = OPEN.has(o.status) && o.seatHeld ? await tx.get(inventoryRef(o.listingId)) : null;
    if (o.kind === 'event' && o.status === 'paid') {
      const evRef = db().collection('events').doc(o.listingId);
      const attRef = evRef.collection('attendees').doc(o.buyerId);
      const [evSnap, attSnap] = await Promise.all([tx.get(evRef), tx.get(attRef)]);
      if (attSnap.exists && attSnap.data()?.ticketId === orderId) {
        tx.delete(attRef);
        const going = Math.max(0, Math.floor(Number(evSnap.data()?.attendeeCount) || 0));
        if (evSnap.exists && attSnap.data()?.status === 'going') tx.update(evRef, { attendeeCount: Math.max(0, going - 1) });
      }
    } else if (o.kind === 'experience' && o.bookingId) {
      const bRef = db().collection('bookings').doc(o.bookingId);
      const b = (await tx.get(bRef)).data();
      if (b && b.payment?.orderId === orderId) {
        tx.update(bRef, { payment: { ...b.payment, status: to }, updatedAt: ts(t) });
      }
    }
    if (inv) tx.set(inv.ref, { held: Math.max(0, (Number(inv.data()?.held) || 0) - 1) }, { merge: true });
    tx.update(oref, { status: to, seatHeld: false, [`${to}At`]: ts(t), reversalRef: ref, updatedAt: ts(t) });
    if (tSnap.exists) tx.update(tRef, { status: to, invalidatedAt: ts(t) });
    return true;
  });
  if (changed) {
    const o = (await oref.get()).data() || {};
    await emitNotification({
      recipientId: o.buyerId, type: 'ticket_refunded',
      title: to === 'refunded' ? 'Ticket refunded' : 'Ticket payment disputed',
      body: String(o.title || ''), data: { action: 'ticket', orderId },
    }).catch(() => undefined);
  }
  return changed;
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
          recipientId: o.buyerId, type: 'ticket_order_expired', title: 'Ticket reservation expired',
          body: String(o.title || ''), data: { action: 'ticket', orderId: d.id },
        }).catch(() => undefined);
      }
    }
  }
  return n;
}

export { toMajor };
