"use strict";
/**
 * Experience bookings — server operations (callable bodies, job bodies).
 * See ./model.ts for the data model, state machine and policy rules.
 *
 * Every status change goes through `transition()`: ONE Firestore transaction
 * that re-reads the booking, checks `canTransition(from, to)`, writes the
 * booking, gives seats back to the slot when the new status no longer holds
 * them, and counts host cancellations. Re-running any operation is safe: an
 * operation that already happened returns its result instead of failing
 * (`noop`), and createBooking is keyed by a client requestId.
 *
 * Nothing here moves money: `refundDue` is an obligation recorded for both
 * parties (paid experiences are paid through the host's external link).
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
exports.bookingDeps = void 0;
exports.msOf = msOf;
exports.loadConfig = loadConfig;
exports.isAdminUid = isAdminUid;
exports.isBlockedEitherWay = isBlockedEitherWay;
exports.notifyAdmins = notifyAdmins;
exports.checkInSecret = checkInSecret;
exports.resetCachedSecret = resetCachedSecret;
exports.bookingView = bookingView;
exports.transition = transition;
exports.createBooking = createBooking;
exports.respondToBookingRequest = respondToBookingRequest;
exports.cancelBooking = cancelBooking;
exports.getBookingCheckInCode = getBookingCheckInCode;
exports.checkInBooking = checkInBooking;
exports.markNoShow = markNoShow;
exports.markBookingPaid = markBookingPaid;
exports.confirmCashReceived = confirmCashReceived;
exports.openBookingDispute = openBookingDispute;
exports.resolveBookingDispute = resolveBookingDispute;
exports.cancelSlot = cancelSlot;
exports.onExperienceDeleted = onExperienceDeleted;
exports.sendDueReminders = sendDueReminders;
exports.expireDueRequests = expireDueRequests;
exports.completeDueBookings = completeDueBookings;
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
const https_1 = require("firebase-functions/v2/https");
require("../shared/firebaseAdmin");
const effectiveTier_1 = require("../shared/effectiveTier");
const notifyHelpers_1 = require("../notifications/notifyHelpers");
const model_1 = require("./model");
/** Overridable in unit tests; production uses the defaults. */
exports.bookingDeps = {
    db: () => admin.firestore(),
    now: () => new Date(),
    notify: (p) => (0, notifyHelpers_1.emitNotification)(p),
    actor: (uid) => (0, notifyHelpers_1.resolveActor)(uid),
};
const fdb = () => exports.bookingDeps.db();
const nowMs = () => exports.bookingDeps.now().getTime();
const ts = (ms) => admin.firestore.Timestamp.fromMillis(ms);
const del = () => admin.firestore.FieldValue.delete();
function msOf(v) {
    const d = (0, effectiveTier_1.tierDateFromValue)(v);
    return d ? d.getTime() : null;
}
function fail(code, reason, extra = {}) {
    throw new https_1.HttpsError(code, reason, Object.assign({ code: reason }, extra));
}
async function safeNotify(p) {
    try {
        await exports.bookingDeps.notify(p);
    }
    catch (e) {
        console.error(`[bookings] notify ${p.type} -> ${p.recipientId} failed:`, e);
    }
}
async function safeActor(uid) {
    try {
        return await exports.bookingDeps.actor(uid);
    }
    catch (_a) {
        return undefined;
    }
}
async function loadConfig() {
    var _a;
    try {
        const snap = await fdb().collection('app_config').doc('experience_bookings').get();
        return (0, model_1.resolveConfig)((_a = snap.data()) !== null && _a !== void 0 ? _a : null);
    }
    catch (_b) {
        return (0, model_1.resolveConfig)(null);
    }
}
/** Admin = admin-panel user (admin_users/{uid}) or legacy users.role == 'admin'. */
async function isAdminUid(uid) {
    var _a;
    const [a, u] = await Promise.all([
        fdb().collection('admin_users').doc(uid).get(),
        fdb().collection('users').doc(uid).get(),
    ]);
    return a.exists || ((_a = u.data()) === null || _a === void 0 ? void 0 : _a.role) === 'admin';
}
/** Either user blocked the other (root blockedUsers + the profile block list). */
async function isBlockedEitherWay(a, b) {
    const db = fdb();
    const [ab, ba, pa, pb] = await Promise.all([
        db.collection('blockedUsers').where('blockerId', '==', a).where('blockedUserId', '==', b).limit(1).get(),
        db.collection('blockedUsers').where('blockerId', '==', b).where('blockedUserId', '==', a).limit(1).get(),
        db.collection('profiles').doc(a).collection('blocked_users').doc(b).get(),
        db.collection('profiles').doc(b).collection('blocked_users').doc(a).get(),
    ]);
    return !ab.empty || !ba.empty || pa.exists || pb.exists;
}
async function notifyAdmins(type, title, body, data) {
    try {
        const admins = await fdb().collection('admin_users')
            .where('role', 'in', ['super_admin', 'superAdmin', 'admin', 'moderator']).limit(50).get();
        await Promise.all(admins.docs.map((d) => safeNotify({ recipientId: d.id, type, title, body, data })));
    }
    catch (e) {
        console.error('[bookings] admin notification failed:', e);
    }
}
let cachedSecret = null;
/**
 * HMAC key for check-in codes. Generated on first use and kept in
 * server_secrets/booking_checkin (no client rule matches: default deny), so
 * nothing has to be provisioned before deploying.
 */
async function checkInSecret() {
    if (cachedSecret)
        return cachedSecret;
    const ref = fdb().collection(model_1.SERVER_SECRETS).doc('booking_checkin');
    const key = await fdb().runTransaction(async (tx) => {
        var _a;
        const snap = await tx.get(ref);
        const existing = (_a = snap.data()) === null || _a === void 0 ? void 0 : _a.key;
        if (typeof existing === 'string' && existing.length >= 32)
            return existing;
        const fresh = crypto.randomBytes(32).toString('hex');
        tx.set(ref, { key: fresh, createdAt: ts(nowMs()) });
        return fresh;
    });
    cachedSecret = key;
    return key;
}
/** Test hook. */
function resetCachedSecret() {
    cachedSecret = null;
}
// ─────────────────────────────────────────────────────────── output shape
function iso(v) {
    const m = msOf(v);
    return m === null ? null : new Date(m).toISOString();
}
/** What every callable returns about a booking (JSON-safe). */
function bookingView(id, b) {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    return {
        bookingId: id,
        experienceId: b.experienceId,
        slotId: b.slotId,
        hostId: b.hostId,
        guestId: b.guestId,
        guests: b.guests,
        status: b.status,
        requestToBook: b.requestToBook === true,
        policy: b.policy,
        price: (_a = b.price) !== null && _a !== void 0 ? _a : null,
        payment: {
            mode: (_c = (_b = b.payment) === null || _b === void 0 ? void 0 : _b.mode) !== null && _c !== void 0 ? _c : 'free',
            link: (_e = (_d = b.payment) === null || _d === void 0 ? void 0 : _d.link) !== null && _e !== void 0 ? _e : null,
            guestMarkedPaidAt: iso((_f = b.payment) === null || _f === void 0 ? void 0 : _f.guestMarkedPaidAt),
            hostConfirmedPaidAt: iso((_g = b.payment) === null || _g === void 0 ? void 0 : _g.hostConfirmedPaidAt),
        },
        refundDue: b.refundDue
            ? Object.assign(Object.assign({}, b.refundDue), { decidedAt: iso(b.refundDue.decidedAt) }) : null,
        slotStart: iso(b.slotStart),
        slotEnd: iso(b.slotEnd),
        requestExpiresAt: iso(b.requestExpiresAt),
        checkedInAt: iso((_h = b.checkIn) === null || _h === void 0 ? void 0 : _h.at),
        dispute: b.dispute
            ? { status: b.dispute.status, openedAt: iso(b.dispute.openedAt), resolution: b.dispute.resolution
                    ? Object.assign(Object.assign({}, b.dispute.resolution), { at: iso(b.dispute.resolution.at) }) : null }
            : null,
    };
}
function notifData(bookingId, b) {
    return { action: 'booking', bookingId, experienceId: String(b.experienceId || '') };
}
/** Confirmation text that tells the guest how to pay. */
function payHint(b) {
    var _a;
    const mode = (_a = b.payment) === null || _a === void 0 ? void 0 : _a.mode;
    if (mode === 'link')
        return `${title(b)} — pay the host with their payment link.`;
    if (mode === 'cash')
        return `${title(b)} — pay the host in cash when you meet.`;
    return title(b);
}
function title(b) {
    const t = typeof b.experienceTitle === 'string' ? b.experienceTitle.trim() : '';
    return t.length > 80 ? `${t.slice(0, 79)}…` : (t || 'Experience');
}
/** Host cancellation bookkeeping, inside a transaction (reads done by caller). */
function writeHostPenalty(tx, hostId, statsSnap, now, cfg, context) {
    const d = statsSnap.data() || {};
    const prev = (Array.isArray(d.recent) ? d.recent : [])
        .map((x) => msOf(x)).filter((x) => x !== null);
    const recent = (0, model_1.pruneCancellations)(prev, now, cfg);
    const flag = (0, model_1.shouldFlagHost)(recent, msOf(d.flaggedAt), now, cfg);
    tx.set(statsSnap.ref, Object.assign({ hostId, recent: recent.map(ts), count: recent.length, updatedAt: ts(now) }, (flag ? { flaggedAt: ts(now) } : {})), { merge: true });
    if (flag) {
        tx.set(fdb().collection(model_1.HOST_FLAGS).doc(hostId), Object.assign(Object.assign({ hostId, type: 'excess_host_cancellations', status: 'open', count: recent.length, windowDays: cfg.hostCancelWindowDays }, context), { createdAt: ts(now), updatedAt: ts(now) }), { merge: true });
    }
    return flag;
}
async function transition(bookingId, decide, cfg) {
    const db = fdb();
    const ref = db.collection(model_1.BOOKINGS).doc(bookingId);
    return db.runTransaction(async (tx) => {
        var _a, _b;
        const snap = await tx.get(ref);
        if (!snap.exists)
            fail('not-found', 'booking_not_found');
        const b = snap.data();
        const now = nowMs();
        const plan = decide(b, now);
        if (plan.noop)
            return { id: bookingId, before: b, after: b, noop: true, hostFlagged: false };
        if (plan.to && !(0, model_1.canTransition)(b.status, plan.to)) {
            fail('failed-precondition', 'invalid_transition', { from: b.status, to: plan.to });
        }
        const release = plan.to ? (0, model_1.seatsReleased)(b.status, plan.to, Number(b.guests) || 0) : 0;
        const slotRef = db.collection(model_1.EXPERIENCES).doc(b.experienceId).collection(model_1.SLOTS).doc(b.slotId);
        const statsRef = db.collection(model_1.HOST_CANCEL_STATS).doc(b.hostId);
        // All reads before any write.
        const slotSnap = release > 0 ? await tx.get(slotRef) : null;
        const statsSnap = plan.hostPenalty ? await tx.get(statsRef) : null;
        const after = Object.assign(Object.assign(Object.assign(Object.assign({}, b), (plan.patch || {})), (plan.to ? { status: plan.to } : {})), { updatedAt: ts(now) });
        tx.update(ref, Object.assign(Object.assign(Object.assign({}, (plan.patch || {})), (plan.to ? { status: plan.to } : {})), { updatedAt: ts(now) }));
        if (slotSnap === null || slotSnap === void 0 ? void 0 : slotSnap.exists) {
            const booked = Number((_a = slotSnap.data()) === null || _a === void 0 ? void 0 : _a.bookedCount) || 0;
            tx.update(slotRef, { bookedCount: Math.max(0, booked - release), updatedAt: ts(now) });
        }
        let hostFlagged = false;
        if (statsSnap) {
            hostFlagged = writeHostPenalty(tx, b.hostId, statsSnap, now, cfg, {
                lastBookingId: bookingId, lastExperienceId: b.experienceId,
            });
        }
        (_b = plan.extra) === null || _b === void 0 ? void 0 : _b.call(plan, tx, after);
        return { id: bookingId, before: b, after, noop: false, hostFlagged };
    });
}
function roleOf(uid, b) {
    if (uid === b.guestId)
        return 'guest';
    if (uid === b.hostId)
        return 'host';
    return null;
}
function requireBookingId(data) {
    const id = data === null || data === void 0 ? void 0 : data.bookingId;
    if (!(0, model_1.isDocId)(id))
        fail('invalid-argument', 'invalid_booking_id');
    return id;
}
function eligibilityWrite(tx, b, bookingId, now, cfg) {
    var _a;
    const end = (_a = msOf(b.slotEnd)) !== null && _a !== void 0 ? _a : now;
    tx.set(fdb().collection(model_1.EXPERIENCES).doc(b.experienceId).collection(model_1.REVIEW_ELIGIBILITY).doc(b.guestId), {
        bookingId,
        guestId: b.guestId,
        hostId: b.hostId,
        experienceId: b.experienceId,
        reviewUntil: ts(Math.max(end, now) + cfg.reviewWindowDays * model_1.DAY_MS),
        createdAt: ts(now),
    });
}
async function flaggedHostFollowUp(r, hostId) {
    if (!r.hostFlagged)
        return;
    await notifyAdmins('admin_host_cancellations', 'Host flagged for cancellations', `Host ${hostId} cancelled confirmed bookings repeatedly. Review host_flags/${hostId}.`, { action: 'admin_host_flag', hostId });
}
// ─────────────────────────────────────────────────────────── createBooking
async function createBooking(uid, data) {
    var _a, _b, _c;
    const { experienceId, slotId, guests, requestId } = data || {};
    if (!(0, model_1.isDocId)(experienceId))
        fail('invalid-argument', 'invalid_experience_id');
    if (!(0, model_1.isDocId)(slotId))
        fail('invalid-argument', 'invalid_slot_id');
    if (!(0, model_1.isRequestId)(requestId))
        fail('invalid-argument', 'invalid_request_id');
    // The booking terms the guest accepted: passed explicitly (string or int),
    // or taken from their user_experiences/{id}/booking_consents/{uid} record.
    let consentVersion = Number.isInteger(data === null || data === void 0 ? void 0 : data.consentVersion)
        ? String(data.consentVersion)
        : (0, model_1.cleanText)(data === null || data === void 0 ? void 0 : data.consentVersion, 32);
    if (!consentVersion) {
        const consent = await fdb().collection(model_1.EXPERIENCES).doc(experienceId)
            .collection('booking_consents').doc(uid).get();
        const v = (_a = consent.data()) === null || _a === void 0 ? void 0 : _a.version;
        if (consent.exists && ((_b = consent.data()) === null || _b === void 0 ? void 0 : _b.experienceId) === experienceId && Number.isInteger(v)) {
            consentVersion = String(v);
        }
    }
    if (!consentVersion)
        fail('invalid-argument', 'consent_required');
    const cfg = await loadConfig();
    if (!Number.isInteger(guests) || guests < 1 || guests > cfg.maxGuestsPerBooking) {
        fail('invalid-argument', 'invalid_guests', { max: cfg.maxGuestsPerBooking });
    }
    const db = fdb();
    const bookingId = (0, model_1.bookingIdFor)(uid, requestId);
    const bookingRef = db.collection(model_1.BOOKINGS).doc(bookingId);
    const expRef = db.collection(model_1.EXPERIENCES).doc(experienceId);
    const slotRef = expRef.collection(model_1.SLOTS).doc(slotId);
    // Retry of a booking that already exists: answer without re-validating.
    const prior = await bookingRef.get();
    if (prior.exists) {
        const p = prior.data();
        if (p.guestId !== uid)
            fail('already-exists', 'request_id_conflict');
        return Object.assign(Object.assign({}, bookingView(bookingId, p)), { alreadyExisted: true });
    }
    const pre = await expRef.get();
    if (!pre.exists)
        fail('not-found', 'experience_not_found');
    const hostId = String(((_c = pre.data()) === null || _c === void 0 ? void 0 : _c.hostId) || '');
    if (!hostId)
        fail('failed-precondition', 'experience_not_bookable');
    if (hostId === uid)
        fail('failed-precondition', 'own_experience');
    if (await isBlockedEitherWay(hostId, uid))
        fail('permission-denied', 'not_available');
    const result = await db.runTransaction(async (tx) => {
        var _a, _b, _c;
        const dupQ = db.collection(model_1.BOOKINGS)
            .where('guestId', '==', uid)
            .where('slotId', '==', slotId)
            .where('status', 'in', model_1.ACTIVE_STATUSES)
            .limit(10);
        const [existing, exp, slot, guestP, hostP, susp, dup] = await Promise.all([
            tx.get(bookingRef), tx.get(expRef), tx.get(slotRef),
            tx.get(db.collection('profiles').doc(uid)),
            tx.get(db.collection('profiles').doc(hostId)),
            tx.get(db.collection(model_1.HOST_SUSPENSIONS).doc(hostId)),
            tx.get(dupQ),
        ]);
        if (existing.exists) {
            const e = existing.data();
            if (e.guestId !== uid)
                fail('already-exists', 'request_id_conflict');
            return { created: false, booking: e };
        }
        const now = nowMs();
        const e = exp.data();
        if (!e || e.hostId !== hostId)
            fail('not-found', 'experience_not_found');
        if (e.status !== 'published')
            fail('failed-precondition', 'experience_not_bookable');
        const host = (_a = hostP.data()) !== null && _a !== void 0 ? _a : null;
        if (!hostP.exists || (0, model_1.isBannedProfile)(host))
            fail('failed-precondition', 'host_unavailable');
        if (susp.exists && ((_b = susp.data()) === null || _b === void 0 ? void 0 : _b.active) !== false)
            fail('failed-precondition', 'host_unavailable');
        const guest = (_c = guestP.data()) !== null && _c !== void 0 ? _c : null;
        if (!guestP.exists || (0, model_1.isBannedProfile)(guest))
            fail('permission-denied', 'account_restricted');
        if ((0, model_1.idDocumentStateOf)(guest) === 'none')
            fail('failed-precondition', 'id_document_required');
        const priced = (0, model_1.computeBookingPrice)(e, guests);
        if (priced.ok === false)
            fail('failed-precondition', 'experience_price_invalid', { reason: priced.reason });
        let mode = 'free';
        let link = null;
        if (!priced.free) {
            if ((0, model_1.idDocumentStateOf)(host) !== 'approved')
                fail('failed-precondition', 'host_not_verified');
            const choice = (0, model_1.choosePaymentMethod)(e, data === null || data === void 0 ? void 0 : data.paymentMethod);
            if (choice.ok === false) {
                fail(choice.reason === 'no_payment_method' ? 'failed-precondition' : 'invalid-argument', choice.reason, {
                    accepted: (0, model_1.acceptedPaymentMethods)(e),
                });
            }
            mode = choice.method;
            if (mode === 'link') {
                const pl = e.paymentLink;
                link = { type: String(pl.type), value: String(pl.value).trim() };
            }
        }
        const s = slot.data();
        if (!s)
            fail('not-found', 'slot_not_found');
        if (s.status !== 'open')
            fail('failed-precondition', 'slot_closed');
        const start = msOf(s.start);
        const end = msOf(s.end);
        if (start === null || end === null || end <= start)
            fail('failed-precondition', 'slot_invalid');
        if (start <= now)
            fail('failed-precondition', 'slot_started');
        if (Number.isInteger(e.maxGroupSize) && guests > e.maxGroupSize) {
            fail('invalid-argument', 'too_many_guests', { max: e.maxGroupSize });
        }
        if (dup.docs.some((d) => { var _a; return ((_a = d.data()) === null || _a === void 0 ? void 0 : _a.experienceId) === experienceId; })) {
            fail('already-exists', 'already_booked', { bookingId: dup.docs[0].id });
        }
        const capacity = Number(s.capacity) || 0;
        const booked = Number(s.bookedCount) || 0;
        if (capacity - booked < guests) {
            fail('resource-exhausted', 'slot_full', { seatsLeft: Math.max(0, capacity - booked) });
        }
        // Request to book is mandatory: the host accepts or declines every booking.
        const requested = true;
        const booking = Object.assign({ experienceId,
            slotId,
            hostId, guestId: uid, guests, status: requested ? 'requested' : 'confirmed', requestToBook: requested, policy: (0, model_1.policyOf)(e), experienceTitle: typeof e.title === 'string' ? e.title.slice(0, 120) : null, slotStart: ts(start), slotEnd: ts(end), price: priced.price, payment: {
                mode,
                link,
                guestMarkedPaidAt: null,
                hostConfirmedPaidAt: null,
            }, refundDue: null, cancellation: null, checkIn: null, dispute: null, consentVersion,
            requestId, createdAt: ts(now), updatedAt: ts(now) }, (requested
            ? { requestExpiresAt: ts((0, model_1.requestExpiresAtMs)(now, start, cfg)) }
            : {
                confirmedAt: ts(now),
                reminderAt: ts((0, model_1.reminderAtMs)(start, cfg)),
                completeAt: ts((0, model_1.completeAtMs)(end, cfg)),
            }));
        tx.set(bookingRef, booking);
        tx.update(slotRef, { bookedCount: booked + guests, updatedAt: ts(now) });
        return { created: true, booking };
    });
    const b = result.booking;
    if (result.created) {
        const actor = await safeActor(uid);
        const d = notifData(bookingId, b);
        if (b.status === 'requested') {
            await safeNotify({ recipientId: hostId, type: 'booking_request', title: 'requested to book your experience', body: title(b), data: d, actor });
        }
        else {
            await safeNotify({ recipientId: hostId, type: 'booking_new', title: 'booked your experience', body: title(b), data: d, actor });
            await safeNotify({
                recipientId: uid, type: 'booking_confirmed', title: 'Booking confirmed',
                body: payHint(b),
                data: d,
            });
        }
    }
    return Object.assign(Object.assign({}, bookingView(bookingId, b)), { alreadyExisted: !result.created });
}
// ─────────────────────────────────────────────────────────── host responds
async function respondToBookingRequest(uid, data) {
    const bookingId = requireBookingId(data);
    if (typeof (data === null || data === void 0 ? void 0 : data.accept) !== 'boolean')
        fail('invalid-argument', 'accept_required');
    const accept = data.accept;
    const cfg = await loadConfig();
    const r = await transition(bookingId, (b, now) => {
        if (uid !== b.hostId)
            fail('permission-denied', 'not_host');
        if (accept && b.status === 'confirmed')
            return { noop: true };
        if (!accept && b.status === 'declined')
            return { noop: true };
        if (b.status !== 'requested')
            fail('failed-precondition', 'not_pending', { status: b.status });
        const expires = msOf(b.requestExpiresAt);
        if (expires !== null && now >= expires)
            fail('failed-precondition', 'request_expired');
        if (!accept)
            return { to: 'declined', patch: { requestExpiresAt: del(), respondedAt: ts(now) } };
        const start = msOf(b.slotStart);
        const end = msOf(b.slotEnd);
        if (start <= now)
            fail('failed-precondition', 'slot_started');
        return {
            to: 'confirmed',
            patch: {
                requestExpiresAt: del(),
                respondedAt: ts(now),
                confirmedAt: ts(now),
                reminderAt: ts((0, model_1.reminderAtMs)(start, cfg)),
                completeAt: ts((0, model_1.completeAtMs)(end, cfg)),
            },
        };
    }, cfg);
    if (!r.noop) {
        const actor = await safeActor(uid);
        await safeNotify({
            recipientId: r.after.guestId,
            type: accept ? 'booking_accepted' : 'booking_declined',
            title: accept ? 'accepted your booking request' : 'declined your booking request',
            body: accept ? payHint(r.after) : title(r.after),
            data: notifData(bookingId, r.after),
            actor,
        });
    }
    return bookingView(bookingId, r.after);
}
// ─────────────────────────────────────────────────────────── cancel
async function cancelBooking(uid, data) {
    const bookingId = requireBookingId(data);
    const reason = (0, model_1.cleanText)(data === null || data === void 0 ? void 0 : data.reason, 500);
    const cfg = await loadConfig();
    const r = await transition(bookingId, (b, now) => {
        var _a, _b;
        const by = roleOf(uid, b);
        if (!by)
            fail('permission-denied', 'not_a_party');
        if (b.status === `cancelled_by_${by}`)
            return { noop: true };
        if (b.status !== 'requested' && b.status !== 'confirmed') {
            fail('failed-precondition', 'not_cancellable', { status: b.status });
        }
        const start = msOf(b.slotStart);
        if (now >= start)
            fail('failed-precondition', 'already_started');
        const wasConfirmed = b.status === 'confirmed';
        const percent = wasConfirmed
            // Every booking is a request: the guest's booking (and its 24 h grace
            // window) starts when the host CONFIRMS it, not when it was requested.
            ? (0, model_1.refundFor)(b.policy, now, start, (_b = (_a = msOf(b.confirmedAt)) !== null && _a !== void 0 ? _a : msOf(b.createdAt)) !== null && _b !== void 0 ? _b : now, by)
            : 100;
        const due = wasConfirmed
            ? (0, model_1.refundDueFor)(b.price, b.payment, percent, by === 'host' ? 'host_cancelled' : 'guest_cancelled')
            : null;
        return {
            to: by === 'host' ? 'cancelled_by_host' : 'cancelled_by_guest',
            patch: {
                cancellation: { by, at: ts(now), reason },
                refundDue: due ? Object.assign(Object.assign({}, due), { decidedAt: ts(now) }) : null,
                reminderAt: del(),
                completeAt: del(),
                requestExpiresAt: del(),
            },
            hostPenalty: by === 'host' && wasConfirmed,
        };
    }, cfg);
    if (!r.noop) {
        const by = roleOf(uid, r.before);
        const other = by === 'guest' ? r.before.hostId : r.before.guestId;
        const actor = await safeActor(uid);
        await safeNotify({
            recipientId: other,
            type: 'booking_cancelled',
            title: by === 'guest' ? 'cancelled their booking' : 'cancelled your booking',
            body: r.after.refundDue && r.after.refundDue.amount > 0
                ? `${title(r.after)} — refund owed: ${r.after.refundDue.percent}%.`
                : title(r.after),
            data: notifData(bookingId, r.after),
            actor,
        });
        await flaggedHostFollowUp(r, r.before.hostId);
    }
    return bookingView(bookingId, r.after);
}
// ─────────────────────────────────────────────────────────── check-in
async function getBookingCheckInCode(uid, data) {
    const bookingId = requireBookingId(data);
    const snap = await fdb().collection(model_1.BOOKINGS).doc(bookingId).get();
    if (!snap.exists)
        fail('not-found', 'booking_not_found');
    const b = snap.data();
    if (b.guestId !== uid)
        fail('permission-denied', 'not_guest');
    if (b.status !== 'confirmed')
        fail('failed-precondition', 'not_confirmed', { status: b.status });
    const code = (0, model_1.checkInCode)(await checkInSecret(), bookingId);
    return { bookingId, code, qrPayload: (0, model_1.checkInQrPayload)(bookingId, code) };
}
async function checkInBooking(uid, data) {
    const bookingId = requireBookingId(data);
    const cashReceived = (data === null || data === void 0 ? void 0 : data.cashReceived) === true;
    const cfg = await loadConfig();
    const secret = await checkInSecret();
    const r = await transition(bookingId, (b, now) => {
        var _a, _b, _c;
        if (uid !== b.hostId)
            fail('permission-denied', 'not_host');
        const wantsCash = cashReceived && ((_a = b.payment) === null || _a === void 0 ? void 0 : _a.mode) === 'cash' && !((_b = b.payment) === null || _b === void 0 ? void 0 : _b.hostConfirmedPaidAt);
        if (b.status === 'confirmed' && b.checkIn && !wantsCash)
            return { noop: true };
        if (b.status !== 'confirmed')
            fail('failed-precondition', 'not_confirmed', { status: b.status });
        if (!(0, model_1.verifyCheckInCode)(secret, bookingId, data === null || data === void 0 ? void 0 : data.code))
            fail('permission-denied', 'invalid_code');
        if (!(0, model_1.inCheckInWindow)(now, msOf(b.slotStart), msOf(b.slotEnd), cfg)) {
            fail('failed-precondition', 'outside_checkin_window');
        }
        return {
            patch: Object.assign({ checkIn: (_c = b.checkIn) !== null && _c !== void 0 ? _c : { at: ts(now), byUid: uid } }, (wantsCash ? { payment: Object.assign(Object.assign({}, b.payment), { hostConfirmedPaidAt: ts(now) }) } : {})),
            extra: b.checkIn ? undefined : (tx, after) => eligibilityWrite(tx, after, bookingId, now, cfg),
        };
    }, cfg);
    if (!r.noop && !r.before.checkIn) {
        await safeNotify({
            recipientId: r.after.guestId, type: 'booking_checked_in', title: 'You are checked in',
            body: title(r.after), data: notifData(bookingId, r.after),
        });
    }
    return Object.assign(Object.assign({}, bookingView(bookingId, r.after)), { alreadyCheckedIn: !!r.before.checkIn });
}
// ─────────────────────────────────────────────────────────── no-show
async function markNoShow(uid, data) {
    const bookingId = requireBookingId(data);
    const cfg = await loadConfig();
    const r = await transition(bookingId, (b, now) => {
        if (uid !== b.hostId)
            fail('permission-denied', 'not_host');
        if (b.status === 'no_show')
            return { noop: true };
        if (b.status !== 'confirmed')
            fail('failed-precondition', 'not_confirmed', { status: b.status });
        if (b.checkIn)
            fail('failed-precondition', 'guest_checked_in');
        if (!(0, model_1.canMarkNoShow)(now, msOf(b.slotStart), cfg))
            fail('failed-precondition', 'too_early');
        // A guest no-show is a late cancellation: the policy's 0% band.
        const due = (0, model_1.refundDueFor)(b.price, b.payment, 0, 'guest_no_show');
        return {
            to: 'no_show',
            patch: {
                noShowAt: ts(now),
                refundDue: due ? Object.assign(Object.assign({}, due), { decidedAt: ts(now) }) : null,
                reminderAt: del(),
                completeAt: del(),
            },
        };
    }, cfg);
    if (!r.noop) {
        const actor = await safeActor(uid);
        await safeNotify({
            recipientId: r.after.guestId, type: 'booking_no_show', title: 'marked you as a no-show',
            body: `${title(r.after)} — you can contest this within ${cfg.disputeWindowHours} h of the end.`,
            data: notifData(bookingId, r.after), actor,
        });
    }
    return bookingView(bookingId, r.after);
}
// ─────────────────────────────────────────────────────────── paid marks
const PAYABLE_STATUSES = ['confirmed', 'completed', 'no_show', 'disputed', 'resolved'];
/**
 * Off-platform payment confirmations (informational, never money):
 *   guest, mode link  -> payment.guestMarkedPaidAt   ("I paid via the link")
 *   host,  mode link  -> payment.hostConfirmedPaidAt ("I received it")
 *   host,  mode cash  -> payment.hostConfirmedPaidAt, only at / after check-in
 *                        (or once the slot started). Also: checkInBooking
 *                        {cashReceived: true}, confirmCashReceived.
 * A guest cannot mark cash as paid (only the host can confirm receiving it).
 */
async function markBookingPaid(uid, data, onlyMode) {
    const bookingId = requireBookingId(data);
    const cfg = await loadConfig();
    const r = await transition(bookingId, (b, now) => {
        var _a, _b, _c;
        const role = roleOf(uid, b);
        if (!role)
            fail('permission-denied', 'not_a_party');
        const mode = (_a = b.payment) === null || _a === void 0 ? void 0 : _a.mode;
        if (onlyMode && mode !== onlyMode)
            fail('failed-precondition', 'not_cash_payment');
        if (mode !== 'link' && mode !== 'cash')
            fail('failed-precondition', 'not_paid_booking');
        if (mode === 'cash' && role !== 'host')
            fail('permission-denied', 'host_confirms_cash');
        if (!PAYABLE_STATUSES.includes(b.status))
            fail('failed-precondition', 'not_confirmed', { status: b.status });
        if (mode === 'cash' && !b.checkIn && now < ((_b = msOf(b.slotStart)) !== null && _b !== void 0 ? _b : Infinity)) {
            fail('failed-precondition', 'cash_before_meeting');
        }
        const field = role === 'guest' ? 'guestMarkedPaidAt' : 'hostConfirmedPaidAt';
        if ((_c = b.payment) === null || _c === void 0 ? void 0 : _c[field])
            return { noop: true };
        return { patch: { payment: Object.assign(Object.assign({}, b.payment), { [field]: ts(now) }) } };
    }, cfg);
    if (!r.noop) {
        const guestSide = uid === r.before.guestId;
        const actor = await safeActor(uid);
        await safeNotify({
            recipientId: guestSide ? r.before.hostId : r.before.guestId,
            type: guestSide ? 'booking_payment_marked' : 'booking_payment_confirmed',
            title: guestSide ? 'says they paid for their booking' : 'confirmed your payment',
            body: title(r.after), data: notifData(bookingId, r.after), actor,
        });
    }
    return bookingView(bookingId, r.after);
}
/** Host: "I received the cash" (mode cash only). */
function confirmCashReceived(uid, data) {
    return markBookingPaid(uid, data, 'cash');
}
// ─────────────────────────────────────────────────────────── disputes
async function removeReviewEligibility(b, bookingId) {
    var _a, _b;
    const expRef = fdb().collection(model_1.EXPERIENCES).doc(b.experienceId);
    try {
        const [elig, pending] = await Promise.all([
            expRef.collection(model_1.REVIEW_ELIGIBILITY).doc(b.guestId).get(),
            expRef.collection(model_1.PENDING_REVIEWS).doc(b.guestId).get(),
        ]);
        if (elig.exists && ((_a = elig.data()) === null || _a === void 0 ? void 0 : _a.bookingId) === bookingId)
            await elig.ref.delete();
        if (pending.exists && ((_b = pending.data()) === null || _b === void 0 ? void 0 : _b.bookingId) === bookingId)
            await pending.ref.delete();
    }
    catch (e) {
        console.error(`[bookings] eligibility cleanup ${bookingId} failed:`, e);
    }
}
async function openBookingDispute(uid, data) {
    const bookingId = requireBookingId(data);
    const reason = (0, model_1.cleanText)(data === null || data === void 0 ? void 0 : data.reason, 1000);
    if (!reason || reason.length < 10)
        fail('invalid-argument', 'reason_required');
    const cfg = await loadConfig();
    const r = await transition(bookingId, (b, now) => {
        if (uid !== b.guestId)
            fail('permission-denied', 'not_guest');
        if (b.status === 'disputed')
            return { noop: true };
        if (b.status !== 'confirmed' && b.status !== 'no_show') {
            fail('failed-precondition', 'not_disputable', { status: b.status });
        }
        if (!(0, model_1.inDisputeWindow)(now, msOf(b.slotStart), msOf(b.slotEnd), cfg)) {
            fail('failed-precondition', 'outside_dispute_window');
        }
        return {
            to: 'disputed',
            patch: {
                dispute: { openedAt: ts(now), byUid: uid, reason, status: 'open', resolution: null, fromStatus: b.status },
                reminderAt: del(),
                completeAt: del(),
            },
        };
    }, cfg);
    if (!r.noop) {
        await removeReviewEligibility(r.after, bookingId);
        const actor = await safeActor(uid);
        await safeNotify({
            recipientId: r.after.hostId, type: 'booking_dispute', title: 'reported a problem with their booking',
            body: title(r.after), data: notifData(bookingId, r.after), actor,
        });
        await notifyAdmins('admin_booking_dispute', 'Booking dispute opened', `${title(r.after)} — booking ${bookingId}`, {
            action: 'admin_booking_dispute', bookingId,
        });
    }
    return bookingView(bookingId, r.after);
}
async function resolveBookingDispute(uid, data) {
    var _a, _b, _c;
    const bookingId = requireBookingId(data);
    if (!(await isAdminUid(uid)))
        fail('permission-denied', 'admin_only');
    const refundPercent = data === null || data === void 0 ? void 0 : data.refundPercent;
    if (!Number.isInteger(refundPercent) || refundPercent < 0 || refundPercent > 100) {
        fail('invalid-argument', 'invalid_refund_percent');
    }
    const hostAction = (_a = data === null || data === void 0 ? void 0 : data.hostAction) !== null && _a !== void 0 ? _a : 'none';
    if (!model_1.HOST_ACTIONS.includes(hostAction))
        fail('invalid-argument', 'invalid_host_action');
    const note = (0, model_1.cleanText)(data === null || data === void 0 ? void 0 : data.note, 1000);
    const cfg = await loadConfig();
    const r = await transition(bookingId, (b, now) => {
        var _a;
        if (b.status === 'resolved')
            return { noop: true };
        if (b.status !== 'disputed')
            fail('failed-precondition', 'not_disputed', { status: b.status });
        const due = refundPercent > 0
            ? (0, model_1.refundDueFor)(b.price, b.payment, refundPercent, 'dispute_resolution')
            : null;
        return {
            to: 'resolved',
            patch: {
                dispute: Object.assign(Object.assign({}, (b.dispute || {})), { status: 'resolved', resolution: { refundPercent, hostAction, note, byUid: uid, at: ts(now) } }),
                refundDue: due ? Object.assign(Object.assign({}, due), { decidedAt: ts(now) }) : ((_a = b.refundDue) !== null && _a !== void 0 ? _a : null),
            },
        };
    }, cfg);
    if (!r.noop) {
        const b = r.after;
        const now = nowMs();
        try {
            if (hostAction === 'hide_listing') {
                const expRef = fdb().collection(model_1.EXPERIENCES).doc(b.experienceId);
                const exp = await expRef.get();
                if (exp.exists && ((_b = exp.data()) === null || _b === void 0 ? void 0 : _b.status) !== 'hidden') {
                    await expRef.update({
                        status: 'hidden',
                        moderation: {
                            auto: false, reason: 'booking_dispute', bookingId,
                            previousStatus: ((_c = exp.data()) === null || _c === void 0 ? void 0 : _c.status) === 'published' ? 'published' : 'draft',
                        },
                    });
                }
            }
            else if (hostAction === 'suspend_hosting') {
                await fdb().collection(model_1.HOST_SUSPENSIONS).doc(b.hostId).set({
                    hostId: b.hostId, active: true, reason: 'booking_dispute', bookingId, byUid: uid, createdAt: ts(now),
                }, { merge: true });
            }
        }
        catch (e) {
            console.error(`[bookings] host action ${hostAction} for ${bookingId} failed:`, e);
        }
        const d = notifData(bookingId, b);
        const due = b.refundDue && b.refundDue.amount > 0 ? ` Refund owed: ${b.refundDue.percent}%.` : '';
        await safeNotify({ recipientId: b.guestId, type: 'booking_dispute_resolved', title: 'Your report was reviewed', body: `${title(b)}.${due}`, data: d });
        await safeNotify({
            recipientId: b.hostId,
            type: hostAction === 'warn' ? 'booking_host_warning' : 'booking_dispute_resolved',
            title: hostAction === 'warn' ? 'Warning about one of your bookings' : 'A booking report was reviewed',
            body: `${title(b)}.${due}`, data: d,
        });
    }
    return bookingView(bookingId, r.after);
}
// ─────────────────────────────────────────────────────────── slot cancel
/**
 * Host cancels a whole slot: the slot becomes 'cancelled' and every active
 * booking on it becomes cancelled_by_host (100% owed back). Counts ONE host
 * cancellation when any confirmed booking was affected. Re-callable: a slot
 * already cancelled finishes any booking still active (pages of 400).
 */
async function cancelSlot(uid, data) {
    const { experienceId, slotId } = data || {};
    if (!(0, model_1.isDocId)(experienceId))
        fail('invalid-argument', 'invalid_experience_id');
    if (!(0, model_1.isDocId)(slotId))
        fail('invalid-argument', 'invalid_slot_id');
    const reason = (0, model_1.cleanText)(data === null || data === void 0 ? void 0 : data.reason, 500);
    const cfg = await loadConfig();
    const db = fdb();
    const expRef = db.collection(model_1.EXPERIENCES).doc(experienceId);
    const slotRef = expRef.collection(model_1.SLOTS).doc(slotId);
    const PAGE = 400;
    const res = await db.runTransaction(async (tx) => {
        var _a, _b;
        const q = db.collection(model_1.BOOKINGS)
            .where('experienceId', '==', experienceId)
            .where('slotId', '==', slotId)
            .where('status', 'in', model_1.ACTIVE_STATUSES)
            .limit(PAGE);
        const [exp, slot, active] = await Promise.all([tx.get(expRef), tx.get(slotRef), tx.get(q)]);
        if (!exp.exists)
            fail('not-found', 'experience_not_found');
        if (((_a = exp.data()) === null || _a === void 0 ? void 0 : _a.hostId) !== uid)
            fail('permission-denied', 'not_host');
        if (!slot.exists)
            fail('not-found', 'slot_not_found');
        const now = nowMs();
        const docs = active.docs;
        const anyConfirmed = docs.some((d) => { var _a; return ((_a = d.data()) === null || _a === void 0 ? void 0 : _a.status) === 'confirmed'; });
        const statsSnap = anyConfirmed ? await tx.get(db.collection(model_1.HOST_CANCEL_STATS).doc(uid)) : null;
        let released = 0;
        const cancelled = [];
        for (const d of docs) {
            const b = d.data();
            if (!(0, model_1.canTransition)(b.status, 'cancelled_by_host'))
                continue;
            const due = b.status === 'confirmed'
                ? (0, model_1.refundDueFor)(b.price, b.payment, 100, 'host_cancelled')
                : null;
            released += (0, model_1.seatsReleased)(b.status, 'cancelled_by_host', Number(b.guests) || 0);
            const patch = {
                status: 'cancelled_by_host',
                cancellation: { by: 'host', at: ts(now), reason: reason !== null && reason !== void 0 ? reason : 'slot_cancelled' },
                refundDue: due ? Object.assign(Object.assign({}, due), { decidedAt: ts(now) }) : null,
                reminderAt: del(), completeAt: del(), requestExpiresAt: del(),
                updatedAt: ts(now),
            };
            tx.update(d.ref, patch);
            cancelled.push({ id: d.id, b: Object.assign(Object.assign({}, b), { status: 'cancelled_by_host' }) });
        }
        const booked = Number((_b = slot.data()) === null || _b === void 0 ? void 0 : _b.bookedCount) || 0;
        tx.update(slotRef, { status: 'cancelled', bookedCount: Math.max(0, booked - released), updatedAt: ts(now) });
        let hostFlagged = false;
        if (statsSnap) {
            hostFlagged = writeHostPenalty(tx, uid, statsSnap, now, cfg, {
                lastExperienceId: experienceId, lastSlotId: slotId,
            });
        }
        return { cancelled, hostFlagged, more: docs.length >= PAGE };
    });
    const actor = await safeActor(uid);
    await Promise.all(res.cancelled.map(({ id, b }) => safeNotify({
        recipientId: b.guestId, type: 'booking_cancelled', title: 'cancelled your booking',
        body: title(b),
        data: notifData(id, b), actor,
    })));
    await flaggedHostFollowUp(res, uid);
    return { experienceId, slotId, cancelledBookings: res.cancelled.length, more: res.more };
}
// ─────────────────────────────────────────────────────────── experience deleted
/**
 * A deleted experience: future active bookings become cancelled_by_host (one
 * host cancellation counted when any was confirmed); the slots, review
 * eligibility markers and unrevealed pending reviews are deleted.
 */
async function onExperienceDeleted(experienceId, hostId) {
    const db = fdb();
    const cfg = await loadConfig();
    const now = nowMs();
    let cancelledCount = 0;
    let anyConfirmed = false;
    const toNotify = [];
    for (let guard = 0; guard < 50; guard++) {
        const page = await db.collection(model_1.BOOKINGS)
            .where('experienceId', '==', experienceId)
            .where('status', 'in', model_1.ACTIVE_STATUSES)
            .limit(300)
            .get();
        const future = page.docs.filter((d) => { var _a, _b; return ((_b = msOf((_a = d.data()) === null || _a === void 0 ? void 0 : _a.slotStart)) !== null && _b !== void 0 ? _b : 0) > now; });
        if (future.length === 0)
            break;
        const batch = db.batch();
        for (const d of future) {
            const b = d.data();
            if (b.status === 'confirmed')
                anyConfirmed = true;
            const due = b.status === 'confirmed' ? (0, model_1.refundDueFor)(b.price, b.payment, 100, 'experience_deleted') : null;
            batch.update(d.ref, {
                status: 'cancelled_by_host',
                cancellation: { by: 'host', at: ts(now), reason: 'experience_deleted' },
                refundDue: due ? Object.assign(Object.assign({}, due), { decidedAt: ts(now) }) : null,
                reminderAt: del(), completeAt: del(), requestExpiresAt: del(),
                updatedAt: ts(now),
            });
            toNotify.push({ id: d.id, b });
        }
        await batch.commit();
        cancelledCount += future.length;
        if (page.docs.length < 300)
            break;
    }
    if (anyConfirmed && hostId) {
        const r = await db.runTransaction(async (tx) => {
            const stats = await tx.get(db.collection(model_1.HOST_CANCEL_STATS).doc(hostId));
            return { hostFlagged: writeHostPenalty(tx, hostId, stats, now, cfg, { lastExperienceId: experienceId }) };
        });
        await flaggedHostFollowUp(r, hostId);
    }
    await Promise.all(toNotify.map(({ id, b }) => safeNotify({
        recipientId: b.guestId, type: 'booking_cancelled', title: 'Your booking was cancelled',
        body: `${title(b)} is no longer available.`, data: notifData(id, b),
    })));
    const expRef = db.collection(model_1.EXPERIENCES).doc(experienceId);
    for (const sub of [model_1.SLOTS, model_1.REVIEW_ELIGIBILITY, model_1.PENDING_REVIEWS]) {
        try {
            await db.recursiveDelete(expRef.collection(sub));
        }
        catch (e) {
            console.error(`[bookings] cleanup ${experienceId}/${sub} failed:`, e);
        }
    }
    return cancelledCount;
}
// ─────────────────────────────────────────────────────────── scheduled sweeps
const SWEEP_PAGE = 200;
const SWEEP_BUDGET_MS = 240000;
/**
 * Pages a "due" query until it returns nothing new or the time budget ends.
 * Each handled doc must leave the query (status or due field changes), so
 * re-querying from the top is correct; ids that failed are skipped.
 */
async function sweep(query, handle, label) {
    const started = Date.now();
    const seen = new Set();
    let handled = 0;
    while (Date.now() - started < SWEEP_BUDGET_MS) {
        const page = await query().limit(SWEEP_PAGE).get();
        const fresh = page.docs.filter((d) => !seen.has(d.id));
        if (fresh.length === 0)
            break;
        for (const d of fresh) {
            seen.add(d.id);
            try {
                await handle(d);
                handled++;
            }
            catch (e) {
                console.error(`[bookings] ${label} ${d.id} failed:`, e);
            }
        }
        if (page.docs.length < SWEEP_PAGE)
            break;
    }
    if (handled)
        console.log(`[bookings] ${label}: ${handled}`);
    return handled;
}
/** Confirmed bookings 24 h before the start: remind guest and host (once). */
async function sendDueReminders() {
    const db = fdb();
    return sweep(() => db.collection(model_1.BOOKINGS)
        .where('status', '==', 'confirmed')
        .where('reminderAt', '<=', ts(nowMs()))
        .orderBy('reminderAt'), async (d) => {
        const ref = d.ref;
        const out = await db.runTransaction(async (tx) => {
            var _a;
            const s = await tx.get(ref);
            const b = s.data();
            const at = msOf(b === null || b === void 0 ? void 0 : b.reminderAt);
            if (!b || b.status !== 'confirmed' || at === null || at > nowMs())
                return null;
            tx.update(ref, { reminderAt: del(), reminderSentAt: ts(nowMs()) });
            return ((_a = msOf(b.slotStart)) !== null && _a !== void 0 ? _a : 0) > nowMs() ? b : null;
        });
        if (!out)
            return;
        const data = notifData(d.id, out);
        await safeNotify({ recipientId: out.guestId, type: 'booking_reminder', title: 'Your experience is coming up', body: title(out), data });
        await safeNotify({ recipientId: out.hostId, type: 'booking_reminder_host', title: 'You are hosting soon', body: title(out), data });
    }, 'reminders');
}
/** Requests the host never answered (48 h or the start): expired, seats freed. */
async function expireDueRequests() {
    const db = fdb();
    const cfg = await loadConfig();
    return sweep(() => db.collection(model_1.BOOKINGS)
        .where('status', '==', 'requested')
        .where('requestExpiresAt', '<=', ts(nowMs()))
        .orderBy('requestExpiresAt'), async (d) => {
        const r = await transition(d.id, (b, now) => {
            const at = msOf(b.requestExpiresAt);
            if (b.status !== 'requested' || at === null || at > now)
                return { noop: true };
            return { to: 'expired', patch: { requestExpiresAt: del(), expiredAt: ts(now) } };
        }, cfg);
        if (r.noop)
            return;
        await safeNotify({
            recipientId: r.after.guestId, type: 'booking_expired', title: 'Your booking request expired',
            body: `${title(r.after)} — the host did not answer in time.`, data: notifData(d.id, r.after),
        });
    }, 'expire-requests');
}
/** Confirmed bookings past end + dispute window: completed; reviews unlocked. */
async function completeDueBookings() {
    const db = fdb();
    const cfg = await loadConfig();
    return sweep(() => db.collection(model_1.BOOKINGS)
        .where('status', '==', 'confirmed')
        .where('completeAt', '<=', ts(nowMs()))
        .orderBy('completeAt'), async (d) => {
        const r = await transition(d.id, (b, now) => {
            const at = msOf(b.completeAt);
            if (b.status !== 'confirmed' || at === null || at > now)
                return { noop: true };
            return {
                to: 'completed',
                patch: { completeAt: del(), reminderAt: del(), completedAt: ts(now) },
                extra: (tx, after) => eligibilityWrite(tx, after, d.id, now, cfg),
            };
        }, cfg);
        if (r.noop)
            return;
        const data = notifData(d.id, r.after);
        await safeNotify({ recipientId: r.after.guestId, type: 'booking_review_prompt', title: 'How was your experience?', body: `Review ${title(r.after)}`, data });
        await safeNotify({ recipientId: r.after.hostId, type: 'booking_review_guest_prompt', title: 'Review your guest', body: title(r.after), data });
    }, 'complete');
}
//# sourceMappingURL=service.js.map