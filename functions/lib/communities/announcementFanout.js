"use strict";
/**
 * Community announcement → members push fan-out (NEW, isolated module).
 *
 * When an owner/admin posts an ANNOUNCEMENT message in a community, push an FCM
 * notification to every member and write a matching in-app `notifications` doc
 * (so it also shows on the notification page).
 *
 * Fires on: communities/{communityId}/messages/{messageId} onCreate.
 * Gate: message `type === 'announcement'`.
 *
 * Idempotency: claims a `fannedOut` flag on the message doc transactionally
 * before any send, so Cloud Functions at-least-once retries can't double-send.
 *
 * Scale: members are PAGED from communities/{id}/members (MEMBER_PAGE at a time);
 * per page tokens are multicast in chunks of 500 and in-app docs written in
 * ≤450-op batches. No unbounded accumulation.
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
exports.onCommunityAnnouncementCreated = void 0;
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
function preview(text) {
    return text.length > 120 ? `${text.substring(0, 117)}...` : text;
}
exports.onCommunityAnnouncementCreated = (0, firestore_1.onDocumentCreated)({
    document: 'communities/{communityId}/messages/{messageId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)('onCommunityAnnouncementCreated', async (event) => {
    var _a, _b;
    const snap = event.data;
    if (!snap)
        return;
    const msg = snap.data();
    if (!msg || msg.type !== 'announcement')
        return;
    const communityId = event.params.communityId;
    const senderId = msg.senderId || '';
    // Claim idempotency flag on the message doc before any fan-out.
    const claimed = await db.runTransaction(async (txn) => {
        var _a;
        const fresh = await txn.get(snap.ref);
        if (!fresh.exists)
            return false;
        if (((_a = fresh.data()) === null || _a === void 0 ? void 0 : _a.fannedOut) === true)
            return false;
        txn.update(snap.ref, {
            fannedOut: true,
            fannedOutAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return true;
    });
    if (!claimed)
        return;
    // Community name for the notification title.
    const communitySnap = await db
        .collection('communities')
        .doc(communityId)
        .get();
    const communityName = ((_a = communitySnap.data()) === null || _a === void 0 ? void 0 : _a.name) || 'A community';
    const title = `📣 ${communityName}`;
    const body = preview(msg.content || '');
    const dataPayload = {
        type: 'community_announcement',
        communityId,
        action: 'open_community',
    };
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
        // Recipients = members minus the author (and minus banned members).
        const rawIds = page.docs
            .filter((d) => { var _a; return d.id !== senderId && ((_a = d.data()) === null || _a === void 0 ? void 0 : _a.isBanned) !== true; })
            .map((d) => d.id);
        const allowedSet = await (0, prefs_1.filterUidsByPref)(rawIds, 'announcements');
        const recipientIds = rawIds.filter((u) => allowedSet.has(u));
        total += recipientIds.length;
        // Resolve FCM tokens.
        const userDocs = await Promise.all(recipientIds.map((uid) => db.collection('users').doc(uid).get()));
        const tokens = [];
        for (const ud of userDocs) {
            const t = (_b = ud.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
            if (t)
                tokens.push(t);
        }
        for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
            const chunk = tokens.slice(i, i + FCM_CHUNK);
            try {
                await admin.messaging().sendEachForMulticast({
                    tokens: chunk,
                    notification: (0, brand_1.brandPush)(title, body),
                    data: dataPayload,
                    android: {
                        priority: 'high',
                        collapseKey: `community_ann_${communityId}`,
                        notification: {
                            sound: 'default',
                            channelId: 'greengo_notifications',
                            priority: 'high',
                            tag: `community_ann_${communityId}`,
                        },
                    },
                    apns: {
                        headers: { 'apns-collapse-id': `community_ann_${communityId}` },
                        payload: { aps: { sound: 'default', badge: 1 } },
                    },
                });
            }
            catch (e) {
                console.error('Community announcement multicast failed', communityId, e);
            }
        }
        // In-app notification docs (Flutter NotificationModel shape).
        let batch = db.batch();
        let ops = 0;
        const commits = [];
        for (const uid of recipientIds) {
            const ref = db.collection('notifications').doc();
            batch.set(ref, {
                userId: uid,
                type: 'community_announcement',
                title,
                message: body,
                body,
                data: dataPayload,
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
    console.log(`Community announcement in ${communityId} fanned out to ${total} member(s)`);
}));
//# sourceMappingURL=announcementFanout.js.map