"use strict";
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
exports.checkInEventAttendee = exports.getEventTicketCode = exports.EVENT_CHECKIN_LATE_HOURS = exports.EVENT_CHECKIN_EARLY_HOURS = void 0;
exports.eventTicketCode = eventTicketCode;
exports.verifyEventTicketCode = verifyEventTicketCode;
exports.eventTicketPayload = eventTicketPayload;
exports.parseEventTicket = parseEventTicket;
exports.inEventCheckInWindow = inEventCheckInWindow;
exports.canScanEvent = canScanEvent;
/**
 * Event QR check-in, server-verified.
 *
 * Before 4.4.0 the ticket QR was plain JSON (`greengo:{"e":eventId,"u":uid}`)
 * and the organizer's app wrote `checkedIn` straight to Firestore — anyone
 * could forge a ticket, and an attendee could even check THEMSELVES in.
 *
 * Now:
 *   - getEventTicketCode   (attendee, status 'going') returns a SIGNED ticket
 *                          `greengo:ev:{eventId}:{uid}:{code}`, code = 8 chars
 *                          of HMAC-SHA256(secret, "event:{eventId}:{uid}").
 *                          Deterministic, so the app can cache it and show it
 *                          offline at the venue.
 *   - checkInEventAttendee (organizer, co-organizer or delegated scanner)
 *                          verifies the ticket, the event, the time window and
 *                          the RSVP, then writes checkedIn/checkedInAt/
 *                          checkedInBy/checkInMethod and records a
 *                          "met in person" encounter (meetings.ts).
 *   - firestore.rules no longer let ANY client write the check-in fields.
 *
 * Legacy unsigned tickets (older app versions) are still accepted while
 * `app_config/event_checkin.allowLegacyTickets` is not false — checked in with
 * checkInMethod 'legacy' and a meeting recorded as NOT verified. Set the flag
 * to false once old versions are gone.
 */
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
require("../shared/firebaseAdmin");
const meetings_1 = require("./meetings");
const CALL_OPTS = { memory: '512MiB', timeoutSeconds: 60 };
const HOUR_MS = 60 * 60 * 1000;
/** Doors open this long before the start … */
exports.EVENT_CHECKIN_EARLY_HOURS = 3;
/** … and close this long after the end (or after the start when no end). */
exports.EVENT_CHECKIN_LATE_HOURS = 12;
const DEFAULT_DURATION_HOURS = 6;
const B32 = 'ABCDEFGHJKMNPQRSTVWXYZ0123456789'; // no I, L, O, U
// ─────────────────────────────────────────────────────────── pure helpers
function eventTicketCode(secret, eventId, uid) {
    const mac = crypto.createHmac('sha256', secret).update(`event:${eventId}:${uid}`).digest();
    let out = '';
    for (let i = 0; i < 8; i++)
        out += B32[mac[i] % 32];
    return out;
}
function verifyEventTicketCode(secret, eventId, uid, given) {
    if (typeof given !== 'string')
        return false;
    const g = given.trim().toUpperCase();
    const want = eventTicketCode(secret, eventId, uid);
    if (g.length !== want.length)
        return false;
    return crypto.timingSafeEqual(Buffer.from(g), Buffer.from(want));
}
function eventTicketPayload(eventId, uid, code) {
    return `greengo:ev:${eventId}:${uid}:${code}`;
}
const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;
/** Parses a scanned event ticket (signed or legacy JSON); null if neither. */
function parseEventTicket(raw) {
    if (typeof raw !== 'string')
        return null;
    const s = raw.trim();
    const m = /^greengo:ev:([^:]+):([^:]+):([A-Za-z0-9]{8})$/.exec(s);
    if (m) {
        if (!ID_RE.test(m[1]) || !ID_RE.test(m[2]))
            return null;
        return { kind: 'signed', eventId: m[1], userId: m[2], code: m[3].toUpperCase() };
    }
    if (s.startsWith('greengo:{')) {
        try {
            const j = JSON.parse(s.substring('greengo:'.length));
            const e = j === null || j === void 0 ? void 0 : j.e;
            const u = j === null || j === void 0 ? void 0 : j.u;
            if (typeof e === 'string' && typeof u === 'string' && ID_RE.test(e) && ID_RE.test(u)) {
                return { kind: 'legacy', eventId: e, userId: u };
            }
        }
        catch (_a) {
            return null;
        }
    }
    return null;
}
/** Whether [now] is inside the event's check-in window. */
function inEventCheckInWindow(now, startMs, endMs) {
    if (startMs === null)
        return true; // no schedule on file: do not lock the door
    const end = endMs !== null && endMs >= startMs ? endMs : startMs + DEFAULT_DURATION_HOURS * HOUR_MS;
    return now >= startMs - exports.EVENT_CHECKIN_EARLY_HOURS * HOUR_MS
        && now <= end + exports.EVENT_CHECKIN_LATE_HOURS * HOUR_MS;
}
function canScanEvent(uid, ev) {
    if (!uid)
        return false;
    if (ev.organizerId === uid)
        return true;
    const co = ev.coOrganizerIds;
    if (Array.isArray(co) && co.includes(uid))
        return true;
    const sc = ev.allowedScannerIds;
    return Array.isArray(sc) && sc.includes(uid);
}
// ─────────────────────────────────────────────────────────── server side
function fail(code, reason, extra = {}) {
    throw new https_1.HttpsError(code, reason, Object.assign({ code: reason }, extra));
}
function msOf(v) {
    if (v instanceof admin.firestore.Timestamp)
        return v.toMillis();
    if (v instanceof Date)
        return v.getTime();
    if (typeof v === 'string') {
        const t = Date.parse(v);
        return Number.isNaN(t) ? null : t;
    }
    if (typeof v === 'number')
        return v;
    return null;
}
let cachedSecret = null;
/** HMAC key, created on first use in server_secrets/event_checkin (default-deny). */
async function ticketSecret() {
    if (cachedSecret)
        return cachedSecret;
    const db = admin.firestore();
    const ref = db.collection('server_secrets').doc('event_checkin');
    cachedSecret = await db.runTransaction(async (tx) => {
        var _a;
        const snap = await tx.get(ref);
        const existing = (_a = snap.data()) === null || _a === void 0 ? void 0 : _a.key;
        if (typeof existing === 'string' && existing.length >= 32)
            return existing;
        const fresh = crypto.randomBytes(32).toString('hex');
        tx.set(ref, { key: fresh, createdAt: admin.firestore.Timestamp.now() });
        return fresh;
    });
    return cachedSecret;
}
async function allowLegacyTickets() {
    var _a;
    try {
        const snap = await admin.firestore().collection('app_config').doc('event_checkin').get();
        return ((_a = snap.data()) === null || _a === void 0 ? void 0 : _a.allowLegacyTickets) !== false;
    }
    catch (_b) {
        return true;
    }
}
function withAuth(impl) {
    return (0, https_1.onCall)(CALL_OPTS, async (req) => {
        var _a, _b;
        const uid = (_a = req.auth) === null || _a === void 0 ? void 0 : _a.uid;
        if (!uid)
            fail('unauthenticated', 'unauthenticated');
        try {
            return await impl(uid, (_b = req.data) !== null && _b !== void 0 ? _b : {});
        }
        catch (e) {
            if (e instanceof https_1.HttpsError)
                throw e;
            console.error('[event_checkin] failed:', e);
            throw new https_1.HttpsError('internal', 'checkin_internal_error', { code: 'internal' });
        }
    });
}
/** Attendee: their signed ticket for an event they are going to. */
exports.getEventTicketCode = withAuth(async (uid, data) => {
    var _a;
    const eventId = data === null || data === void 0 ? void 0 : data.eventId;
    if (typeof eventId !== 'string' || !ID_RE.test(eventId))
        fail('invalid-argument', 'invalid_event_id');
    const att = await admin.firestore().collection('events').doc(eventId).collection('attendees').doc(uid).get();
    if (!att.exists || ((_a = att.data()) === null || _a === void 0 ? void 0 : _a.status) !== 'going')
        fail('failed-precondition', 'not_going');
    const code = eventTicketCode(await ticketSecret(), eventId, uid);
    return { eventId, userId: uid, code, qrPayload: eventTicketPayload(eventId, uid, code) };
});
/**
 * Door: verify a scanned ticket and check the attendee in.
 * data: { eventId, payload } — eventId is the event the scanner has open (or,
 * from the QR hub, omitted: the ticket's own event is used and the caller's
 * rights on THAT event are checked).
 */
exports.checkInEventAttendee = withAuth(async (uid, data) => {
    var _a, _b, _c, _d, _e;
    const ticket = parseEventTicket(data === null || data === void 0 ? void 0 : data.payload);
    if (!ticket)
        fail('invalid-argument', 'invalid_code');
    const openEventId = typeof (data === null || data === void 0 ? void 0 : data.eventId) === 'string' ? data.eventId : null;
    if (openEventId && openEventId !== ticket.eventId)
        fail('failed-precondition', 'wrong_event');
    const db = admin.firestore();
    const evRef = db.collection('events').doc(ticket.eventId);
    const evSnap = await evRef.get();
    if (!evSnap.exists)
        fail('not-found', 'event_not_found');
    const ev = evSnap.data();
    if (!canScanEvent(uid, ev))
        fail('permission-denied', 'not_scanner');
    let verified;
    if (ticket.kind === 'signed') {
        if (!verifyEventTicketCode(await ticketSecret(), ticket.eventId, ticket.userId, ticket.code)) {
            fail('permission-denied', 'invalid_code');
        }
        verified = true;
    }
    else {
        if (!(await allowLegacyTickets()))
            fail('permission-denied', 'legacy_ticket_rejected');
        verified = false;
    }
    if (!inEventCheckInWindow(Date.now(), msOf(ev.startDate), msOf(ev.endDate))) {
        fail('failed-precondition', 'outside_checkin_window');
    }
    const attRef = evRef.collection('attendees').doc(ticket.userId);
    const res = await db.runTransaction(async (tx) => {
        var _a;
        const att = await tx.get(attRef);
        if (!att.exists)
            fail('not-found', 'not_registered');
        const a = att.data();
        if (a.status !== 'going')
            fail('failed-precondition', 'not_going', { status: (_a = a.status) !== null && _a !== void 0 ? _a : null });
        if (a.checkedIn === true)
            return { already: true, a };
        tx.update(attRef, {
            checkedIn: true,
            checkedInAt: admin.firestore.FieldValue.serverTimestamp(),
            checkedInBy: uid,
            checkInMethod: verified ? 'signed' : 'legacy',
        });
        return { already: false, a };
    });
    if (!res.already) {
        const title = String((_a = ev.title) !== null && _a !== void 0 ? _a : '');
        const ctx = { type: 'event', contextId: ticket.eventId, title, verified, byUid: uid };
        await (0, meetings_1.recordMeeting)(String((_b = ev.organizerId) !== null && _b !== void 0 ? _b : ''), ticket.userId, ctx);
        const co = Array.isArray(ev.coOrganizerIds) ? ev.coOrganizerIds : [];
        if (uid !== ev.organizerId && co.includes(uid))
            await (0, meetings_1.recordMeeting)(uid, ticket.userId, ctx);
    }
    return {
        eventId: ticket.eventId,
        userId: ticket.userId,
        userName: (_c = res.a.userName) !== null && _c !== void 0 ? _c : '',
        userPhotoUrl: (_d = res.a.userPhotoUrl) !== null && _d !== void 0 ? _d : null,
        guestCount: Number((_e = res.a.guestCount) !== null && _e !== void 0 ? _e : 0),
        alreadyCheckedIn: res.already,
        verified,
    };
});
//# sourceMappingURL=eventCheckin.js.map