"use strict";
/**
 * Two-way, double-blind reviews after a real booking.
 *
 *   guest -> experience: user_experiences/{expId}/pending_reviews/{guestId}
 *     (client create, only with a review_eligibility marker for that booking;
 *     readable by its author only). On reveal it is copied into the PUBLIC
 *     user_experiences/{expId}/reviews/{guestId} — the existing
 *     onExperienceReviewWritten trigger then moderates it, folds it into the
 *     experience + host aggregates and notifies the host, exactly as before —
 *     and the pending doc + marker are deleted.
 *   host -> guest:       guest_reviews/{bookingId}
 *     (client create by the booking's host; status held|visible|rejected set
 *     here). Visible reviews aggregate into profiles/{guestId}.guestRating*
 *     (server-owned), applied once per trigger event (booking_agg_events).
 *
 * Reveal rule (per booking): BOTH sides submitted -> both revealed at once;
 * otherwise each side is revealed REVIEW_REVEAL_DAYS after it was submitted
 * (revealBlindReviews job). A side submitted after the other was already
 * revealed is revealed immediately (nothing left to be blind about).
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
exports.revealForBooking = revealForBooking;
exports.handleGuestReviewWrite = handleGuestReviewWrite;
exports.handlePendingReviewCreated = handlePendingReviewCreated;
exports.revealDueReviews = revealDueReviews;
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const moderation_1 = require("../user_experiences/moderation");
const model_1 = require("./model");
const service_1 = require("./service");
const fdb = () => service_1.bookingDeps.db();
const nowMs = () => service_1.bookingDeps.now().getTime();
const ts = (ms) => admin.firestore.Timestamp.fromMillis(ms);
const AGG_EVENT_TTL_MS = 7 * model_1.DAY_MS;
/**
 * Reveals what may be revealed for [bookingId], in one transaction.
 * `due` = also reveal a side on its own once its revealAt has passed.
 */
async function revealForBooking(bookingId, due = false) {
    const db = fdb();
    const bookingSnap = await db.collection(model_1.BOOKINGS).doc(bookingId).get();
    const b = bookingSnap.data();
    if (!b)
        return { guestSide: false, hostSide: false };
    const expRef = db.collection(model_1.EXPERIENCES).doc(b.experienceId);
    const pendingRef = expRef.collection(model_1.PENDING_REVIEWS).doc(b.guestId);
    const reviewRef = expRef.collection('reviews').doc(b.guestId);
    const eligRef = expRef.collection(model_1.REVIEW_ELIGIBILITY).doc(b.guestId);
    const grRef = db.collection(model_1.GUEST_REVIEWS).doc(bookingId);
    const out = await db.runTransaction(async (tx) => {
        var _a, _b, _c, _d, _e, _f, _g;
        const [pending, review, gr, elig] = await Promise.all([
            tx.get(pendingRef), tx.get(reviewRef), tx.get(grRef), tx.get(eligRef),
        ]);
        const now = nowMs();
        const p = pending.data();
        const pendingOk = !!p && p.bookingId === bookingId && ((_a = p.status) !== null && _a !== void 0 ? _a : 'pending') === 'pending';
        const g = gr.data();
        const guestSubmitted = pendingOk || (review.exists && ((_b = review.data()) === null || _b === void 0 ? void 0 : _b.bookingId) === bookingId);
        const hostSubmitted = gr.exists;
        const guestRevealed = review.exists && ((_c = review.data()) === null || _c === void 0 ? void 0 : _c.bookingId) === bookingId;
        const hostRevealed = !!g && g.status !== 'held';
        const pendingDue = pendingOk && ((_d = (0, service_1.msOf)(p.revealAt)) !== null && _d !== void 0 ? _d : Infinity) <= now;
        const grDue = !!g && g.status === 'held' && ((_e = (0, service_1.msOf)(g.revealAt)) !== null && _e !== void 0 ? _e : Infinity) <= now;
        const revealGuest = pendingOk && (hostSubmitted || hostRevealed || (due && pendingDue));
        const revealHost = !!g && g.status === 'held' && (guestSubmitted || guestRevealed || (due && grDue));
        if (revealGuest) {
            const base = {
                authorId: b.guestId,
                bookingId,
                rating: p.rating,
                comment: typeof p.comment === 'string' ? p.comment : '',
                updatedAt: ts(now),
            };
            if (review.exists) {
                tx.update(reviewRef, base);
            }
            else {
                tx.set(reviewRef, Object.assign(Object.assign({}, base), { createdAt: (_f = p.createdAt) !== null && _f !== void 0 ? _f : ts(now) }));
            }
            tx.delete(pendingRef);
            if (elig.exists && ((_g = elig.data()) === null || _g === void 0 ? void 0 : _g.bookingId) === bookingId)
                tx.delete(eligRef);
        }
        if (revealHost)
            tx.update(grRef, { status: 'visible', revealedAt: ts(now) });
        return { guestSide: revealGuest, hostSide: revealHost };
    });
    return out;
}
/**
 * guest_reviews/{bookingId} written. New doc (no status yet): moderate ->
 * 'rejected' or 'held' (+ revealAt), then try to reveal the pair. Every event:
 * apply its own visible-rating delta to the guest's profile totals (once per
 * event id). Newly visible -> notify the guest.
 */
async function handleGuestReviewWrite(eventId, bookingId, before, after) {
    var _a, _b, _c;
    const db = fdb();
    const ref = db.collection(model_1.GUEST_REVIEWS).doc(bookingId);
    if (after && !after.status) {
        const cfg = await (0, service_1.loadConfig)();
        const decision = (0, moderation_1.moderateCommentText)(after.comment);
        const created = (_a = (0, service_1.msOf)(after.createdAt)) !== null && _a !== void 0 ? _a : nowMs();
        await ref.update(decision.ok
            ? { status: 'held', revealAt: ts(created + cfg.reviewRevealDays * model_1.DAY_MS) }
            : { status: 'rejected', moderation: { reason: decision.reason, terms: (_b = decision.terms) !== null && _b !== void 0 ? _b : [] } });
        // A rejected host review still counts as "submitted" for the guest side.
        await revealForBooking(bookingId);
        if (decision.ok) {
            const fresh = (await ref.get()).data();
            if ((fresh === null || fresh === void 0 ? void 0 : fresh.status) === 'held') {
                await notifySafe({
                    recipientId: after.guestId, type: 'guest_review_waiting',
                    title: 'Your host reviewed you', body: 'Review your experience to see what they said.',
                    data: { action: 'booking', bookingId, experienceId: String(after.experienceId || '') },
                });
            }
        }
        return; // the status write re-fires this trigger with its own delta
    }
    const delta = (0, model_1.guestRatingDelta)(before, after);
    const guestId = ((_c = after === null || after === void 0 ? void 0 : after.guestId) !== null && _c !== void 0 ? _c : before === null || before === void 0 ? void 0 : before.guestId);
    if (guestId && (delta.sum !== 0 || delta.count !== 0)) {
        const markerRef = db.collection(model_1.BOOKING_AGG_EVENTS).doc(`gr_${eventId}`);
        const profileRef = db.collection('profiles').doc(guestId);
        await db.runTransaction(async (tx) => {
            const [marker, profile] = await Promise.all([tx.get(markerRef), tx.get(profileRef)]);
            if (marker.exists)
                return; // duplicate delivery
            tx.set(markerRef, { bookingId, guestId, expireAt: ts(nowMs() + AGG_EVENT_TTL_MS) });
            if (!profile.exists)
                return;
            tx.update(profileRef, Object.assign({}, (0, model_1.applyGuestRatingDelta)(profile.data(), delta)));
        });
    }
    if ((after === null || after === void 0 ? void 0 : after.status) === 'visible' && (before === null || before === void 0 ? void 0 : before.status) !== 'visible') {
        await notifySafe({
            recipientId: after.guestId, type: 'guest_review_published',
            title: 'You have a new review from a host', body: typeof after.comment === 'string' ? after.comment.slice(0, 120) : '',
            data: { action: 'guest_review', bookingId },
        });
    }
}
/**
 * pending_reviews/{guestId} created: stamp status + revealAt (server fields),
 * then reveal if the host already reviewed; otherwise nudge the host.
 */
async function handlePendingReviewCreated(experienceId, guestId, data) {
    var _a;
    const db = fdb();
    const ref = db.collection(model_1.EXPERIENCES).doc(experienceId).collection(model_1.PENDING_REVIEWS).doc(guestId);
    const bookingId = typeof data.bookingId === 'string' ? data.bookingId : '';
    if (!bookingId)
        return;
    const cfg = await (0, service_1.loadConfig)();
    const created = (_a = (0, service_1.msOf)(data.createdAt)) !== null && _a !== void 0 ? _a : nowMs();
    try {
        await ref.update({ status: 'pending', revealAt: ts(created + cfg.reviewRevealDays * model_1.DAY_MS) });
    }
    catch (_b) {
        return; // withdrawn / already revealed
    }
    const r = await revealForBooking(bookingId);
    if (!r.guestSide) {
        const b = (await db.collection(model_1.BOOKINGS).doc(bookingId).get()).data();
        if (b === null || b === void 0 ? void 0 : b.hostId) {
            await notifySafe({
                recipientId: b.hostId, type: 'booking_review_waiting',
                title: 'Your guest left a review', body: 'Review your guest to reveal both reviews.',
                data: { action: 'booking', bookingId, experienceId },
            });
        }
    }
}
/** Hourly: reveal every side whose blind period has ended. */
async function revealDueReviews() {
    const db = fdb();
    const now = ts(nowMs());
    let n = 0;
    const ids = new Set();
    const [held, pending] = await Promise.all([
        db.collection(model_1.GUEST_REVIEWS).where('status', '==', 'held').where('revealAt', '<=', now)
            .orderBy('revealAt').limit(300).get(),
        db.collectionGroup(model_1.PENDING_REVIEWS).where('status', '==', 'pending').where('revealAt', '<=', now)
            .orderBy('revealAt').limit(300).get(),
    ]);
    held.docs.forEach((d) => ids.add(d.id));
    pending.docs.forEach((d) => {
        var _a;
        const id = (_a = d.data()) === null || _a === void 0 ? void 0 : _a.bookingId;
        if (typeof id === 'string' && id)
            ids.add(id);
    });
    for (const id of ids) {
        try {
            const r = await revealForBooking(id, true);
            if (r.guestSide || r.hostSide)
                n++;
        }
        catch (e) {
            console.error(`[bookings] reveal ${id} failed:`, e);
        }
    }
    if (n)
        console.log(`[bookings] revealed reviews for ${n} booking(s)`);
    return n;
}
async function notifySafe(p) {
    try {
        await service_1.bookingDeps.notify(p);
    }
    catch (e) {
        console.error(`[bookings] notify ${p.type} failed:`, e);
    }
}
//# sourceMappingURL=reviews.js.map