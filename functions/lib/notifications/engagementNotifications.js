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
exports.checkBoostExpiries = exports.onEventBoostStarted = exports.onProfileBoostStarted = exports.onTicketScanned = exports.onProfileViewed = void 0;
/**
 * Engagement notifications (NEW): profile views (throttled), ticket QR scans,
 * and boost start/end. See notifyHelpers for the shared emit.
 */
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
const notifyHelpers_1 = require("./notifyHelpers");
require("../shared/firebaseAdmin");
const db = admin.firestore();
// ── m) Someone viewed your profile — throttled to 1 per viewer per day ───────
exports.onProfileViewed = (0, firestore_1.onDocumentCreated)('user_interactions/{viewerId}/events/{eventId}', (0, monitoring_1.monitored)('onProfileViewed', async (event) => {
    var _a;
    const d = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!d || d.type !== 'profile_view')
        return;
    const viewerId = event.params.viewerId;
    const targetId = d.targetId || '';
    if (!targetId || targetId === viewerId)
        return;
    // Throttle: at most one "viewed your profile" per viewer→target per day.
    const day = new Date().toISOString().slice(0, 10); // yyyy-mm-dd (UTC)
    const dedupRef = db
        .collection('notif_dedup')
        .doc(`pv_${targetId}_${viewerId}_${day}`);
    try {
        await dedupRef.create({ at: admin.firestore.FieldValue.serverTimestamp() });
    }
    catch (_b) {
        return; // already notified today
    }
    const actor = await (0, notifyHelpers_1.resolveActor)(viewerId);
    await (0, notifyHelpers_1.emitNotification)({
        recipientId: targetId,
        type: 'profile_view',
        title: 'viewed your profile',
        body: 'Tap to see who stopped by',
        data: { type: 'profile_view', action: 'open_profile', profileId: viewerId, actorId: viewerId },
        actor,
    });
}));
// ── j) Your event ticket QR is being scanned ─────────────────────────────────
exports.onTicketScanned = (0, firestore_1.onDocumentUpdated)('events/{eventId}/attendees/{userId}', (0, monitoring_1.monitored)('onTicketScanned', async (event) => {
    var _a, _b, _c;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    // Only on the check-in transition (false → true).
    if (before.checkedIn === true || after.checkedIn !== true)
        return;
    const eventId = event.params.eventId;
    const attendeeId = event.params.userId;
    const eSnap = await db.collection('events').doc(eventId).get();
    const title = ((_c = eSnap.data()) === null || _c === void 0 ? void 0 : _c.title) || 'your event';
    await (0, notifyHelpers_1.emitNotification)({
        recipientId: attendeeId,
        type: 'qr_scanned',
        title: `Your ticket for ${title} was scanned`,
        body: "You're checked in — enjoy!",
        data: { type: 'qr_scanned', eventId, action: 'open_event' },
    });
}));
// ── o) / q) Boost STARTED — profile / event ──────────────────────────────────
function isFutureTs(v) {
    return v instanceof admin.firestore.Timestamp && v.toDate().getTime() > Date.now();
}
exports.onProfileBoostStarted = (0, firestore_1.onDocumentUpdated)('profiles/{uid}', (0, monitoring_1.monitored)('onProfileBoostStarted', async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const b = before.businessPromotedUntil;
    const a = after.businessPromotedUntil;
    // Started when it became a future time and actually changed.
    if (!isFutureTs(a))
        return;
    if (b instanceof admin.firestore.Timestamp && a instanceof admin.firestore.Timestamp &&
        b.toMillis() === a.toMillis())
        return;
    // Reset the "ended" flag for the new cycle.
    await event.data.after.ref.set({ boostEndNotified: false }, { merge: true });
    await (0, notifyHelpers_1.emitNotification)({
        recipientId: event.params.uid,
        type: 'boost_started',
        title: 'Your profile boost is now live',
        body: 'Your profile is being promoted to more people',
        data: { type: 'boost_started', subject: 'profile', action: 'open_profile' },
    });
}));
exports.onEventBoostStarted = (0, firestore_1.onDocumentUpdated)('events/{eventId}', (0, monitoring_1.monitored)('onEventBoostStarted', async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const wasFeatured = before.isFeatured === true && isFutureTs(before.featuredUntil);
    const nowFeatured = after.isFeatured === true && isFutureTs(after.featuredUntil);
    if (wasFeatured || !nowFeatured)
        return;
    const organizerId = after.organizerId || '';
    if (!organizerId)
        return;
    await event.data.after.ref.set({ boostEndNotified: false }, { merge: true });
    await (0, notifyHelpers_1.emitNotification)({
        recipientId: organizerId,
        type: 'boost_started',
        title: `Your event ${after.title || ''} boost is now live`.trim(),
        body: 'Your event is being promoted in Explore',
        data: { type: 'boost_started', subject: 'event', eventId: event.params.eventId, action: 'open_event' },
    });
}));
// ── p) / r) Boost ENDED — hourly sweep of expired boosts ─────────────────────
exports.checkBoostExpiries = (0, scheduler_1.onSchedule)('every 60 minutes', async () => {
    const now = admin.firestore.Timestamp.now();
    const since = admin.firestore.Timestamp.fromMillis(now.toMillis() - 3 * 60 * 60 * 1000);
    // Profiles whose boost expired in the last 3h and weren't yet notified.
    const profiles = await db
        .collection('profiles')
        .where('businessPromotedUntil', '>', since)
        .where('businessPromotedUntil', '<=', now)
        .limit(200)
        .get();
    for (const doc of profiles.docs) {
        if (doc.data().boostEndNotified === true)
            continue;
        await doc.ref.set({ boostEndNotified: true }, { merge: true });
        await (0, notifyHelpers_1.emitNotification)({
            recipientId: doc.id,
            type: 'boost_ended',
            title: 'Your profile boost has ended',
            body: 'Boost again to keep reaching more people',
            data: { type: 'boost_ended', subject: 'profile', action: 'open_profile' },
        });
    }
    // Events whose feature window expired in the last 3h.
    const events = await db
        .collection('events')
        .where('featuredUntil', '>', since)
        .where('featuredUntil', '<=', now)
        .limit(200)
        .get();
    for (const doc of events.docs) {
        const e = doc.data();
        if (e.boostEndNotified === true)
            continue;
        const organizerId = e.organizerId || '';
        if (!organizerId)
            continue;
        await doc.ref.set({ boostEndNotified: true }, { merge: true });
        await (0, notifyHelpers_1.emitNotification)({
            recipientId: organizerId,
            type: 'boost_ended',
            title: `Your event ${e.title || ''} boost has ended`.trim(),
            body: 'Boost again to keep it featured',
            data: { type: 'boost_ended', subject: 'event', eventId: doc.id, action: 'open_event' },
        });
    }
});
//# sourceMappingURL=engagementNotifications.js.map