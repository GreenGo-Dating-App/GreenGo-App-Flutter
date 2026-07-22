"use strict";
/**
 * Community event → members push fan-out (NEW, isolated module).
 *
 * When an event linked to a community (`communityId` set) becomes `published`,
 * push an FCM notification to every member of that community and write a
 * matching in-app `notifications` doc.
 *
 * Fires on:
 *   - events/{eventId} onCreate  — created already `published` with communityId.
 *   - events/{eventId} onUpdate  — transitioning INTO `published` with communityId.
 *
 * Independent of the business-followers fan-out (business_new_event.ts): a
 * community event with a business organizer notifies BOTH audiences via separate
 * idempotency flags (`pushedToCommunity` here vs `pushedToFollowers` there).
 *
 * Scale: members paged (MEMBER_PAGE); multicast in 500-chunks; in-app docs in
 * ≤450-op batches.
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
exports.onCommunityEventChanged = exports.onCommunityEventPublished = exports.onCommunityEventCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const brand_1 = require("../notifications/brand");
const prefs_1 = require("../notifications/prefs");
const monitoring_1 = require("../shared/monitoring");
const pushRuntime_1 = require("../shared/pushRuntime");
require("../shared/firebaseAdmin");
const db = admin.firestore();
const FCM_CHUNK = 500;
const MEMBER_PAGE = 500;
const BATCH_LIMIT = 450;
function preview(title) {
    return title.length > 120 ? `${title.substring(0, 117)}...` : title;
}
/**
 * Page over a community's members and deliver `notif` via FCM multicast + an
 * in-app `notifications` doc each. Shared by the publish and change/cancel
 * fan-outs so both stay identical in scale behaviour.
 */
async function notifyCommunityMembers(communityId, notif) {
    var _a;
    const { title, body, eventImage, dataPayload, collapseKey } = notif;
    const membersCol = db
        .collection('communities')
        .doc(communityId)
        .collection('members');
    let lastDoc;
    let total = 0;
    // eslint-disable-next-line no-constant-condition
    while (true) {
        let q = membersCol
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(MEMBER_PAGE);
        if (lastDoc)
            q = q.startAfter(lastDoc);
        const page = await q.get();
        if (page.empty)
            break;
        lastDoc = page.docs[page.docs.length - 1];
        const rawIds = page.docs
            .filter((d) => { var _a; return ((_a = d.data()) === null || _a === void 0 ? void 0 : _a.isBanned) !== true; })
            .map((d) => d.id);
        const allowedSet = await (0, prefs_1.filterUidsByPref)(rawIds, 'events');
        const recipientIds = rawIds.filter((u) => allowedSet.has(u));
        total += recipientIds.length;
        const userDocs = await Promise.all(recipientIds.map((uid) => db.collection('users').doc(uid).get()));
        const tokens = [];
        for (const ud of userDocs) {
            const t = (_a = ud.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
            if (t)
                tokens.push(t);
        }
        for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
            const chunk = tokens.slice(i, i + FCM_CHUNK);
            try {
                await admin.messaging().sendEachForMulticast({
                    tokens: chunk,
                    notification: (0, brand_1.brandPush)(title, body, eventImage),
                    data: dataPayload,
                    android: {
                        priority: 'high',
                        collapseKey,
                        notification: Object.assign({ sound: 'default', channelId: 'greengo_notifications', priority: 'high', tag: collapseKey }, (eventImage ? { imageUrl: eventImage } : {})),
                    },
                    apns: {
                        headers: { 'apns-collapse-id': collapseKey },
                        payload: { aps: { sound: 'default', badge: 1 } },
                    },
                });
            }
            catch (e) {
                console.error('Community members multicast failed', collapseKey, e);
            }
        }
        let batch = db.batch();
        let ops = 0;
        const commits = [];
        for (const uid of recipientIds) {
            const ref = db.collection('notifications').doc();
            batch.set(ref, {
                userId: uid,
                type: notif.type,
                title,
                message: body,
                body,
                data: dataPayload,
                imageUrl: eventImage !== null && eventImage !== void 0 ? eventImage : null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                // Members were already multicast above — skip the parity trigger.
                pushSent: true,
            });
            ops++;
            if (ops >= BATCH_LIMIT) {
                commits.push(batch.commit());
                batch = db.batch();
                ops = 0;
            }
        }
        if (ops > 0)
            commits.push(batch.commit());
        await Promise.all(commits);
        if (page.size < MEMBER_PAGE)
            break;
    }
    return total;
}
async function fanOutCommunityEvent(eventId, eventData, eventRef) {
    var _a;
    if (eventData.status !== 'published')
        return;
    const communityId = eventData.communityId || '';
    if (!communityId)
        return;
    if (eventData.pushedToCommunity === true)
        return;
    // Claim idempotency flag transactionally.
    const claimed = await db.runTransaction(async (txn) => {
        var _a;
        const fresh = await txn.get(eventRef);
        if (!fresh.exists)
            return false;
        if (((_a = fresh.data()) === null || _a === void 0 ? void 0 : _a.pushedToCommunity) === true)
            return false;
        txn.update(eventRef, {
            pushedToCommunity: true,
            pushedToCommunityAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return true;
    });
    if (!claimed)
        return;
    const communitySnap = await db
        .collection('communities')
        .doc(communityId)
        .get();
    const communityName = ((_a = communitySnap.data()) === null || _a === void 0 ? void 0 : _a.name) || 'Your community';
    const eventTitle = eventData.title || 'New event';
    const eventImage = eventData.imageUrl || undefined;
    const total = await notifyCommunityMembers(communityId, {
        type: 'community_event',
        title: `New event in ${communityName}`,
        body: preview(eventTitle),
        eventImage,
        dataPayload: {
            type: 'community_event',
            eventId,
            communityId,
            action: 'open_event',
        },
        collapseKey: `community_event_${eventId}`,
    });
    console.log(`Community event ${eventId} fanned out to ${total} member(s) of ${communityId}`);
}
exports.onCommunityEventCreated = (0, firestore_1.onDocumentCreated)({
    document: 'events/{eventId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onCommunityEventCreated', async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    await fanOutCommunityEvent(event.params.eventId, snap.data(), snap.ref);
}));
exports.onCommunityEventPublished = (0, firestore_1.onDocumentUpdated)({
    document: 'events/{eventId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onCommunityEventPublished', async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    if (before.status === 'published')
        return;
    if (after.status !== 'published')
        return;
    await fanOutCommunityEvent(event.params.eventId, after, event.data.after.ref);
}));
function ms(v) {
    const t = v;
    return typeof (t === null || t === void 0 ? void 0 : t.toMillis) === 'function' ? t.toMillis() : 0;
}
/**
 * Community-event CHANGED / CANCELLED fan-out (#16).
 *
 * When an already-published event that is linked to a community has its start
 * time or venue changed, or is cancelled, notify every member. Does NOT write
 * back to the event doc (so it never self-triggers); relies on the fact that a
 * real reschedule/cancel is a single distinct doc version.
 */
exports.onCommunityEventChanged = (0, firestore_1.onDocumentUpdated)({
    document: 'events/{eventId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onCommunityEventChanged', async (event) => {
    var _a, _b, _c;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const communityId = after.communityId || '';
    if (!communityId)
        return;
    // Only events that were already visible to members.
    if (before.status !== 'published')
        return;
    const eventId = event.params.eventId;
    const communitySnap = await db
        .collection('communities')
        .doc(communityId)
        .get();
    const communityName = ((_c = communitySnap.data()) === null || _c === void 0 ? void 0 : _c.name) || 'Your community';
    const eventTitle = after.title || 'Event';
    const eventImage = after.imageUrl || undefined;
    // Cancellation takes precedence.
    const cancelled = after.status === 'cancelled' || after.isCancelled === true;
    if (cancelled && before.status === 'published') {
        const total = await notifyCommunityMembers(communityId, {
            type: 'community_event_changed',
            title: `Event cancelled in ${communityName}`,
            body: preview(`"${eventTitle}" has been cancelled`),
            eventImage,
            dataPayload: {
                type: 'community_event_changed',
                eventId,
                communityId,
                action: 'open_event',
                change: 'cancelled',
            },
            collapseKey: `community_event_changed_${eventId}`,
        });
        console.log(`Community event ${eventId} cancellation → ${total} member(s)`);
        return;
    }
    // Still published → detect a reschedule / venue change.
    if (after.status !== 'published')
        return;
    const timeChanged = ms(before.startDate) !== ms(after.startDate);
    const venueChanged = (before.locationName || '') !== (after.locationName || '') ||
        (before.address || '') !== (after.address || '') ||
        (before.venue || '') !== (after.venue || '');
    if (!timeChanged && !venueChanged)
        return;
    const what = timeChanged ? 'New time' : 'New location';
    const total = await notifyCommunityMembers(communityId, {
        type: 'community_event_changed',
        title: `Event updated in ${communityName}`,
        body: preview(`${what} for "${eventTitle}"`),
        eventImage,
        dataPayload: {
            type: 'community_event_changed',
            eventId,
            communityId,
            action: 'open_event',
            change: timeChanged ? 'time' : 'venue',
        },
        collapseKey: `community_event_changed_${eventId}`,
    });
    console.log(`Community event ${eventId} change → ${total} member(s)`);
}));
//# sourceMappingURL=eventFanout.js.map