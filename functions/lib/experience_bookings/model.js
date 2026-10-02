"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.HOST_ACTIONS = exports.PAYMENT_METHODS = exports.DEFAULT_POLICY = exports.CANCELLATION_POLICIES = exports.ACTIVE_STATUSES = exports.SEAT_HOLDING = exports.BOOKING_STATUSES = exports.DEFAULT_CONFIG = exports.DAY_MS = exports.HOUR_MS = exports.SERVER_SECRETS = exports.BOOKING_AGG_EVENTS = exports.HOST_SUSPENSIONS = exports.HOST_FLAGS = exports.HOST_CANCEL_STATS = exports.REVIEW_ELIGIBILITY = exports.PENDING_REVIEWS = exports.GUEST_REVIEWS = exports.EXPERIENCES = exports.SLOTS = exports.BOOKINGS = void 0;
exports.resolveConfig = resolveConfig;
exports.isBookingStatus = isBookingStatus;
exports.canTransition = canTransition;
exports.seatsReleased = seatsReleased;
exports.policyOf = policyOf;
exports.refundFor = refundFor;
exports.normalizeCurrency = normalizeCurrency;
exports.currencyExponent = currencyExponent;
exports.toMinorUnits = toMinorUnits;
exports.computeBookingPrice = computeBookingPrice;
exports.acceptedPaymentMethods = acceptedPaymentMethods;
exports.choosePaymentMethod = choosePaymentMethod;
exports.refundDueFor = refundDueFor;
exports.requestExpiresAtMs = requestExpiresAtMs;
exports.reminderAtMs = reminderAtMs;
exports.completeAtMs = completeAtMs;
exports.canMarkNoShow = canMarkNoShow;
exports.inCheckInWindow = inCheckInWindow;
exports.inDisputeWindow = inDisputeWindow;
exports.pruneCancellations = pruneCancellations;
exports.shouldFlagHost = shouldFlagHost;
exports.bookingIdFor = bookingIdFor;
exports.checkInCode = checkInCode;
exports.verifyCheckInCode = verifyCheckInCode;
exports.checkInQrPayload = checkInQrPayload;
exports.idDocumentStateOf = idDocumentStateOf;
exports.isBannedProfile = isBannedProfile;
exports.isDocId = isDocId;
exports.isRequestId = isRequestId;
exports.cleanText = cleanText;
exports.guestReviewContribution = guestReviewContribution;
exports.guestRatingDelta = guestRatingDelta;
exports.applyGuestRatingDelta = applyGuestRatingDelta;
exports.bookingReviewable = bookingReviewable;
const crypto = __importStar(require("crypto"));
exports.BOOKINGS = 'bookings';
exports.SLOTS = 'slots';
exports.EXPERIENCES = 'user_experiences';
exports.GUEST_REVIEWS = 'guest_reviews';
exports.PENDING_REVIEWS = 'pending_reviews';
exports.REVIEW_ELIGIBILITY = 'review_eligibility';
exports.HOST_CANCEL_STATS = 'host_cancellation_stats';
exports.HOST_FLAGS = 'host_flags';
exports.HOST_SUSPENSIONS = 'host_suspensions';
exports.BOOKING_AGG_EVENTS = 'booking_agg_events';
exports.SERVER_SECRETS = 'server_secrets';
exports.HOUR_MS = 60 * 60 * 1000;
exports.DAY_MS = 24 * exports.HOUR_MS;
exports.DEFAULT_CONFIG = {
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
function resolveConfig(raw) {
    const out = Object.assign({}, exports.DEFAULT_CONFIG);
    if (!raw)
        return out;
    const bounds = {
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
    for (const k of Object.keys(bounds)) {
        const v = raw[k];
        const [lo, hi] = bounds[k];
        if (typeof v === 'number' && Number.isInteger(v) && v >= lo && v <= hi)
            out[k] = v;
    }
    return out;
}
// ───────────────────────────────────────────────────────────── state machine
exports.BOOKING_STATUSES = [
    'requested', 'confirmed', 'declined', 'expired',
    'cancelled_by_guest', 'cancelled_by_host',
    'completed', 'no_show', 'disputed', 'resolved',
];
const TRANSITIONS = {
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
function isBookingStatus(s) {
    return typeof s === 'string' && exports.BOOKING_STATUSES.includes(s);
}
/** The ONLY gate for status changes. Unknown statuses never transition. */
function canTransition(from, to) {
    if (!isBookingStatus(from) || !isBookingStatus(to))
        return false;
    return TRANSITIONS[from].includes(to);
}
/** Statuses whose guests occupy seats on the slot. */
exports.SEAT_HOLDING = new Set([
    'requested', 'confirmed', 'no_show', 'disputed', 'completed', 'resolved',
]);
/** Statuses that block a second booking of the same guest on the same slot. */
exports.ACTIVE_STATUSES = ['requested', 'confirmed'];
/** Seats to give back to the slot for the move from -> to (0 or guests). */
function seatsReleased(from, to, guests) {
    return exports.SEAT_HOLDING.has(from) && !exports.SEAT_HOLDING.has(to) ? guests : 0;
}
// ─────────────────────────────────────────────────────────── refund policy
exports.CANCELLATION_POLICIES = ['flexible', 'moderate', 'strict'];
exports.DEFAULT_POLICY = 'moderate';
/** Policy enum from an experience doc; anything else (legacy text) -> moderate. */
function policyOf(experience) {
    const raw = typeof (experience === null || experience === void 0 ? void 0 : experience.cancellationPolicy) === 'string'
        ? experience.cancellationPolicy.trim()
        : '';
    return exports.CANCELLATION_POLICIES.includes(raw)
        ? raw
        : exports.DEFAULT_POLICY;
}
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
function refundFor(policy, now, slotStart, bookedAt, by) {
    if (by === 'host')
        return 100;
    const toStart = slotStart - now;
    if (toStart <= 0)
        return 0;
    if (now - bookedAt <= exports.DAY_MS && toStart > 2 * exports.DAY_MS)
        return 100;
    const p = exports.CANCELLATION_POLICIES.includes(policy) ? policy : exports.DEFAULT_POLICY;
    switch (p) {
        case 'flexible':
            return toStart >= exports.DAY_MS ? 100 : 0;
        case 'strict':
            return toStart >= 7 * exports.DAY_MS ? 100 : 0;
        case 'moderate':
        default:
            if (toStart >= 7 * exports.DAY_MS)
                return 100;
            return toStart >= exports.DAY_MS ? 50 : 0;
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
const CURRENCY_SYMBOLS = {
    '$': 'usd', 'us$': 'usd', '€': 'eur', '£': 'gbp', 'r$': 'brl', '¥': 'jpy',
};
function normalizeCurrency(c) {
    var _a;
    if (typeof c !== 'string')
        return null;
    const v = c.trim().toLowerCase();
    if (/^[a-z]{3}$/.test(v))
        return v;
    return (_a = CURRENCY_SYMBOLS[v]) !== null && _a !== void 0 ? _a : null;
}
function currencyExponent(currency) {
    if (ZERO_DECIMAL.has(currency))
        return 0;
    if (THREE_DECIMAL.has(currency))
        return 3;
    return 2;
}
/** Major units (as stored on the experience, e.g. 49.9) -> integer minor units. */
function toMinorUnits(major, currency) {
    const f = 10 ** currencyExponent(currency);
    // toFixed first: 19.99 * 100 = 1998.9999999999998 must become 1999.
    return Math.round(Number((major * f).toFixed(6)));
}
/** Price for [guests] seats, from the EXPERIENCE doc only. */
function computeBookingPrice(experience, guests) {
    const raw = experience.price;
    const priceNum = typeof raw === 'number' && Number.isFinite(raw) ? raw : null;
    const free = experience.isFree === true || priceNum === 0;
    if (free)
        return { ok: true, free: true, price: { unitAmount: 0, currency: null, totalAmount: 0 } };
    if (priceNum === null || priceNum < 0)
        return { ok: false, reason: 'invalid_price' };
    const currency = normalizeCurrency(experience.currency);
    if (!currency)
        return { ok: false, reason: 'currency_missing' };
    const unitAmount = toMinorUnits(priceNum, currency);
    if (unitAmount <= 0)
        return { ok: false, reason: 'invalid_price' };
    const totalAmount = unitAmount * guests;
    if (!Number.isSafeInteger(totalAmount))
        return { ok: false, reason: 'amount_too_large' };
    return { ok: true, free: false, price: { unitAmount, currency, totalAmount } };
}
// ─────────────────────────────────────────────────────────── payment methods
/** How a guest pays a PAID experience (both off-platform). */
exports.PAYMENT_METHODS = ['cash', 'link'];
function hasPaymentLink(e) {
    const pl = e.paymentLink;
    return !!pl && typeof pl === 'object' && typeof pl.type === 'string' &&
        typeof pl.value === 'string' && pl.value.trim().length > 0;
}
/**
 * The methods an experience accepts. `paymentMethods` (['cash'] | ['link'] |
 * ['cash','link']) when present and valid; a legacy doc with only a
 * paymentLink -> ['link']. 'link' is only offered while a link exists.
 */
function acceptedPaymentMethods(e) {
    const raw = Array.isArray(e.paymentMethods) ? e.paymentMethods : null;
    const listed = raw
        ? exports.PAYMENT_METHODS.filter((m) => raw.includes(m))
        : (hasPaymentLink(e) ? ['link'] : []);
    return listed.filter((m) => m !== 'link' || hasPaymentLink(e));
}
/**
 * Validates the guest's choice for a paid experience. A single accepted
 * method may be omitted (it is implied); with two the guest must choose.
 */
function choosePaymentMethod(e, requested) {
    const accepted = acceptedPaymentMethods(e);
    if (accepted.length === 0)
        return { ok: false, reason: 'no_payment_method' };
    if (requested === undefined || requested === null || requested === '') {
        return accepted.length === 1
            ? { ok: true, method: accepted[0] }
            : { ok: false, reason: 'payment_method_required' };
    }
    return typeof requested === 'string' && accepted.includes(requested)
        ? { ok: true, method: requested }
        : { ok: false, reason: 'payment_method_not_accepted' };
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
function refundDueFor(price, payment, percent, reason) {
    const mode = payment === null || payment === void 0 ? void 0 : payment.mode;
    if (!price || !(price.totalAmount > 0) || (mode !== 'link' && mode !== 'cash'))
        return null;
    const policyPercent = Math.max(0, Math.min(100, Math.round(percent)));
    const paidCash = mode === 'cash' && !!(payment === null || payment === void 0 ? void 0 : payment.hostConfirmedPaidAt);
    const pct = mode === 'cash' && !paidCash ? 0 : policyPercent;
    return {
        percent: pct,
        policyPercent,
        amount: Math.round((price.totalAmount * pct) / 100),
        currency: price.currency,
        reason: mode === 'cash' && !paidCash
            ? `${reason}_cash_unpaid`
            : mode === 'link' && !(payment === null || payment === void 0 ? void 0 : payment.guestMarkedPaidAt) && !(payment === null || payment === void 0 ? void 0 : payment.hostConfirmedPaidAt)
                ? `${reason}_link_unconfirmed`
                : reason,
    };
}
// ─────────────────────────────────────────────────────────── time rules
function requestExpiresAtMs(createdMs, slotStartMs, cfg) {
    return Math.min(createdMs + cfg.requestTtlHours * exports.HOUR_MS, slotStartMs);
}
function reminderAtMs(slotStartMs, cfg) {
    return slotStartMs - cfg.reminderLeadHours * exports.HOUR_MS;
}
function completeAtMs(slotEndMs, cfg) {
    return slotEndMs + cfg.disputeWindowHours * exports.HOUR_MS;
}
function canMarkNoShow(now, slotStart, cfg) {
    return now >= slotStart + cfg.noShowGraceMinutes * 60 * 1000;
}
function inCheckInWindow(now, slotStart, slotEnd, cfg) {
    return now >= slotStart - cfg.checkInEarlyHours * exports.HOUR_MS
        && now <= slotEnd + cfg.checkInLateHours * exports.HOUR_MS;
}
/** Guest may dispute from the start until end + dispute window. */
function inDisputeWindow(now, slotStart, slotEnd, cfg) {
    return now >= slotStart && now <= slotEnd + cfg.disputeWindowHours * exports.HOUR_MS;
}
/** Host cancellations inside the window after adding one at [now]. */
function pruneCancellations(recentMs, now, cfg) {
    const since = now - cfg.hostCancelWindowDays * exports.DAY_MS;
    return [...recentMs.filter((t) => t > since && t <= now), now].sort((a, b) => a - b).slice(-50);
}
/** Flag once per window: at the limit and not flagged within the window. */
function shouldFlagHost(recentMs, flaggedAtMs, now, cfg) {
    if (recentMs.length < cfg.hostCancelLimit)
        return false;
    return flaggedAtMs === null || flaggedAtMs <= now - cfg.hostCancelWindowDays * exports.DAY_MS;
}
// ─────────────────────────────────────────────────────────── identity
/** Deterministic booking id for (guest, client requestId): retries hit the same doc. */
function bookingIdFor(guestId, requestId) {
    return 'bk_' + crypto.createHash('sha256').update(`${guestId}:${requestId}`).digest('hex').slice(0, 28);
}
const B32 = 'ABCDEFGHJKMNPQRSTVWXYZ0123456789'; // no I, L, O, U (readable aloud)
/** 8-character check-in code = HMAC-SHA256(secret, bookingId), base-32. */
function checkInCode(secret, bookingId) {
    const mac = crypto.createHmac('sha256', secret).update(`checkin:${bookingId}`).digest();
    let out = '';
    for (let i = 0; i < 8; i++)
        out += B32[mac[i] % 32];
    return out;
}
function verifyCheckInCode(secret, bookingId, given) {
    if (typeof given !== 'string')
        return false;
    const g = given.trim().toUpperCase();
    const want = checkInCode(secret, bookingId);
    if (g.length !== want.length)
        return false;
    return crypto.timingSafeEqual(Buffer.from(g), Buffer.from(want));
}
/** What the guest's app encodes as a QR code. */
function checkInQrPayload(bookingId, code) {
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
function idDocumentStateOf(profile) {
    var _a;
    if (!profile)
        return 'none';
    if (profile.isAgeVerified === true)
        return 'approved';
    const s = (_a = profile.ageVerification) === null || _a === void 0 ? void 0 : _a.status;
    if (s === 'verified')
        return 'approved';
    if (s === 'pending')
        return 'uploaded';
    return 'none';
}
function isBannedProfile(d) {
    if (!d)
        return false;
    if (d.isBanned === true || d.banned === true)
        return true;
    return d.accountStatus === 'banned' || d.accountStatus === 'suspended';
}
// ─────────────────────────────────────────────────────────── input validation
const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;
const REQ_RE = /^[A-Za-z0-9_-]{8,64}$/;
function isDocId(v) {
    return typeof v === 'string' && ID_RE.test(v);
}
function isRequestId(v) {
    return typeof v === 'string' && REQ_RE.test(v);
}
function cleanText(v, max) {
    if (typeof v !== 'string')
        return null;
    const s = v.trim();
    return s.length === 0 ? null : s.slice(0, max);
}
exports.HOST_ACTIONS = ['none', 'warn', 'suspend_hosting', 'hide_listing'];
/** What one guest review contributes to the guest's totals (visible only). */
function guestReviewContribution(r) {
    if (!r || r.status !== 'visible')
        return { sum: 0, count: 0 };
    const v = r.rating;
    if (typeof v !== 'number' || !Number.isInteger(v) || v < 1 || v > 5)
        return { sum: 0, count: 0 };
    return { sum: v, count: 1 };
}
function guestRatingDelta(before, after) {
    const b = guestReviewContribution(before);
    const a = guestReviewContribution(after);
    return { sum: a.sum - b.sum, count: a.count - b.count };
}
/** Applies a delta to profile totals; clamped at 0. */
function applyGuestRatingDelta(profile, delta) {
    const num = (x) => (typeof x === 'number' && Number.isFinite(x) ? x : 0);
    const p = profile !== null && profile !== void 0 ? profile : {};
    const count = Math.max(0, num(p.guestRatingCount) + delta.count);
    const sum = count === 0 ? 0 : Math.max(0, num(p.guestRatingSum) + delta.sum);
    return {
        guestRatingSum: sum,
        guestRatingCount: count,
        guestRatingAvg: count === 0 ? 0 : Math.round((sum / count) * 100) / 100,
    };
}
/** A booking the host may review the guest for / the guest may review the experience for. */
function bookingReviewable(b, side) {
    if (b.status === 'completed')
        return true;
    if (b.status === 'confirmed' && b.checkIn)
        return true;
    return side === 'host' && b.status === 'no_show';
}
//# sourceMappingURL=model.js.map