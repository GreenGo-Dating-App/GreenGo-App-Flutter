/**
 * Guest booking — server operations behind the `guestBooking` HTTPS function
 * (./index.ts). Each handler returns a ready response ({ status, html }); no
 * handler ever logs a name or an e-mail address.
 *
 *   GET  /guest/{e|x|a}/{id}         read-only guest view (+ form when bookable)
 *   POST /guest/{e|x}/{id}           book: free event RSVP | instant checkout | experience request
 *   GET  /guest/done/{orderId}?t=&r= payment return (capability t)
 *   GET  /guest/pay/{bookingId}?t=   "pay now" page of an accepted request (capability t)
 *   POST /guest/pay/{bookingId}      start that payment
 *
 * Data written for a guest (minimal PII, see docs in ./index.ts):
 *   guest_contacts/{guestKey}   { email, locale, updatedAt, expireAt }   server-only
 *   ticket_orders / tickets / ticket_holdings   buyerId = guestKey, isGuest, guest{firstName,lastName}, guestName
 *   events/{id}/attendees/{guestKey}   userName "First Last", isGuest: true, no photo
 *   bookings/{id}               guestId = guestKey, isGuest, guest{...}, guestName
 *   guest_rate_limits/{hash}    fixed-window counters (hashed keys)          server-only
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { AppLocale } from '../shared/i18n';
import {
  GUEST_CONTACTS, GuestBuyer, guestDisplayName, guestKeyFor, normalizeGuestEmail,
} from '../shared/guestIdentity';
import {
  HOST, clip, formatPrice, mainExperiencePhoto, safeImageUrl, scrubContactInfo, str,
  buildAttractionPreview, DEFAULT_ATTRACTION_BUCKET,
} from '../share/sharePreviewCore';
import { formatWhen, hostTimeZone, joinPlace, millis } from '../emails/emailFormat';
import {
  OPEN_STATUSES, TICKET_TYPES, cancelTicketOrder, createTicketCheckout, inventoryRef, isoCurrency,
  syncOrderWithProvider, typeSaleError,
} from '../ticket_payments/orders';
import { toMajor } from '../ticket_payments/currency';
import { currentPhaseIndex, phaseName, phasesLeft, readPricePhases, validatePricePhases } from '../ticket_payments/pricePhases';
import { AttendeeName, parseAttendeeNames, requiresAttendeeNames } from '../ticket_payments/ticketRules';
import { MAX_TICKETS_PER_BUYER } from '../ticket_payments/config';
import { createBooking, loadConfig } from '../experience_bookings/service';
import { getExperienceAvailability } from '../experience_bookings/availability';
import { gt, GuestKey } from './guestI18n';
import {
  Block, GuestInput, GuestKind, LIMITS, checkSig, eventSale, eventSeatsLeft, experienceSale, guestBookBlock,
  guestTicketCap, guestViewBlock, intField, maskGuestEmail, parseGuestInput, paySig, rateKey, returnSig,
  signFormToken, verifyFormToken,
} from './guestModel';
import {
  FormView, ListingView, renderListingPage, renderMessagePage, renderPayPage, renderRedirectPage,
  renderUnavailablePage,
} from './guestPages';
import { guestIdentitySecret, guestSigningKey } from './guestKeys';
import { sendGuestRsvpTicket } from './guestEmails';

const db = () => guestDeps.db();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
export const GUEST_RATE_LIMITS = 'guest_rate_limits';
const HOUR = 3600 * 1000;
const DAY = 24 * HOUR;
const OPEN = new Set<string>(OPEN_STATUSES);

export interface PageResponse { status: number; html: string }

/** Overridable in tests. */
export const guestDeps = {
  db: (): FirebaseFirestore.Firestore => admin.firestore(),
  now: (): number => Date.now(),
};

// ─────────────────────────────────────────────────────────── small helpers

export class GuestError extends Error {
  constructor(public readonly key: GuestKey, public readonly status = 400) { super(key); }
}

/** Server refusal reason (HttpsError details.code) -> what we tell the guest. */
export function errorKeyFor(reason: string): GuestKey {
  switch (reason) {
    case 'sold_out': case 'ticket_type_sold_out': case 'slot_full':
      return 'guest.err.soldOut';
    case 'ticket_limit_reached':
      return 'guest.err.ticketLimit';
    case 'attendee_names_required':
      return 'guest.err.attendeeNames';
    case 'ticket_type_limit_reached': case 'already_booked':
    case 'already_has_ticket': case 'own_listing': case 'own_experience': case 'request_id_conflict':
      return 'guest.err.limit';
    case 'time_taken': case 'slot_closed': case 'slot_not_found': case 'slot_invalid': case 'invalid_start':
    case 'no_free_start': case 'too_soon': case 'outside_window':
      return 'guest.err.slot';
    case 'organizer_payments_not_ready': case 'provider_unavailable': case 'payments_not_configured':
    case 'currency_not_supported': case 'below_minimum': case 'currency_missing':
      return 'guest.err.payment';
    case 'invalid_items': case 'invalid_quantity':
      return 'guest.err.quantity';
    default:
      return 'guest.err.unavailable';
  }
}

function reasonOf(e: unknown): string {
  if (e instanceof HttpsError) {
    const d = e.details as Record<string, unknown> | undefined;
    return typeof d?.code === 'string' ? d.code : e.message;
  }
  return 'internal';
}

/** Only the providers' hosted checkout pages are ever redirected to. */
export function isProviderCheckoutUrl(u: unknown): u is string {
  if (typeof u !== 'string' || u.length > 2048) return false;
  try {
    const url = new URL(u);
    if (url.protocol !== 'https:') return false;
    return /(^|\.)stripe\.com$/.test(url.hostname)
      || /(^|\.)mercadopago\.(com|com\.[a-z]{2}|[a-z]{2})$/.test(url.hostname);
  } catch {
    return false;
  }
}

/** Fixed-window counter (hashed key, TTL field). false = over the limit. */
export async function takeGuestRateLimit(kind: string, value: string, limit: number, windowMs = HOUR): Promise<boolean> {
  const ref = db().collection(GUEST_RATE_LIMITS).doc(rateKey(kind, value));
  const now = guestDeps.now();
  return db().runTransaction(async (tx) => {
    const d = (await tx.get(ref)).data();
    const fresh = !d || now - (Number(d.windowStartMs) || 0) >= windowMs;
    const count = fresh ? 1 : (Number(d!.count) || 0) + 1;
    tx.set(ref, { windowStartMs: fresh ? now : d!.windowStartMs, count, expireAt: ts(now + 2 * windowMs) });
    return count <= limit;
  });
}

/** guest_contacts/{key}: the ONLY place a guest's e-mail is stored. */
async function upsertContact(key: string, email: string, locale: AppLocale): Promise<void> {
  const now = guestDeps.now();
  await db().collection(GUEST_CONTACTS).doc(key).set({
    email: normalizeGuestEmail(email),
    locale,
    updatedAt: ts(now),
    // Firestore TTL policy on expireAt: dropped LIMITS.contactRetentionDays
    // after the guest's last booking (orders keep the name for accounting).
    expireAt: ts(now + LIMITS.contactRetentionDays * DAY),
  }, { merge: true });
}

/** The guest's payment-return page (capability t = HMAC of the order id). */
export function guestReturnUrl(key: string, orderId: string, r: string, locale: AppLocale): string {
  return `${HOST}/guest/done/${encodeURIComponent(orderId)}?r=${r}&t=${returnSig(key, orderId)}&hl=${encodeURIComponent(locale)}`;
}

function buyerFor(first: string, last: string, key: string, locale: AppLocale): GuestBuyer {
  return { firstName: first, lastName: last, returnUrl: (r, orderId) => guestReturnUrl(key, orderId, r, locale) };
}

function providerName(p: unknown): string | undefined {
  return p === 'stripe' ? 'Stripe' : p === 'mercadopago' ? 'Mercado Pago' : undefined;
}

function noticeKey(b: Block): GuestKey | null {
  switch (b) {
    case 'guests_not_allowed': return 'guest.notice.notAllowed';
    case 'ended': return 'guest.notice.ended';
    case 'not_on_sale': return 'guest.notice.notOnSale';
    case 'app_only': return 'guest.notice.appOnly';
    default: return null;
  }
}

// ─────────────────────────────────────────────────────────── listing page

const COL: Record<GuestKind, string> = { e: 'events', x: 'user_experiences', a: 'attractions' };

let attractionBucket: Promise<string> | null = null;
function getAttractionBucket(): Promise<string> {
  attractionBucket ??= db().collection('attraction_config').doc('app').get()
    .then((d) => {
      const b = d.get('storageBucket');
      return typeof b === 'string' && b.trim() ? b.trim() : DEFAULT_ATTRACTION_BUCKET;
    })
    .catch(() => { attractionBucket = null; return DEFAULT_ATTRACTION_BUCKET; });
  return attractionBucket;
}

interface Loaded {
  d: Record<string, any>;
  held: number;
  /** ticket_inventory/event_{id}.phaseSold (price phases), {} otherwise. */
  phaseSold: Record<string, number>;
  types: Array<{ id: string; t: Record<string, any> }>;
}

async function loadListing(kind: GuestKind, id: string): Promise<Loaded | null> {
  const ref = db().collection(COL[kind]).doc(id);
  const snap = await ref.get();
  if (!snap.exists) return null;
  const d = snap.data() as Record<string, any>;
  let held = 0;
  let phaseSold: Record<string, number> = {};
  let types: Loaded['types'] = [];
  if (kind === 'e' && eventSale(d) === 'instant') {
    const [inv, ty] = await Promise.all([inventoryRef(id).get(), ref.collection(TICKET_TYPES).limit(20).get()]);
    held = Number(inv.data()?.held) || 0;
    phaseSold = (inv.data()?.phaseSold || {}) as Record<string, number>;
    types = ty.docs.map((x) => ({ id: x.id, t: x.data() }));
  }
  return { d, held, phaseSold, types };
}

/** Upcoming start times a guest may request (recurring rules + one-off slots), max 40. */
async function experienceSlots(id: string, d: Record<string, any>, locale: AppLocale, now: number): Promise<Array<{ value: string; label: string }>> {
  const tz = hostTimeZone(d);
  const out: Array<{ ms: number; value: string }> = [];
  try {
    const r = await getExperienceAvailability('', {
      experienceId: id, from: new Date(now).toISOString(), to: new Date(now + 30 * DAY).toISOString(),
    }, now);
    for (const s of (r.slots as Array<Record<string, any>>) || []) {
      const ms = Date.parse(String(s.start));
      if (Number.isFinite(ms)) out.push({ ms, value: `r_${ms}` });
    }
  } catch { /* no rules */ }
  try {
    const one = await db().collection(COL.x).doc(id).collection('slots')
      .where('start', '>=', ts(now)).orderBy('start').limit(30).get();
    for (const s of one.docs) {
      if (s.data().status !== 'open') continue;
      const ms = millis(s.data().start);
      if (ms !== null) out.push({ ms, value: `s_${s.id}` });
    }
  } catch { /* no one-off slots */ }
  out.sort((a, b) => a.ms - b.ms);
  return out.slice(0, 40).map((s) => ({ value: s.value, label: formatWhen(s.ms, tz, locale) }));
}

function priceLabel(amountMajor: number, currency: string | null, locale: AppLocale): string {
  return amountMajor > 0 ? (formatPrice(amountMajor, currency, locale) || String(amountMajor)) : gt(locale, 'guest.page.free');
}

/** Builds the view model of the guest page (pure apart from the slot lookup). */
async function listingView(
  kind: GuestKind, id: string, L: Loaded, locale: AppLocale, now: number,
  extra: { error?: string | null; values?: Partial<GuestInput>; attendeeValues?: AttendeeName[] } = {},
): Promise<ListingView> {
  const d = L.d;
  const facts: Array<[string, string]> = [];
  let title = '';
  let description = '';
  let imageUrl: string | null = null;
  let seatsLeft: number | null = null;
  let form: FormView | null = null;
  let noTimes = false;
  const block = guestBookBlock(kind, d, now);
  const key = await guestSigningKey();
  const token = signFormToken(key, kind, id, now);

  if (kind === 'a') {
    const p = buildAttractionPreview(id, d, await getAttractionBucket(), locale);
    title = p.title;
    imageUrl = p.imageUrl;
    description = clip(str(d.descriptionMedium) || p.description, 1500);
    const place = joinPlace([d.cityName, d.countryName]);
    if (place) facts.push([gt(locale, 'guest.page.where'), place]);
  } else if (kind === 'e') {
    title = str(d.title) || 'GreenGo';
    description = clip(scrubContactInfo(str(d.description)), 1500);
    imageUrl = safeImageUrl(d.imageUrl);
    facts.push([gt(locale, 'guest.page.when'), formatWhen(millis(d.startDate), hostTimeZone(d), locale)]);
    const place = joinPlace([d.locationName, d.address, d.city]);
    if (place) facts.push([gt(locale, 'guest.page.where'), place]);
    const host = str(d.organizerName);
    if (host && host !== 'Current User') facts.push([gt(locale, 'guest.page.host'), host]);
    const sale = eventSale(d);
    const cur = isoCurrency(d.currencyCode, d.currency);
    // Price phases (ticket_payments/pricePhases.ts): the CURRENT phase's
    // price and the tickets left across phases (createTicketCheckout prices
    // the order again).
    const rawPhases = L.types.length || sale === 'free' ? null : readPricePhases(d.pricePhases);
    const pv = rawPhases && cur ? validatePricePhases(rawPhases, Math.floor(Number(d.maxAttendees) || 0), cur) : null;
    const phases = pv && pv.ok ? pv.phases : null;
    const curIdx = phases ? currentPhaseIndex(phases, L.phaseSold) : -1;
    if (sale === 'free') facts.push([gt(locale, 'guest.page.price'), gt(locale, 'guest.page.free')]);
    else if (phases && curIdx >= 0) {
      facts.push([gt(locale, 'guest.page.price'),
        `${priceLabel(phases[curIdx].price, cur ? cur.toUpperCase() : null, locale)} · ${phaseName(phases[curIdx].nameKey, locale)}`]);
    } else if (!L.types.length && typeof d.price === 'number') {
      facts.push([gt(locale, 'guest.page.price'), priceLabel(d.price, cur ? cur.toUpperCase() : null, locale)]);
    }
    seatsLeft = eventSeatsLeft(d, L.held);
    if (phases) {
      const phaseLeft = phasesLeft(phases, L.phaseSold).reduce((a, b) => a + b, 0);
      seatsLeft = seatsLeft === null ? phaseLeft : Math.min(seatsLeft, phaseLeft);
    }
    if (!block && seatsLeft !== 0) {
      if (sale === 'free') {
        form = { mode: 'free', action: `/guest/e/${encodeURIComponent(id)}`, token };
      } else {
        const cap = guestTicketCap(d, seatsLeft);
        const types = L.types
          .filter((x) => !typeSaleError(x.t, now))
          .map((x) => {
            const stock = x.t.quantity === null || x.t.quantity === undefined
              ? cap : Math.max(0, Number(x.t.quantity) - (Number(x.t.sold) || 0) - (Number(x.t.held) || 0));
            const per = Number.isInteger(x.t.maxPerUser) && x.t.maxPerUser > 0 ? x.t.maxPerUser : cap;
            const priceMinor = Number(x.t.price) || 0;
            const label = `${clip(String(x.t.name || 'Ticket'), 60)} · ${priceLabel(cur ? toMajor(priceMinor, cur) : 0, cur ? cur.toUpperCase() : null, locale)}`;
            return { id: x.id, label, max: Math.max(0, Math.min(cap, stock, per)) };
          })
          .filter((x) => x.max > 0);
        if (L.types.length ? types.length : cap > 0) {
          form = {
            mode: 'pay', action: `/guest/e/${encodeURIComponent(id)}`, token,
            ...(L.types.length ? { types } : { quantityMax: cap }),
            provider: providerName(d.ticketProvider),
            // "Ask for attendee names": one name per ticket (ticket 1 = the guest).
            ...(requiresAttendeeNames(d) ? { attendeeNames: L.types.length ? Math.min(cap, MAX_TICKETS_PER_BUYER) : cap } : {}),
          };
        }
      }
    }
  } else {
    title = str(d.title) || 'GreenGo';
    description = clip(scrubContactInfo(str(d.description)), 1500);
    imageUrl = mainExperiencePhoto(d);
    const place = joinPlace([d.meetingPoint, d.locationName, d.city]);
    if (place) facts.push([gt(locale, 'guest.page.where'), place]);
    const host = str(d.hostName);
    if (host) facts.push([gt(locale, 'guest.page.host'), host]);
    const sale = experienceSale(d);
    const cur = str(d.currency).toUpperCase() || null;
    const price = d.isFree === true
      ? gt(locale, 'guest.page.free')
      : d.pricingMode === 'per_group' && typeof d.groupPrice === 'number'
        ? priceLabel(toMajor(d.groupPrice, (cur || 'usd').toLowerCase()), cur, locale)
        : typeof d.price === 'number' ? priceLabel(d.price, cur, locale) : '';
    if (price) facts.push([gt(locale, 'guest.page.price'), price]);
    if (!block) {
      const slots = await experienceSlots(id, d, locale, now);
      const cfg = await loadConfig();
      const max = Math.min(cfg.maxGuestsPerBooking, Number.isInteger(d.maxGroupSize) ? d.maxGroupSize : LIMITS.maxTickets, LIMITS.maxTickets);
      const min = Number.isInteger(d.minGroupSize) && d.minGroupSize > 1 ? d.minGroupSize : 1;
      if (slots.length && min <= max) {
        form = {
          mode: 'request', action: `/guest/x/${encodeURIComponent(id)}`, token, slots, partyMin: min, partyMax: max,
          provider: sale === 'instant' ? providerName(d.paymentProvider) : undefined,
        };
      } else {
        noTimes = true;
      }
    }
  }
  const nk: GuestKey | null = block ? noticeKey(block) : noTimes ? 'guest.notice.noTimes' : null;
  return {
    kind, id, locale, title: clip(title, 120), description, imageUrl, facts, seatsLeft,
    notice: nk ? gt(locale, nk) : null,
    form, error: extra.error ?? null, values: extra.values, attendeeValues: extra.attendeeValues,
  };
}

/** GET /guest/{kind}/{id} */
export async function guestListingPage(kind: GuestKind, id: string, locale: AppLocale): Promise<PageResponse> {
  const now = guestDeps.now();
  const L = await loadListing(kind, id).catch(() => null);
  if (!L || guestViewBlock(kind, L.d, now)) return { status: 404, html: renderUnavailablePage(locale) };
  return { status: 200, html: renderListingPage(await listingView(kind, id, L, locale, now)) };
}

// ─────────────────────────────────────────────────────────── submit

export interface SubmitContext {
  kind: GuestKind;
  id: string;
  locale: AppLocale;
  body: Record<string, unknown>;
  ip: string;
}

/** Re-renders the page with an error (and the guest's input kept). */
async function formError(ctx: SubmitContext, key: GuestKey, values: Partial<GuestInput>, status = 400): Promise<PageResponse> {
  const now = guestDeps.now();
  const L = await loadListing(ctx.kind, ctx.id).catch(() => null);
  if (!L || guestViewBlock(ctx.kind, L.d, now)) return { status: 404, html: renderUnavailablePage(ctx.locale) };
  const error = gt(ctx.locale, key, { count: MAX_TICKETS_PER_BUYER });
  return { status, html: renderListingPage(await listingView(ctx.kind, ctx.id, L, ctx.locale, now, {
    error, values, attendeeValues: typedAttendeeNames(ctx.body),
  })) };
}

/** Raw names typed for tickets 2..MAX (re-shown with an error; validated by [guestAttendees]). */
export function typedAttendeeNames(body: Record<string, unknown>): AttendeeName[] {
  const out: AttendeeName[] = [];
  for (let i = 2; i <= MAX_TICKETS_PER_BUYER; i++) {
    const f = body[`att_${i}_first`];
    const l = body[`att_${i}_last`];
    out.push({
      firstName: typeof f === 'string' ? f.slice(0, 60) : '',
      lastName: typeof l === 'string' ? l.slice(0, 60) : '',
    });
  }
  return out;
}

/**
 * The attendee names of a guest order of [quantity] tickets: ticket 1 in the
 * guest's own name, tickets 2..N from the form rows. null = a row missing.
 */
export function guestAttendees(body: Record<string, unknown>, input: GuestInput, quantity: number): AttendeeName[] | null {
  const raw = [{ firstName: input.firstName, lastName: input.lastName }, ...typedAttendeeNames(body)].slice(0, quantity);
  return parseAttendeeNames(raw, quantity);
}

/** Ticket choice of an event form: items (ticket types) or a plain quantity. */
export function parseEventChoice(body: Record<string, unknown>): { items: Array<{ typeId: string; qty: number }> } | { quantity: number } | null {
  const items: Array<{ typeId: string; qty: number }> = [];
  for (const [k, v] of Object.entries(body)) {
    const m = /^qty_([A-Za-z0-9_-]{1,128})$/.exec(k);
    if (!m) continue;
    const q = intField(v, 0, LIMITS.maxTickets);
    if (q === null) return null;
    if (q > 0) items.push({ typeId: m[1], qty: q });
    if (items.length > 20) return null;
  }
  if (items.length) return items.reduce((s, x) => s + x.qty, 0) <= LIMITS.maxTickets ? { items } : null;
  if (body.quantity === undefined) return { quantity: 1 };
  const q = intField(body.quantity, 1, LIMITS.maxTickets);
  return q === null ? null : { quantity: q };
}

/** Experience start choice: "r_{ms}" (recurring) | "s_{slotId}" (one-off). */
export function parseSlotChoice(v: unknown): { slotId: string; startAt?: number } | null {
  if (typeof v !== 'string') return null;
  let m = /^r_(\d{12,14})$/.exec(v);
  if (m) return { slotId: 'recurring', startAt: Number(m[1]) };
  m = /^s_([A-Za-z0-9_-]{1,128})$/.exec(v);
  return m ? { slotId: m[1] } : null;
}

/** POST /guest/{e|x}/{id} (Origin already checked by the caller). */
export async function guestSubmit(ctx: SubmitContext): Promise<PageResponse> {
  const { kind, id, locale, body } = ctx;
  const now = guestDeps.now();
  if (kind === 'a') return { status: 405, html: renderUnavailablePage(locale) };
  const key = await guestSigningKey();
  const parsed = parseGuestInput(body);
  const values = { firstName: parsed.input.firstName, lastName: parsed.input.lastName, email: parsed.input.email };
  // Bots fill every field; humans never see this one.
  if (typeof body.website === 'string' && body.website.trim()) return formError(ctx, 'guest.err.generic', values);
  const tok = verifyFormToken(key, kind, id, body.token, now);
  if (tok.ok === false) return formError(ctx, tok.reason === 'too_fast' ? 'guest.err.generic' : 'guest.err.expired', values);
  if (parsed.ok === false) {
    const k: GuestKey = parsed.error === 'name' ? 'guest.err.name' : parsed.error === 'email' ? 'guest.err.email' : 'guest.err.consent';
    return formError(ctx, k, values);
  }
  const input = parsed.input;
  const email = normalizeGuestEmail(input.email);
  // Abuse limits: per IP, per e-mail, and per listing (seat-hold flooding).
  const okIp = await takeGuestRateLimit('ip', ctx.ip, LIMITS.perIpPerHour);
  const okMail = okIp && await takeGuestRateLimit('email', email, LIMITS.perEmailPerHour);
  const okListing = okMail && await takeGuestRateLimit('listing', `${kind}:${id}`, LIMITS.perListingPerHour);
  if (!okIp || !okMail || !okListing) return formError(ctx, 'guest.err.rateLimited', values, 429);

  const L = await loadListing(kind, id).catch(() => null);
  if (!L || guestViewBlock(kind, L.d, now)) return { status: 404, html: renderUnavailablePage(locale) };
  const block = guestBookBlock(kind, L.d, now);
  if (block) return { status: 409, html: renderListingPage(await listingView(kind, id, L, locale, now, { values })) };

  const guestKey = guestKeyFor(await guestIdentitySecret(), email);
  await upsertContact(guestKey, email, locale);
  try {
    if (kind === 'e') {
      if (eventSale(L.d) === 'free') {
        const r = await registerGuestForFreeEvent(id, guestKey, input, now);
        if (r !== 'already') await sendGuestRsvpTicket(id, L.d, guestKey).catch((e) => console.error('[guest] rsvp email failed:', (e as Error)?.message));
        return {
          status: 200,
          html: renderMessagePage(locale, gt(locale, 'guest.done.registeredTitle'),
            gt(locale, 'guest.done.registeredBody', { email: maskGuestEmail(email) })),
        };
      }
      const choice = parseEventChoice(body);
      if (!choice) return formError(ctx, 'guest.err.quantity', values);
      const qty = 'items' in choice ? choice.items.reduce((a, x) => a + x.qty, 0) : choice.quantity;
      let attendees: AttendeeName[] | null = null;
      if (requiresAttendeeNames(L.d)) {
        attendees = guestAttendees(body, input, qty);
        if (!attendees) return formError(ctx, 'guest.err.attendeeNames', values);
      }
      // THE hook: the same createTicketCheckout members use (pricing, holds,
      // capacity, provider checkout, seller-paid service fee of Track 1).
      const res = await createTicketCheckout(guestKey, {
        kind: 'event', id, platform: 'web', locale, ...choice, ...(attendees ? { attendees } : {}),
      }, email, buyerFor(input.firstName, input.lastName, key, locale));
      return checkoutResponse(res, locale);
    }
    // Experience: a booking REQUEST (the host accepts each one).
    const slot = parseSlotChoice(body.slot);
    if (!slot) return formError(ctx, 'guest.err.slot', values);
    const cfg = await loadConfig();
    const guests = intField(body.partySize, 1, Math.min(cfg.maxGuestsPerBooking, LIMITS.maxTickets));
    if (guests === null) return formError(ctx, 'guest.err.generic', values);
    await createBooking(guestKey, {
      experienceId: id, slotId: slot.slotId, ...(slot.startAt ? { startAt: slot.startAt } : {}),
      guests, requestId: `g${tok.nonce}`.slice(0, 64), consentVersion: 'guest_web_v1',
    }, { firstName: input.firstName, lastName: input.lastName });
    return {
      status: 200,
      html: renderMessagePage(locale, gt(locale, 'guest.done.requestTitle'),
        gt(locale, 'guest.done.requestBody', { email: maskGuestEmail(email) })),
    };
  } catch (e) {
    if (e instanceof GuestError) return formError(ctx, e.key, values, e.status);
    const reason = reasonOf(e);
    if (!(e instanceof HttpsError)) console.error(`[guest] submit ${kind}/${id} failed:`, (e as Error)?.message);
    return formError(ctx, errorKeyFor(reason), values, 409);
  }
}

function checkoutResponse(res: Record<string, unknown>, locale: AppLocale): PageResponse {
  if (res.mode === 'free') {
    // Only free ticket types: issued right away, the ticket e-mail follows.
    return { status: 200, html: renderMessagePage(locale, gt(locale, 'guest.done.paidTitle'), gt(locale, 'guest.done.paidBody')) };
  }
  if (res.mode !== 'instant' || !isProviderCheckoutUrl(res.checkoutUrl)) {
    console.error(`[guest] unexpected checkout result for order ${String(res.orderId || '')}`);
    return { status: 502, html: renderMessagePage(locale, gt(locale, 'guest.err.payment'), gt(locale, 'guest.err.payment'), { error: true }) };
  }
  return { status: 200, html: renderRedirectPage(locale, res.checkoutUrl as string) };
}

/**
 * Free event RSVP for a guest: attendee doc + seat in ONE transaction with the
 * capacity check (no waitlist for guests). Idempotent per guest key.
 */
export async function registerGuestForFreeEvent(
  eventId: string, guestKey: string, input: GuestInput, now: number,
): Promise<'registered' | 'already'> {
  const evRef = db().collection('events').doc(eventId);
  const attRef = evRef.collection('attendees').doc(guestKey);
  return db().runTransaction(async (tx) => {
    const [ev, att] = await Promise.all([tx.get(evRef), tx.get(attRef)]);
    const d = ev.data();
    const block = guestBookBlock('e', d, now);
    if (block) throw new GuestError(noticeKey(block) ?? 'guest.err.unavailable', 409);
    if (eventSale(d!) !== 'free') throw new GuestError('guest.err.unavailable', 409);
    if (att.exists && att.data()?.status === 'going') return 'already' as const;
    const max = Math.floor(Number(d!.maxAttendees) || 0);
    const going = Math.max(0, Math.floor(Number(d!.attendeeCount) || 0));
    if (max > 0 && going >= max) throw new GuestError('guest.err.soldOut', 409);
    tx.set(attRef, {
      eventId, userId: guestKey, userName: guestDisplayName(input), userPhotoUrl: null,
      status: 'going', rsvpDate: ts(now), isApproved: true,
      isInvisible: false, isAnonymous: false, muteNotifications: true, visibleToOrganizerOnly: false,
      checkedIn: false, checkedInAt: null, guestCount: 0, ticketCount: 1, tierId: null,
      isGuest: true,
    });
    tx.update(evRef, { attendeeCount: going + 1 });
    return 'registered' as const;
  });
}

// ─────────────────────────────────────────────────────────── payment return

/** GET /guest/done/{orderId}?r=&t=&k=&l=&n= */
export async function guestReturnPage(orderId: string, q: Record<string, unknown>, locale: AppLocale): Promise<PageResponse> {
  const key = await guestSigningKey();
  if (!checkSig(returnSig(key, orderId), q.t)) return { status: 404, html: renderUnavailablePage(locale) };
  const ref = db().collection('ticket_orders').doc(orderId);
  let o = (await ref.get()).data();
  if (!o || o.isGuest !== true) return { status: 404, html: renderUnavailablePage(locale) };
  const back = `/guest/${o.kind === 'experience' ? 'x' : 'e'}/${encodeURIComponent(String(o.listingId))}?hl=${encodeURIComponent(locale)}`;
  if (OPEN.has(o.status)) {
    if (q.r === 'cancel') {
      // Releases the held seats now instead of at expiry (sync first: paid wins).
      await cancelTicketOrder(String(o.buyerId), { orderId }).catch(() => undefined);
    } else {
      await syncOrderWithProvider(orderId).catch(() => undefined);
    }
    o = (await ref.get()).data() || o;
  }
  if (o.status === 'paid') {
    return { status: 200, html: renderMessagePage(locale, gt(locale, 'guest.done.paidTitle'), gt(locale, 'guest.done.paidBody')) };
  }
  if (OPEN.has(o.status)) {
    const n = intField(q.n, 0, 100) ?? 0;
    return {
      status: 200,
      html: renderMessagePage(locale, gt(locale, 'guest.done.pendingTitle'), gt(locale, 'guest.done.pendingBody'),
        { refreshSeconds: n < 12 ? 5 : 0 }),
    };
  }
  return { status: 200, html: renderMessagePage(locale, gt(locale, 'guest.done.cancelTitle'), gt(locale, 'guest.done.cancelBody'), { backHref: back }) };
}

// ─────────────────────────────────────────────────────────── accepted request: pay now

async function payableBooking(bookingId: string, sig: unknown): Promise<Record<string, any> | null> {
  const key = await guestSigningKey();
  if (!checkSig(paySig(key, bookingId), sig)) return null;
  const b = (await db().collection('bookings').doc(bookingId).get()).data();
  if (!b || b.isGuest !== true) return null;
  return b;
}

/** GET /guest/pay/{bookingId}?t= */
export async function guestPayPage(bookingId: string, q: Record<string, unknown>, locale: AppLocale): Promise<PageResponse> {
  const b = await payableBooking(bookingId, q.t);
  if (!b) return { status: 404, html: renderMessagePage(locale, gt(locale, 'guest.pay.title'), gt(locale, 'guest.pay.invalid'), { error: true }) };
  if (b.payment?.status === 'paid') {
    return { status: 200, html: renderMessagePage(locale, gt(locale, 'guest.pay.title'), gt(locale, 'guest.pay.done')) };
  }
  if (b.status !== 'confirmed' || b.payment?.mode !== 'online') {
    return { status: 409, html: renderMessagePage(locale, gt(locale, 'guest.pay.title'), gt(locale, 'guest.pay.invalid'), { error: true }) };
  }
  const exp = (await db().collection('user_experiences').doc(String(b.experienceId)).get()).data() || {};
  const facts: Array<[string, string]> = [[gt(locale, 'guest.page.when'), formatWhen(millis(b.slotStart), hostTimeZone(exp), locale)]];
  const place = joinPlace([exp.meetingPoint, exp.locationName, exp.city]);
  if (place) facts.push([gt(locale, 'guest.page.where'), place]);
  facts.push([gt(locale, 'guest.form.partySize'), String(Math.max(1, Number(b.guests) || 1))]);
  return {
    status: 200,
    html: renderPayPage(locale, {
      title: String(b.experienceTitle || exp.title || 'GreenGo'), facts,
      action: `/guest/pay/${encodeURIComponent(bookingId)}`, sig: String(q.t), provider: providerName(b.payment?.provider) ?? null,
    }),
  };
}

/** POST /guest/pay/{bookingId} (Origin already checked by the caller). */
export async function guestPaySubmit(bookingId: string, body: Record<string, unknown>, locale: AppLocale, ip: string): Promise<PageResponse> {
  const b = await payableBooking(bookingId, body.t);
  if (!b) return { status: 404, html: renderMessagePage(locale, gt(locale, 'guest.pay.title'), gt(locale, 'guest.pay.invalid'), { error: true }) };
  if (!(await takeGuestRateLimit('ip', ip, LIMITS.perIpPerHour))) {
    return { status: 429, html: renderMessagePage(locale, gt(locale, 'guest.pay.title'), gt(locale, 'guest.err.rateLimited'), { error: true }) };
  }
  const contact = (await db().collection(GUEST_CONTACTS).doc(String(b.guestId)).get()).data();
  const key = await guestSigningKey();
  try {
    const res = await createTicketCheckout(String(b.guestId), {
      kind: 'experience', id: String(b.experienceId), bookingId, platform: 'web', locale,
    }, typeof contact?.email === 'string' ? contact.email : null,
    buyerFor(String(b.guest?.firstName || ''), String(b.guest?.lastName || ''), key, locale));
    return checkoutResponse(res, locale);
  } catch (e) {
    const reason = reasonOf(e);
    if (reason === 'already_has_ticket') {
      return { status: 200, html: renderMessagePage(locale, gt(locale, 'guest.pay.title'), gt(locale, 'guest.pay.done')) };
    }
    if (!(e instanceof HttpsError)) console.error(`[guest] pay ${bookingId} failed:`, (e as Error)?.message);
    return { status: 409, html: renderMessagePage(locale, gt(locale, 'guest.pay.title'), gt(locale, errorKeyFor(reason)), { error: true }) };
  }
}
