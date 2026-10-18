/**
 * Guest booking from a shared link — pure rules (no Firestore / network), so
 * every decision is unit-testable. See ./index.ts for the flow.
 *
 * Who is a guest: someone who opened a shared /e/{id}, /x/{id} or /a/{id}
 * link and chose "Continue as guest". They only ever see THAT page, rendered
 * by the server; they never get Firestore access.
 *
 * Bookable by a guest (all must hold):
 *   - the listing is viewable by a guest ([guestViewBlock]): exists, live /
 *     published, not taken down (copyright / safety / moderation / deleted),
 *     not hidden by a plan downgrade (hiddenByDowngrade, Track 2), and for
 *     events PUBLIC (visibility != 'private');
 *   - the host switched `guestsAllowed: true` on (default OFF; only settable
 *     on public events, enforced in firestore.rules too);
 *   - events: not cancelled / ended, no approval / age / gender gate the
 *     server cannot verify for an anonymous guest, and paid ONLY through the
 *     instant checkout (Stripe / Mercado Pago) — never the "link" mode;
 *   - experiences: free, or paid online through Stripe / Mercado Pago.
 */
import * as crypto from 'crypto';
import { isTakenDown, millis, str } from '../share/sharePreviewCore';
import { MAX_TICKETS_PER_BUYER } from '../ticket_payments/config';

export type GuestKind = 'e' | 'x' | 'a';
export const GUEST_KINDS: readonly GuestKind[] = ['e', 'x', 'a'];
export const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

/** Hosts a guest form may be posted from (Origin / Referer check). */
export const ALLOWED_ORIGINS = [
  'https://greengo-chat.web.app',
  'https://greengo-chat.firebaseapp.com',
];

export const LIMITS = {
  nameMax: 60,
  emailMax: 254,
  /** Tickets per guest order (also capped by the listing's per-buyer limit). */
  maxTickets: 10,
  /** Form token lifetime and the minimum time a human needs to fill it in. */
  formTtlMs: 2 * 60 * 60 * 1000,
  formMinAgeMs: 1500,
  /** Rate limits (fixed windows, see guestService.takeGuestRateLimit). */
  perIpPerHour: 20,
  perEmailPerHour: 8,
  /** Backstop against seat-hold flooding of one listing from many IPs. */
  perListingPerHour: 240,
  /** guest_contacts retention after the guest's last booking. */
  contactRetentionDays: 400,
};

// ─────────────────────────────────────────────────────────── input

export interface GuestInput {
  firstName: string;
  lastName: string;
  email: string;
}

export type InputError = 'name' | 'email' | 'consent';

const NAME_RE = /^[\p{L}\p{M}](?:[\p{L}\p{M}'’ .-]*[\p{L}\p{M}.])?$/u;
const EMAIL_RE =
  /^[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$/;

/** Collapses whitespace; strips control / bidi characters. */
export function cleanName(v: unknown): string {
  if (typeof v !== 'string') return '';
  return v
    .replace(/[\u0000-\u001F\u007F-\u009F​-‏‪-‮⁦-⁩]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

export function isValidName(v: string): boolean {
  return v.length >= 1 && v.length <= LIMITS.nameMax && NAME_RE.test(v);
}

export function isValidGuestEmail(v: string): boolean {
  return v.length <= LIMITS.emailMax && EMAIL_RE.test(v) && !v.includes('..');
}

/** Validates the posted form; returns the clean input or the first error. */
export function parseGuestInput(body: Record<string, unknown>):
  { ok: true; input: GuestInput } | { ok: false; error: InputError; input: GuestInput } {
  const input: GuestInput = {
    firstName: cleanName(body.firstName),
    lastName: cleanName(body.lastName),
    email: typeof body.email === 'string' ? body.email.trim().slice(0, LIMITS.emailMax + 1) : '',
  };
  if (!isValidName(input.firstName) || !isValidName(input.lastName)) return { ok: false, error: 'name', input };
  if (!isValidGuestEmail(input.email)) return { ok: false, error: 'email', input };
  if (body.consent !== 'on' && body.consent !== 'true' && body.consent !== '1') return { ok: false, error: 'consent', input };
  return { ok: true, input };
}

/** Integer form field in [min, max], else null. */
export function intField(v: unknown, min: number, max: number): number | null {
  const s = typeof v === 'string' ? v.trim() : typeof v === 'number' ? String(v) : '';
  if (!/^\d{1,4}$/.test(s)) return null;
  const n = Number(s);
  return n >= min && n <= max ? n : null;
}

/** "a***@example.com" (shown back on the result page, never logged). */
export function maskGuestEmail(email: string): string {
  const [user, domain] = email.split('@');
  if (!user || !domain) return '***';
  return `${user[0]}***@${domain}`;
}

// ─────────────────────────────────────────────────────────── listings

export type Block =
  | 'not_found' | 'hidden'
  | 'guests_not_allowed' | 'ended' | 'not_on_sale' | 'app_only';

/** Can a guest SEE this listing? null = yes. */
export function guestViewBlock(kind: GuestKind, d: Record<string, unknown> | undefined | null, now: number): Block | null {
  if (!d) return 'not_found';
  if (isTakenDown(d)) return 'hidden';
  if (d.hiddenByDowngrade === true) return 'hidden';
  const status = str(d.status);
  if (kind === 'e') {
    if (status === 'draft') return 'hidden';
    if (status === 'scheduled' && millis(d.publishAt) > now) return 'hidden';
    if (str(d.visibility) === 'private') return 'hidden';
    return null;
  }
  return status === 'published' ? null : 'hidden';
}

/** Event / experience end (ms), else start, else null. */
export function listingEndMs(kind: GuestKind, d: Record<string, unknown>): number | null {
  if (kind !== 'e') return null;
  const end = millis(d.endDate) || millis(d.startDate);
  return end > 0 ? end : null;
}

export type EventSale = 'free' | 'instant' | 'link';

/** How an event is sold: free RSVP, instant checkout, or organizer-confirmed link. */
export function eventSale(d: Record<string, unknown>): EventSale {
  const provider = d.ticketProvider;
  const price = d.price;
  if (provider === 'stripe' || provider === 'mercadopago') return 'instant';
  if (provider != null) return 'link';
  return typeof price === 'number' && price > 0 ? 'link' : 'free';
}

/** Experience payment for a guest: free, instant (Stripe / MP), or not for guests. */
export function experienceSale(d: Record<string, unknown>): 'free' | 'instant' | 'app_only' {
  if (d.isFree === true) return 'free';
  const methods = Array.isArray(d.paymentMethods) ? d.paymentMethods : [];
  const online = methods.includes('online') && (d.paymentProvider === 'stripe' || d.paymentProvider === 'mercadopago');
  return online ? 'instant' : 'app_only';
}

/**
 * Can a guest BOOK this listing right now? null = yes. Attractions are never
 * bookable (read-only page).
 */
export function guestBookBlock(kind: GuestKind, d: Record<string, unknown> | undefined | null, now: number): Block | null {
  const view = guestViewBlock(kind, d, now);
  if (view) return view;
  if (kind === 'a') return 'not_on_sale';
  const l = d as Record<string, unknown>;
  if (l.guestsAllowed !== true) return 'guests_not_allowed';
  if (kind === 'e') {
    const status = str(l.status);
    if (status === 'cancelled' || status === 'completed') return 'not_on_sale';
    const end = listingEndMs(kind, l);
    if (end !== null && end < now) return 'ended';
    // Gates the server cannot check for an anonymous guest.
    if (l.requiresApproval === true) return 'app_only';
    if (typeof l.minAge === 'number' || typeof l.maxAge === 'number') return 'app_only';
    if (str(l.genderPreference) && str(l.genderPreference) !== 'any') return 'app_only';
    if (Array.isArray(l.ticketTiers) && l.ticketTiers.length > 0) return 'app_only';
    if (eventSale(l) === 'link') return 'app_only';
    return null;
  }
  return experienceSale(l) === 'app_only' ? 'app_only' : null;
}

/** Seats left on an event (null = unlimited). */
export function eventSeatsLeft(d: Record<string, unknown>, held: number): number | null {
  const max = Math.floor(Number(d.maxAttendees) || 0);
  if (max <= 0) return null;
  const going = Math.max(0, Math.floor(Number(d.attendeeCount) || 0));
  return Math.max(0, max - going - Math.max(0, held));
}

/**
 * Per-order ticket cap for a guest (paid events): the listing's per-buyer
 * limit, never above MAX_TICKETS_PER_BUYER (owner rule 2026-10-18: 4 per
 * e-mail per event, re-checked in createTicketCheckout against the guest's
 * earlier orders), the seats left and LIMITS.maxTickets. Plus-ones
 * (guestsAllowedPerAttendee) do not apply to paid events: every person
 * holds a ticket.
 */
export function guestTicketCap(d: Record<string, unknown>, seatsLeft: number | null): number {
  let cap = Math.min(LIMITS.maxTickets, MAX_TICKETS_PER_BUYER);
  if (Number.isInteger(d.maxTicketsPerUser) && (d.maxTicketsPerUser as number) > 0) {
    cap = Math.min(cap, d.maxTicketsPerUser as number);
  }
  if (seatsLeft !== null) cap = Math.min(cap, seatsLeft);
  return Math.max(0, cap);
}

// ─────────────────────────────────────────────────────────── signed tokens

function sig(key: string, msg: string): string {
  return crypto.createHmac('sha256', key).update(msg).digest('base64url').slice(0, 22);
}

function safeEq(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}

/**
 * Form token embedded in the guest form: "{issuedMs}.{nonce}.{sig}" bound to
 * the listing. Proves the POST comes from a form we rendered (with the
 * Origin check: CSRF), carries a minimum fill time, expires, and its nonce is
 * the idempotency key of the submission.
 */
export function signFormToken(key: string, kind: GuestKind, id: string, nowMs: number, nonce?: string): string {
  const n = nonce ?? crypto.randomBytes(12).toString('base64url');
  const body = `${nowMs}.${n}`;
  return `${body}.${sig(key, `gform:v1:${kind}:${id}:${body}`)}`;
}

export function verifyFormToken(
  key: string, kind: GuestKind, id: string, token: unknown, nowMs: number,
): { ok: true; nonce: string } | { ok: false; reason: 'invalid' | 'expired' | 'too_fast' } {
  if (typeof token !== 'string' || token.length > 120) return { ok: false, reason: 'invalid' };
  const parts = token.split('.');
  if (parts.length !== 3) return { ok: false, reason: 'invalid' };
  const [issued, nonce, s] = parts;
  if (!/^\d{10,16}$/.test(issued) || !/^[A-Za-z0-9_-]{8,32}$/.test(nonce)) return { ok: false, reason: 'invalid' };
  if (!safeEq(s, sig(key, `gform:v1:${kind}:${id}:${issued}.${nonce}`))) return { ok: false, reason: 'invalid' };
  const age = nowMs - Number(issued);
  if (age < LIMITS.formMinAgeMs) return { ok: false, reason: 'too_fast' };
  if (age > LIMITS.formTtlMs) return { ok: false, reason: 'expired' };
  return { ok: true, nonce };
}

/** Capability for the guest's own payment-return page of [orderId]. */
export function returnSig(key: string, orderId: string): string {
  return sig(key, `gret:v1:${orderId}`);
}

/** Capability for the "pay now" link of an accepted guest booking. */
export function paySig(key: string, bookingId: string): string {
  return sig(key, `gpay:v1:${bookingId}`);
}

export function checkSig(expected: string, given: unknown): boolean {
  return typeof given === 'string' && given.length <= 64 && safeEq(given, expected);
}

/**
 * CSRF: a guest form POST must come from our own pages. Browsers send Origin
 * on form POSTs; when a privacy setting strips it, the Referer must match.
 */
export function originAllowed(origin: unknown, referer: unknown, extra: string[] = []): boolean {
  const allowed = [...ALLOWED_ORIGINS, ...extra];
  if (typeof origin === 'string' && origin && origin !== 'null') return allowed.includes(origin);
  if (typeof referer !== 'string' || !referer) return false;
  try {
    return allowed.includes(new URL(referer).origin);
  } catch {
    return false;
  }
}

/** Salted, truncated hash for rate-limit keys (no raw IP / e-mail stored). */
export function rateKey(kind: string, value: string): string {
  return crypto.createHash('sha256').update(`greengo-guest-v1:${kind}:${value}`).digest('hex').slice(0, 40);
}

// ─────────────────────────────────────────────────────────── routing

export type GuestRoute =
  | { route: 'listing'; kind: GuestKind; id: string }
  | { route: 'done'; id: string }
  | { route: 'pay'; id: string };

/**
 * /guest/{e|x|a}/{id} | /guest/done/{orderId} | /guest/pay/{bookingId}
 * (the leading "guest" segment is optional: direct function URL). Anything
 * else, or a malformed id, is null.
 */
export function parseGuestPath(path: string): GuestRoute | null {
  const parts = path.split('/').filter(Boolean);
  if (parts[0] === 'guest') parts.shift();
  if (parts.length !== 2) return null;
  let id: string;
  try {
    id = decodeURIComponent(parts[1]);
  } catch {
    return null;
  }
  if (!ID_RE.test(id)) return null;
  if (parts[0] === 'done') return { route: 'done', id };
  if (parts[0] === 'pay') return { route: 'pay', id };
  return (GUEST_KINDS as readonly string[]).includes(parts[0]) ? { route: 'listing', kind: parts[0] as GuestKind, id } : null;
}

/** Best-effort client IP for rate limiting (same source order as copyright/web.ts). */
export function clientIp(headers: Record<string, unknown>, fallback?: string): string {
  const fastly = typeof headers['fastly-client-ip'] === 'string' ? headers['fastly-client-ip'] : '';
  if (fastly) return fastly.trim().slice(0, 64);
  const xf = String(headers['x-forwarded-for'] || '').split(',')[0].trim();
  return (xf || fallback || 'unknown').slice(0, 64);
}
