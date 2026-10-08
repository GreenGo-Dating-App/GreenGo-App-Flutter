/**
 * Experience bookings — data model, state machine and policy math (PURE: no
 * Firestore, no network). Everything that decides money-shaped numbers or a
 * status transition lives here so it can be unit-tested exhaustively.
 *
 * NO MONEY MOVES THROUGH GREENGO. Paid experiences are paid off-platform: in
 * CASH at the meeting, or through the host's own external payment LINK
 * (experience.paymentMethods / paymentLink); a booking only
 * records the agreement, the seats and — on a cancellation / dispute — the
 * refund the policy says is OWED (`refundDue`), shown to both parties. Neither
 * the guest nor the host can move money through these documents.
 *
 * ─────────────────────────────────────────────────────────────── DATA MODEL
 *
 * user_experiences/{expId}/slots/{slotId}            host-managed (rules)
 *   start: Timestamp, end: Timestamp, capacity: int (1..500),
 *   bookedCount: int  (SERVER ONLY, seats held by active bookings),
 *   status: 'open' | 'cancelled', createdAt?, updatedAt?
 *   Rules: host create (bookedCount 0, status open, start in the future) /
 *   update (never bookedCount; capacity >= bookedCount; start/end frozen and
 *   status unchanged while bookedCount > 0 -> use the cancelSlot callable);
 *   delete only while bookedCount == 0.
 *
 * bookings/{bookingId}                               ALL WRITES SERVER-ONLY
 *   experienceId, slotId, hostId, guestId, guests (int >= 1),
 *   status: BookingStatus (see STATE MACHINE),
 *   requestToBook: bool (snapshot of experience.requestToBook),
 *   policy: 'flexible' | 'moderate' | 'strict' (snapshot),
 *   experienceTitle, slotStart, slotEnd (snapshots, for lists + jobs),
 *   price: { unitAmount, currency, totalAmount }  minor units, from the
 *          EXPERIENCE doc (never the client); currency null when free,
 *   payment: { mode: 'free' | 'cash' | 'link'  (guest's choice, one of the
 *                experience's paymentMethods; validated server-side),
 *              link: {type, value} | null (snapshot of the host's link, mode link),
 *              guestMarkedPaidAt: Timestamp | null  (mode link only),
 *              hostConfirmedPaidAt: Timestamp | null (host: link received, or
 *                cash received at / after check-in) }   informational only,
 *   refundDue: { percent, policyPercent, amount, currency, reason, decidedAt } | null
 *              an OBLIGATION computed by refundFor() + refundDueFor(); GreenGo
 *              never executes it. Cash not yet received -> percent 0,
 *   cancellation: { by: 'guest' | 'host', at, reason } | null,
 *   checkIn: { at, byUid } | null,
 *   dispute: { openedAt, byUid, reason, status: 'open' | 'resolved',
 *              resolution: { refundPercent, hostAction, note, byUid, at } | null } | null,
 *   consentVersion: string (the booking terms the guest accepted),
 *   requestId: string (client idempotency key; bookingId = hash(guest, requestId)),
 *   requestExpiresAt  (status requested: min(created + 48 h, slot start)),
 *   reminderAt        (status confirmed: slot start - 24 h; deleted once sent),
 *   completeAt        (status confirmed: slot end + dispute window),
 *   confirmedAt, createdAt, updatedAt
 *   Rules: read by guestId / hostId / admins; no client writes.
 *
 * host_cancellation_stats/{hostId}  server-only; host reads own.
 *   recent: Timestamp[] (host cancellations of CONFIRMED bookings, last 90 d),
 *   flaggedAt: Timestamp | null
 * host_flags/{hostId}               server-only; admins read. 3 host
 *   cancellations in 90 days -> { type: 'excess_host_cancellations', status:
 *   'open', count, ... } + admins notified (suspension is an admin decision).
 * host_suspensions/{hostId}         server-only (resolveBookingDispute
 *   hostAction 'suspend_hosting'); blocks NEW bookings of that host.
 *
 * Two-way, double-blind reviews (only after a real booking):
 * user_experiences/{expId}/review_eligibility/{guestId}  server-only; the
 *   guest reads own. Written at check-in or completion; deleted when a dispute
 *   is opened. { bookingId, hostId, reviewUntil }.
 * user_experiences/{expId}/pending_reviews/{guestId}     guest -> experience,
 *   held: { authorId, bookingId, rating, comment, createdAt, updatedAt } +
 *   server { status: 'pending', revealAt }. Only the author can read it. On
 *   reveal the server copies it into the PUBLIC reviews/{guestId} (the existing
 *   review trigger then moderates + aggregates as before) and deletes it.
 *   Direct client creates of reviews/{uid} are no longer allowed.
 * guest_reviews/{bookingId}                               host -> guest:
 *   { hostId, guestId, experienceId, rating 1..5, comment <= 500, createdAt }
 *   + server { status: 'held' | 'visible' | 'rejected', revealAt, moderation }.
 *   Visible to everyone only once revealed; aggregate on profiles/{guestId}:
 *   guestRatingSum / guestRatingCount / guestRatingAvg (server-owned).
 *   Reveal = both sides submitted, or REVIEW_REVEAL_DAYS after submission.
 *
 * ─────────────────────────────────────────────────────────── STATE MACHINE
 *
 *   requested ─► confirmed | declined | expired | cancelled_by_guest | cancelled_by_host
 *   confirmed ─► completed | no_show | disputed | cancelled_by_guest | cancelled_by_host
 *   no_show   ─► disputed           (guest contests the no-show)
 *   disputed  ─► resolved
 *   declined, expired, cancelled_*, completed, resolved: terminal.
 * Seats (slot.bookedCount) are held by requested / confirmed / no_show /
 * disputed / completed / resolved and released on the move to declined /
 * expired / cancelled_*.
 */

import * as crypto from 'crypto';

export const BOOKINGS = 'bookings';
export const SLOTS = 'slots';
export const EXPERIENCES = 'user_experiences';
export const GUEST_REVIEWS = 'guest_reviews';
export const PENDING_REVIEWS = 'pending_reviews';
export const REVIEW_ELIGIBILITY = 'review_eligibility';
export const HOST_CANCEL_STATS = 'host_cancellation_stats';
export const HOST_FLAGS = 'host_flags';
export const HOST_SUSPENSIONS = 'host_suspensions';
export const BOOKING_AGG_EVENTS = 'booking_agg_events';
export const SERVER_SECRETS = 'server_secrets';

export const HOUR_MS = 60 * 60 * 1000;
export const DAY_MS = 24 * HOUR_MS;

/** Tunables. `app_config/experience_bookings` may override any of them. */
export interface BookingConfig {
  maxGuestsPerBooking: number;
  requestTtlHours: number;
  reminderLeadHours: number;
  disputeWindowHours: number;
  noShowGraceMinutes: number;
  checkInEarlyHours: number;
  checkInLateHours: number;
  reviewRevealDays: number;
  reviewWindowDays: number;
  hostCancelLimit: number;
  hostCancelWindowDays: number;
}

export const DEFAULT_CONFIG: BookingConfig = {
  maxGuestsPerBooking: 20,
  requestTtlHours: 48,
  reminderLeadHours: 24,
  disputeWindowHours: 24,
  noShowGraceMinutes: 30,
  checkInEarlyHours: 2,
  checkInLateHours: 12,
  reviewRevealDays: 14,
  reviewWindowDays: 30,
  hostCancelLimit: 3,
  hostCancelWindowDays: 90,
};

/** Merges a config doc over the defaults, ignoring anything out of range. */
export function resolveConfig(raw: Record<string, unknown> | null | undefined): BookingConfig {
  const out: BookingConfig = { ...DEFAULT_CONFIG };
  if (!raw) return out;
  const bounds: Record<keyof BookingConfig, [number, number]> = {
    maxGuestsPerBooking: [1, 500],
    requestTtlHours: [1, 24 * 14],
    reminderLeadHours: [1, 24 * 7],
    disputeWindowHours: [1, 24 * 14],
    noShowGraceMinutes: [0, 24 * 60],
    checkInEarlyHours: [0, 48],
    checkInLateHours: [0, 72],
    reviewRevealDays: [1, 60],
    reviewWindowDays: [1, 365],
    hostCancelLimit: [1, 100],
    hostCancelWindowDays: [1, 365],
  };
  for (const k of Object.keys(bounds) as Array<keyof BookingConfig>) {
    const v = raw[k];
    const [lo, hi] = bounds[k];
    if (typeof v === 'number' && Number.isInteger(v) && v >= lo && v <= hi) out[k] = v;
  }
  return out;
}

// ───────────────────────────────────────────────────────────── state machine

export const BOOKING_STATUSES = [
  'requested', 'confirmed', 'declined', 'expired',
  'cancelled_by_guest', 'cancelled_by_host',
  'completed', 'no_show', 'disputed', 'resolved',
] as const;
export type BookingStatus = typeof BOOKING_STATUSES[number];

const TRANSITIONS: Record<BookingStatus, readonly BookingStatus[]> = {
  requested: ['confirmed', 'declined', 'expired', 'cancelled_by_guest', 'cancelled_by_host'],
  confirmed: ['completed', 'no_show', 'disputed', 'cancelled_by_guest', 'cancelled_by_host'],
  no_show: ['disputed'],
  disputed: ['resolved'],
  declined: [],
  expired: [],
  cancelled_by_guest: [],
  cancelled_by_host: [],
  completed: [],
  resolved: [],
};

export function isBookingStatus(s: unknown): s is BookingStatus {
  return typeof s === 'string' && (BOOKING_STATUSES as readonly string[]).includes(s);
}

/** The ONLY gate for status changes. Unknown statuses never transition. */
export function canTransition(from: unknown, to: unknown): boolean {
  if (!isBookingStatus(from) || !isBookingStatus(to)) return false;
  return TRANSITIONS[from].includes(to);
}

/** Statuses whose guests occupy seats on the slot. */
export const SEAT_HOLDING: ReadonlySet<BookingStatus> = new Set<BookingStatus>([
  'requested', 'confirmed', 'no_show', 'disputed', 'completed', 'resolved',
]);

/** Statuses that block a second booking of the same guest on the same slot. */
export const ACTIVE_STATUSES: readonly BookingStatus[] = ['requested', 'confirmed'];

// ─────────────────────────────────────────────── private time slots
//
// A slot is the host's AVAILABILITY WINDOW (start..end, at most 24h). A guest
// books ONE start time inside it; the booking lasts the experience's
// durationMinutes (Practical info) - or the whole window when the duration is
// longer than the window / missing. Start times sit on a grid of that length
// from the window start (10:00, 11:00, ... for 60 min). One booking = one user
// and their party: a host's active bookings (requested + confirmed, across ALL
// their experiences) never overlap.

/** Bookings never run longer than a window, so this bounds the look-back. */
export const MAX_BOOKING_LENGTH_MS = 24 * HOUR_MS;
/** Most start times offered in one window (15-minute grid over 24h = 96). */
export const MAX_STARTS_PER_WINDOW = 96;

/** How long one booking lasts in this window, in ms. */
export function bookingLengthMs(durationMinutes: unknown, windowStart: number, windowEnd: number): number {
  const windowLen = Math.max(0, windowEnd - windowStart);
  const d = typeof durationMinutes === 'number' && Number.isFinite(durationMinutes) ? durationMinutes : 0;
  const len = Math.round(d) * 60 * 1000;
  return len > 0 && len <= windowLen ? len : windowLen;
}

/** Bookable start times in a window: a grid of [lengthMs] from its start. */
export function windowStarts(windowStart: number, windowEnd: number, lengthMs: number): number[] {
  const out: number[] = [];
  if (lengthMs <= 0) return out;
  for (let t = windowStart; t + lengthMs <= windowEnd && out.length < MAX_STARTS_PER_WINDOW; t += lengthMs) {
    out.push(t);
  }
  return out;
}

export function overlapsAny(start: number, end: number, busy: ReadonlyArray<readonly [number, number]>): boolean {
  return busy.some(([s, e]) => start < e && s < end);
}

/**
 * The start the guest asked for (ms), validated against the window grid, or
 * - for app versions that send no start - the window start when the window is
 * exactly one booking long, else the first free start. Null = no valid start.
 */
export function chooseStart(
  requested: number | null,
  starts: readonly number[],
  lengthMs: number,
  busy: ReadonlyArray<readonly [number, number]>,
  now: number,
): { ok: true; start: number } | { ok: false; reason: 'invalid_start' | 'slot_started' | 'time_taken' } {
  const free = (t: number) => t > now && !overlapsAny(t, t + lengthMs, busy);
  if (requested !== null) {
    if (!starts.includes(requested)) return { ok: false, reason: 'invalid_start' };
    if (requested <= now) return { ok: false, reason: 'slot_started' };
    return free(requested) ? { ok: true, start: requested } : { ok: false, reason: 'time_taken' };
  }
  const future = starts.filter((t) => t > now);
  if (future.length === 0) return { ok: false, reason: 'slot_started' };
  const first = future.find(free);
  return first === undefined ? { ok: false, reason: 'time_taken' } : { ok: true, start: first };
}

/** Seats to give back to the slot for the move from -> to (0 or guests). */
export function seatsReleased(from: BookingStatus, to: BookingStatus, guests: number): number {
  return SEAT_HOLDING.has(from) && !SEAT_HOLDING.has(to) ? guests : 0;
}

// ─────────────────────────────────────────────────────────── refund policy

export const CANCELLATION_POLICIES = ['flexible', 'moderate', 'strict'] as const;
export type CancellationPolicy = typeof CANCELLATION_POLICIES[number];
export const DEFAULT_POLICY: CancellationPolicy = 'moderate';

/** Policy enum from an experience doc; anything else (legacy text) -> moderate. */
export function policyOf(experience: Record<string, unknown> | null | undefined): CancellationPolicy {
  const raw = typeof experience?.cancellationPolicy === 'string'
    ? experience.cancellationPolicy.trim()
    : '';
  return (CANCELLATION_POLICIES as readonly string[]).includes(raw)
    ? raw as CancellationPolicy
    : DEFAULT_POLICY;
}

export type CancelledBy = 'guest' | 'host';

/**
 * Percent of the price the guest is owed back.
 *   host cancels                                   -> 100
 *   at / after the start (late, guest no-show)     -> 0
 *   guest, within 24 h of the booking being CONFIRMED
 *     by the host ([bookedAt]) AND the start is still
 *     more than 48 h away (at cancel time)           -> 100 (grace)
 *   flexible  100 until 24 h before, then 0
 *   moderate  100 until 7 days before, 50 until 24 h before, then 0
 *   strict    100 until 7 days before, then 0
 * Boundaries are inclusive in the guest's favour ("until 24 h before" means
 * exactly 24 h before still refunds).
 */
export function refundFor(
  policy: CancellationPolicy | string,
  now: number,
  slotStart: number,
  bookedAt: number,
  by: CancelledBy,
): number {
  if (by === 'host') return 100;
  const toStart = slotStart - now;
  if (toStart <= 0) return 0;
  if (now - bookedAt <= DAY_MS && toStart > 2 * DAY_MS) return 100;
  const p = (CANCELLATION_POLICIES as readonly string[]).includes(policy) ? policy : DEFAULT_POLICY;
  switch (p) {
    case 'flexible':
      return toStart >= DAY_MS ? 100 : 0;
    case 'strict':
      return toStart >= 7 * DAY_MS ? 100 : 0;
    case 'moderate':
    default:
      if (toStart >= 7 * DAY_MS) return 100;
      return toStart >= DAY_MS ? 50 : 0;
  }
}

// ─────────────────────────────────────────────────────────── price math

const ZERO_DECIMAL = new Set([
  'bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga', 'pyg', 'rwf',
  'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf',
]);
const THREE_DECIMAL = new Set(['bhd', 'jod', 'kwd', 'omr', 'tnd']);

/**
 * Symbols the experience editor stores (kExperienceCurrencies in the app:
 * $, €, £, R$, ¥) -> ISO 4217. Without this every paid listing created by the
 * app failed createBooking with experience_price_invalid (currency_missing).
 */
const CURRENCY_SYMBOLS: Record<string, string> = {
  '$': 'usd', 'us$': 'usd', '€': 'eur', '£': 'gbp', 'r$': 'brl', '¥': 'jpy',
};

export function normalizeCurrency(c: unknown): string | null {
  if (typeof c !== 'string') return null;
  const v = c.trim().toLowerCase();
  if (/^[a-z]{3}$/.test(v)) return v;
  return CURRENCY_SYMBOLS[v] ?? null;
}

export function currencyExponent(currency: string): number {
  if (ZERO_DECIMAL.has(currency)) return 0;
  if (THREE_DECIMAL.has(currency)) return 3;
  return 2;
}

/** Major units (as stored on the experience, e.g. 49.9) -> integer minor units. */
export function toMinorUnits(major: number, currency: string): number {
  const f = 10 ** currencyExponent(currency);
  // toFixed first: 19.99 * 100 = 1998.9999999999998 must become 1999.
  return Math.round(Number((major * f).toFixed(6)));
}

export interface BookingPrice {
  unitAmount: number;
  currency: string | null;
  totalAmount: number;
}

export type PriceResult =
  | { ok: true; free: boolean; price: BookingPrice }
  | { ok: false; reason: 'invalid_price' | 'currency_missing' | 'amount_too_large' };

/** Price for [guests] seats, from the EXPERIENCE doc only. */
export function computeBookingPrice(
  experience: Record<string, unknown>,
  guests: number,
): PriceResult {
  const raw = experience.price;
  const priceNum = typeof raw === 'number' && Number.isFinite(raw) ? raw : null;
  const free = experience.isFree === true || priceNum === 0;
  if (free) return { ok: true, free: true, price: { unitAmount: 0, currency: null, totalAmount: 0 } };
  if (priceNum === null || priceNum < 0) return { ok: false, reason: 'invalid_price' };
  const currency = normalizeCurrency(experience.currency);
  if (!currency) return { ok: false, reason: 'currency_missing' };
  const unitAmount = toMinorUnits(priceNum, currency);
  if (unitAmount <= 0) return { ok: false, reason: 'invalid_price' };
  const totalAmount = unitAmount * guests;
  if (!Number.isSafeInteger(totalAmount)) return { ok: false, reason: 'amount_too_large' };
  return { ok: true, free: false, price: { unitAmount, currency, totalAmount } };
}

// ─────────────────────────────────────────────────────────── payment methods

/** How a guest pays a PAID experience (both off-platform). */
export const PAYMENT_METHODS = ['cash', 'link', 'online'] as const;
/** In-app ticket payment providers (ticket_payments/). */
export const ONLINE_PROVIDERS = ['stripe', 'mercadopago', 'link'] as const;
/** Link-mode methods (ticket_payments/config.ts isLinkMethod mirror). */
const LINK_METHODS = ['pix', 'mercadoPago', 'picPay', 'paypal', 'venmo', 'cashApp', 'revolut', 'wise',
  'monzo', 'kofi', 'stripe', 'cash', 'bankTransfer'];
export function linkMethodOf(e: Record<string, unknown>): string | null {
  const m = e.paymentLinkMethod;
  return typeof m === 'string' && LINK_METHODS.includes(m) ? m : null;
}
export function onlineProviderOf(e: Record<string, unknown>): string | null {
  const p = e.paymentProvider;
  return typeof p === 'string' && (ONLINE_PROVIDERS as readonly string[]).includes(p) ? p : null;
}
export type PaymentMethod = typeof PAYMENT_METHODS[number];
export type PaymentMode = 'free' | PaymentMethod;

function hasPaymentLink(e: Record<string, unknown>): boolean {
  const pl = e.paymentLink as Record<string, unknown> | null | undefined;
  return !!pl && typeof pl === 'object' && typeof pl.type === 'string' &&
    typeof pl.value === 'string' && pl.value.trim().length > 0;
}

/**
 * The methods an experience accepts. `paymentMethods` (['cash'] | ['link'] |
 * ['cash','link']) when present and valid; a legacy doc with only a
 * paymentLink -> ['link']. 'link' is only offered while a link exists.
 */
export function acceptedPaymentMethods(e: Record<string, unknown>): PaymentMethod[] {
  const raw = Array.isArray(e.paymentMethods) ? e.paymentMethods : null;
  const listed = raw
    ? PAYMENT_METHODS.filter((m) => raw.includes(m))
    : (hasPaymentLink(e) ? ['link' as const] : []);
  // 'online' (Stripe / Mercado Pago, paid INSIDE the app) needs a provider and
  // replaces every off-platform method: a listing that offers it offers only it.
  if (listed.includes('online')) {
    const p = onlineProviderOf(e);
    return p && (p !== 'link' || linkMethodOf(e)) ? ['online'] : [];
  }
  return listed.filter((m) => m !== 'link' || hasPaymentLink(e));
}

/**
 * Validates the guest's choice for a paid experience. A single accepted
 * method may be omitted (it is implied); with two the guest must choose.
 */
export function choosePaymentMethod(
  e: Record<string, unknown>,
  requested: unknown,
): { ok: true; method: PaymentMethod } | { ok: false; reason: 'payment_method_required' | 'payment_method_not_accepted' | 'no_payment_method' } {
  const accepted = acceptedPaymentMethods(e);
  if (accepted.length === 0) return { ok: false, reason: 'no_payment_method' };
  if (requested === undefined || requested === null || requested === '') {
    return accepted.length === 1
      ? { ok: true, method: accepted[0] }
      : { ok: false, reason: 'payment_method_required' };
  }
  return typeof requested === 'string' && (accepted as string[]).includes(requested)
    ? { ok: true, method: requested as PaymentMethod }
    : { ok: false, reason: 'payment_method_not_accepted' };
}

export interface RefundDue {
  /** What the guest is owed back, as a percent of what they actually paid. */
  percent: number;
  /** The policy band, even when nothing was paid (shown to both parties). */
  policyPercent: number;
  amount: number;
  currency: string | null;
  reason: string;
}

/**
 * The refund OBLIGATION for a booking (GreenGo never executes it).
 *   free                      -> null
 *   link                      -> policy percent of the total; when nobody has
 *                                marked the link payment as made yet, the
 *                                reason ends in `_link_unconfirmed` (owed only
 *                                if the guest did pay)
 *   cash, host has NOT yet confirmed receiving it -> 0 (cash is paid at the
 *                                meeting, so nothing has changed hands)
 *   cash, receipt confirmed   -> policy percent of the total
 */
export function refundDueFor(
  price: BookingPrice | null | undefined,
  payment: Record<string, unknown> | null | undefined,
  percent: number,
  reason: string,
): RefundDue | null {
  const mode = payment?.mode;
  if (mode === 'online') {
    // Refunds are executed by the organizer in their Stripe / MP dashboard; the
    // provider webhook then invalidates the ticket. Owed only once paid.
    if (!price || !(price.totalAmount > 0)) return null;
    const pp = Math.max(0, Math.min(100, Math.round(percent)));
    const paid = payment?.status === 'paid';
    const pct = paid ? pp : 0;
    return {
      percent: pct, policyPercent: pp, amount: Math.round((price.totalAmount * pct) / 100),
      currency: price.currency, reason: paid ? reason : `${reason}_online_unpaid`,
    };
  }
  if (!price || !(price.totalAmount > 0) || (mode !== 'link' && mode !== 'cash')) return null;
  const policyPercent = Math.max(0, Math.min(100, Math.round(percent)));
  const paidCash = mode === 'cash' && !!payment?.hostConfirmedPaidAt;
  const pct = mode === 'cash' && !paidCash ? 0 : policyPercent;
  return {
    percent: pct,
    policyPercent,
    amount: Math.round((price.totalAmount * pct) / 100),
    currency: price.currency,
    reason: mode === 'cash' && !paidCash
      ? `${reason}_cash_unpaid`
      : mode === 'link' && !payment?.guestMarkedPaidAt && !payment?.hostConfirmedPaidAt
        ? `${reason}_link_unconfirmed`
        : reason,
  };
}

// ─────────────────────────────────────────────────────────── time rules

export function requestExpiresAtMs(createdMs: number, slotStartMs: number, cfg: BookingConfig): number {
  return Math.min(createdMs + cfg.requestTtlHours * HOUR_MS, slotStartMs);
}

export function reminderAtMs(slotStartMs: number, cfg: BookingConfig): number {
  return slotStartMs - cfg.reminderLeadHours * HOUR_MS;
}

export function completeAtMs(slotEndMs: number, cfg: BookingConfig): number {
  return slotEndMs + cfg.disputeWindowHours * HOUR_MS;
}

export function canMarkNoShow(now: number, slotStart: number, cfg: BookingConfig): boolean {
  return now >= slotStart + cfg.noShowGraceMinutes * 60 * 1000;
}

export function inCheckInWindow(now: number, slotStart: number, slotEnd: number, cfg: BookingConfig): boolean {
  return now >= slotStart - cfg.checkInEarlyHours * HOUR_MS
    && now <= slotEnd + cfg.checkInLateHours * HOUR_MS;
}

/** Guest may dispute from the start until end + dispute window. */
export function inDisputeWindow(now: number, slotStart: number, slotEnd: number, cfg: BookingConfig): boolean {
  return now >= slotStart && now <= slotEnd + cfg.disputeWindowHours * HOUR_MS;
}

/** Host cancellations inside the window after adding one at [now]. */
export function pruneCancellations(recentMs: number[], now: number, cfg: BookingConfig): number[] {
  const since = now - cfg.hostCancelWindowDays * DAY_MS;
  return [...recentMs.filter((t) => t > since && t <= now), now].sort((a, b) => a - b).slice(-50);
}

/** Flag once per window: at the limit and not flagged within the window. */
export function shouldFlagHost(
  recentMs: number[],
  flaggedAtMs: number | null,
  now: number,
  cfg: BookingConfig,
): boolean {
  if (recentMs.length < cfg.hostCancelLimit) return false;
  return flaggedAtMs === null || flaggedAtMs <= now - cfg.hostCancelWindowDays * DAY_MS;
}

// ─────────────────────────────────────────────────────────── identity

/** Deterministic booking id for (guest, client requestId): retries hit the same doc. */
export function bookingIdFor(guestId: string, requestId: string): string {
  return 'bk_' + crypto.createHash('sha256').update(`${guestId}:${requestId}`).digest('hex').slice(0, 28);
}

const B32 = 'ABCDEFGHJKMNPQRSTVWXYZ0123456789'; // no I, L, O, U (readable aloud)

/** 8-character check-in code = HMAC-SHA256(secret, bookingId), base-32. */
export function checkInCode(secret: string, bookingId: string): string {
  const mac = crypto.createHmac('sha256', secret).update(`checkin:${bookingId}`).digest();
  let out = '';
  for (let i = 0; i < 8; i++) out += B32[mac[i] % 32];
  return out;
}

export function verifyCheckInCode(secret: string, bookingId: string, given: unknown): boolean {
  if (typeof given !== 'string') return false;
  const g = given.trim().toUpperCase();
  const want = checkInCode(secret, bookingId);
  if (g.length !== want.length) return false;
  return crypto.timingSafeEqual(Buffer.from(g), Buffer.from(want));
}

/** What the guest's app encodes as a QR code. */
export function checkInQrPayload(bookingId: string, code: string): string {
  return `greengo:checkin:${bookingId}:${code}`;
}

// ─────────────────────────────────────────────────────────── profile reads

/**
 * Identity document of a profile, read defensively:
 *   'approved'  isAgeVerified / ageVerification.status 'verified' (both
 *               protected by the profile rules: only the document-verification
 *               functions write them);
 *   'uploaded'  ageVerification.status pending (submitted, under review);
 *   'none'      anything else (missing = false).
 * `profiles.idVerified` is deliberately NOT trusted: the profile rules do not
 * protect it, so an owner could set it on their own profile.
 */
export function idDocumentStateOf(profile: Record<string, any> | null | undefined): 'none' | 'uploaded' | 'approved' {
  if (!profile) return 'none';
  if (profile.isAgeVerified === true) return 'approved';
  const s = profile.ageVerification?.status;
  if (s === 'verified') return 'approved';
  if (s === 'pending') return 'uploaded';
  return 'none';
}

export function isBannedProfile(d: Record<string, unknown> | null | undefined): boolean {
  if (!d) return false;
  if (d.isBanned === true || d.banned === true) return true;
  return d.accountStatus === 'banned' || d.accountStatus === 'suspended';
}

// ─────────────────────────────────────────────────────────── input validation

const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;
const REQ_RE = /^[A-Za-z0-9_-]{8,64}$/;

export function isDocId(v: unknown): v is string {
  return typeof v === 'string' && ID_RE.test(v);
}

export function isRequestId(v: unknown): v is string {
  return typeof v === 'string' && REQ_RE.test(v);
}

export function cleanText(v: unknown, max: number): string | null {
  if (typeof v !== 'string') return null;
  const s = v.trim();
  return s.length === 0 ? null : s.slice(0, max);
}

export const HOST_ACTIONS = ['none', 'warn', 'suspend_hosting', 'hide_listing'] as const;
export type HostAction = typeof HOST_ACTIONS[number];

// ─────────────────────────────────────────────────────────── reviews

export interface RatingTotals {
  guestRatingSum: number;
  guestRatingCount: number;
  guestRatingAvg: number;
}

/** What one guest review contributes to the guest's totals (visible only). */
export function guestReviewContribution(r: Record<string, unknown> | null | undefined): { sum: number; count: number } {
  if (!r || r.status !== 'visible') return { sum: 0, count: 0 };
  const v = r.rating;
  if (typeof v !== 'number' || !Number.isInteger(v) || v < 1 || v > 5) return { sum: 0, count: 0 };
  return { sum: v, count: 1 };
}

export function guestRatingDelta(
  before: Record<string, unknown> | null | undefined,
  after: Record<string, unknown> | null | undefined,
): { sum: number; count: number } {
  const b = guestReviewContribution(before);
  const a = guestReviewContribution(after);
  return { sum: a.sum - b.sum, count: a.count - b.count };
}

/** Applies a delta to profile totals; clamped at 0. */
export function applyGuestRatingDelta(
  profile: Record<string, unknown> | null | undefined,
  delta: { sum: number; count: number },
): RatingTotals {
  const num = (x: unknown) => (typeof x === 'number' && Number.isFinite(x) ? x : 0);
  const p = profile ?? {};
  const count = Math.max(0, num(p.guestRatingCount) + delta.count);
  const sum = count === 0 ? 0 : Math.max(0, num(p.guestRatingSum) + delta.sum);
  return {
    guestRatingSum: sum,
    guestRatingCount: count,
    guestRatingAvg: count === 0 ? 0 : Math.round((sum / count) * 100) / 100,
  };
}

/** A booking the host may review the guest for / the guest may review the experience for. */
export function bookingReviewable(b: Record<string, any>, side: 'host' | 'guest'): boolean {
  if (b.status === 'completed') return true;
  if (b.status === 'confirmed' && b.checkIn) return true;
  return side === 'host' && b.status === 'no_show';
}
