"use strict";
/**
 * Social notifications (NEW, isolated module).
 *
 * Emits an in-app notification (+ FCM push) with the ACTOR's avatar + name to
 * the owner/organizer when someone acts on their thing:
 *   - joins your community        (communities/{id}/members/{uid} onCreate)
 *   - joins your event            (events/{id}/attendees/{uid} onCreate)
 *   - follows your business       (business_followers/{bizId}/followers/{uid})
 *   - rates your business         (business_ratings/{bizId}/ratings/{uid})
 *   - likes your event            (events/{id}/likes/{uid} onCreate)
 *
 * Titles are stored WITHOUT the actor's name (the Flutter tile renders
 * `actorName` as a bold, tappable span). `imageUrl`/`actorId`/`actorName` drive
 * the tile's left avatar + name-tap → actor profile.
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
exports.onEventLiked = exports.onBusinessRated = exports.onBusinessFollowed = exports.onEventAttendeeJoined = exports.onCommunityMemberJoined = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const brand_1 = require("./brand");
const prefs_1 = require("./prefs");
const monitoring_1 = require("../shared/monitoring");
const pushRuntime_1 = require("../shared/pushRuntime");
require("../shared/firebaseAdmin");
const db = admin.firestore();
/** Resolve an actor's display name + avatar from their profile. */
async function resolveActor(actorId) {
    try {
        const snap = await db.collection('profiles').doc(actorId).get();
        const p = snap.data() || {};
        const name = p.displayName ||
            p.nickname ||
            p.name ||
            'Someone';
        const photo = p.profilePhotoUrl ||
            (Array.isArray(p.photos) ? p.photos[0] : undefined) ||
            (Array.isArray(p.photoUrls) ? p.photoUrls[0] : undefined);
        return { id: actorId, name, photo };
    }
    catch (_a) {
        return { id: actorId, name: 'Someone' };
    }
}
/**
 * Claim a one-time dedup key so a re-fired trigger doesn't double-notify.
 * Returns true if THIS call won the claim (first time), false if already claimed.
 */
async function claimOnce(dedupKey) {
    const ref = db.collection('notif_dedup').doc(dedupKey);
    try {
        await ref.create({ at: admin.firestore.FieldValue.serverTimestamp() });
        return true;
    }
    catch (_a) {
        return false; // already exists → duplicate delivery
    }
}
/**
 * Emit one notification to [recipientId]: an in-app `notifications` doc carrying
 * the actor identity, plus a best-effort FCM push if the recipient has a token.
 * [dedupKey] guards against duplicate deliveries on trigger retries.
 */
async function emit(recipientId, type, title, body, rawData, actor, dedupKey) {
    var _a;
    if (!recipientId || recipientId === actor.id)
        return;
    if (!(await claimOnce(dedupKey)))
        return;
    // Always carry the actor identity in the push DATA payload too, so the client
    // (background/terminated push handler) can render + link the actor's name.
    const data = Object.assign(Object.assign({}, rawData), { actorId: actor.id, actorName: actor.name });
    // In-app doc (Flutter NotificationModel shape + actor fields).
    // pushSent: true — this function sends its own push below, so the
    // onNotificationCreatedPush parity trigger must skip it (no double-push).
    await db.collection('notifications').add(Object.assign({ userId: recipientId, type,
        title, message: body, body,
        data, isRead: false, createdAt: admin.firestore.FieldValue.serverTimestamp(), actorId: actor.id, actorName: actor.name, pushSent: true }, (actor.photo ? { imageUrl: actor.photo } : {})));
    // Respect the recipient's per-category preference (feed doc already written).
    if (!(await (0, prefs_1.shouldNotify)(recipientId, (0, prefs_1.categoryForType)(type))))
        return;
    // Best-effort push.
    try {
        const userSnap = await db.collection('users').doc(recipientId).get();
        const token = (_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
        if (token) {
            await admin.messaging().send({
                token,
                notification: (0, brand_1.brandPush)(`${actor.name} ${title}`, body, actor.photo),
                data,
                android: {
                    priority: 'high',
                    notification: { sound: 'default', channelId: 'greengo_notifications' },
                },
                apns: { payload: { aps: { sound: 'default', badge: 1 } } },
            });
        }
    }
    catch (_b) {
        // Never fail the trigger on a push error.
    }
}
// ── e) Someone joined your community ────────────────────────────────────────
exports.onCommunityMemberJoined = (0, firestore_1.onDocumentCreated)({
    document: 'communities/{communityId}/members/{userId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onCommunityMemberJoined', async (event) => {
    const communityId = event.params.communityId;
    const userId = event.params.userId;
    const cSnap = await db.collection('communities').doc(communityId).get();
    const c = cSnap.data();
    if (!c)
        return;
    const ownerId = c.createdByUserId || '';
    if (!ownerId || ownerId === userId)
        return; // creator auto-joins
    const actor = await resolveActor(userId);
    await emit(ownerId, 'community_join', `joined your community ${c.name || ''}`.trim(), c.name || 'Your community', { type: 'community_join', communityId, action: 'open_community', actorId: userId }, actor, `community_join_${communityId}_${userId}`);
}));
// ── f) Someone joined your event ────────────────────────────────────────────
exports.onEventAttendeeJoined = (0, firestore_1.onDocumentCreated)({
    document: 'events/{eventId}/attendees/{userId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onEventAttendeeJoined', async (event) => {
    var _a, _b;
    const eventId = event.params.eventId;
    const userId = event.params.userId;
    const status = ((_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data()) === null || _b === void 0 ? void 0 : _b.status) || '';
    if (status && status !== 'going')
        return; // only real RSVPs
    const eSnap = await db.collection('events').doc(eventId).get();
    const e = eSnap.data();
    if (!e)
        return;
    const organizerId = e.organizerId || '';
    if (!organizerId || organizerId === userId)
        return;
    const actor = await resolveActor(userId);
    await emit(organizerId, 'event_join', `joined your event ${e.title || ''}`.trim(), e.title || 'Your event', { type: 'event_join', eventId, action: 'open_event', actorId: userId }, actor, `event_join_${eventId}_${userId}`);
}));
// ── w) Someone follows your business ────────────────────────────────────────
exports.onBusinessFollowed = (0, firestore_1.onDocumentCreated)({
    document: 'business_followers/{businessId}/followers/{userId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onBusinessFollowed', async (event) => {
    const businessId = event.params.businessId;
    const userId = event.params.userId;
    if (businessId === userId)
        return;
    const actor = await resolveActor(userId);
    await emit(businessId, 'business_follow', 'started following your business', 'You have a new follower', { type: 'business_follow', businessId, action: 'open_profile', profileId: userId, actorId: userId }, actor, `business_follow_${businessId}_${userId}`);
}));
// ── u) Someone rated your business ──────────────────────────────────────────
exports.onBusinessRated = (0, firestore_1.onDocumentCreated)({
    document: 'business_ratings/{businessId}/ratings/{userId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onBusinessRated', async (event) => {
    var _a, _b;
    const businessId = event.params.businessId;
    const userId = event.params.userId;
    if (businessId === userId)
        return;
    // The client writes the rating under `stars` (not `rating`).
    const stars = ((_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data()) === null || _b === void 0 ? void 0 : _b.stars) || 0;
    const actor = await resolveActor(userId);
    await emit(businessId, 'business_rating', stars > 0 ? `rated your business ${stars}★` : 'rated your business', 'You have a new rating', { type: 'business_rating', businessId, action: 'open_profile', profileId: businessId, actorId: userId }, actor, `business_rating_${businessId}_${userId}`);
}));
// ── n) Someone liked your event ─────────────────────────────────────────────
exports.onEventLiked = (0, firestore_1.onDocumentCreated)({
    document: 'events/{eventId}/likes/{userId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onEventLiked', async (event) => {
    const eventId = event.params.eventId;
    const userId = event.params.userId;
    const eSnap = await db.collection('events').doc(eventId).get();
    const e = eSnap.data();
    if (!e)
        return;
    const organizerId = e.organizerId || '';
    if (!organizerId || organizerId === userId)
        return;
    const actor = await resolveActor(userId);
    await emit(organizerId, 'event_like', `liked your event ${e.title || ''}`.trim(), e.title || 'Your event', { type: 'event_like', eventId, action: 'open_event', actorId: userId }, actor, `event_like_${eventId}_${userId}`);
}));
//# sourceMappingURL=socialNotifications.js.map