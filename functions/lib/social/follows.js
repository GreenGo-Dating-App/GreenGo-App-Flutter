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
exports.backfillFollowCounts = exports.onUserFollowDeleted = exports.onUserFollowCreated = void 0;
/**
 * User follow graph — authoritative follower / following counters.
 *
 * The follow graph EXTENDS the existing business-follow edges (one model for
 * every account, business or not):
 *   - `business_followers/{followeeId}/followers/{followerId}`   (canonical edge)
 *   - `user_business_following/{followerId}/businesses/{followeeId}` (mirror)
 * Both are written by the follower's client; rules only let a user create /
 * delete their OWN edge and never update one.
 *
 * Counters live on the profile in fields NO client can write:
 *   - `profiles/{followee}.followersCount`
 *   - `profiles/{follower}.followingCount`
 * (The legacy `followerCount` stays client-writable for old app versions but
 * is no longer read by the app.)
 *
 * Exactly-once counting: the create trigger marks the edge `counted: true` in
 * the same transaction that increments the counters, and the delete trigger
 * only decrements an edge whose deleted snapshot carries `counted: true`. So a
 * retried create never double-counts, an edge deleted before it was counted is
 * never decremented, and legacy edges (created before this shipped) only move
 * the counters once `backfillFollowCounts` has counted them.
 *
 * Blocks: an edge between users who have blocked each other (either way) is
 * removed uncounted and nobody is notified.
 */
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
const pushRuntime_1 = require("../shared/pushRuntime");
const notifyHelpers_1 = require("../notifications/notifyHelpers");
require("../shared/firebaseAdmin");
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const EDGE_PATH = 'business_followers/{followeeId}/followers/{followerId}';
function edgeRef(followeeId, followerId) {
    return db
        .collection('business_followers')
        .doc(followeeId)
        .collection('followers')
        .doc(followerId);
}
function mirrorRef(followerId, followeeId) {
    return db
        .collection('user_business_following')
        .doc(followerId)
        .collection('businesses')
        .doc(followeeId);
}
/** True when either user has blocked the other (bounded: 2 x limit(1)). */
async function isBlockedEitherWay(a, b) {
    try {
        const [ab, ba] = await Promise.all([
            db.collection('blockedUsers')
                .where('blockerId', '==', a)
                .where('blockedUserId', '==', b)
                .limit(1)
                .get(),
            db.collection('blockedUsers')
                .where('blockerId', '==', b)
                .where('blockedUserId', '==', a)
                .limit(1)
                .get(),
        ]);
        return !ab.empty || !ba.empty;
    }
    catch (_a) {
        return false; // fail open: a lookup hiccup must not eat a real follow
    }
}
/**
 * Count ONE edge exactly once. Returns true when this call did the counting.
 * Profiles that do not exist (deleted accounts) are skipped instead of being
 * resurrected as counter-only stubs.
 */
async function countEdge(followeeId, followerId) {
    const followeeRef = db.collection('profiles').doc(followeeId);
    const followerRef = db.collection('profiles').doc(followerId);
    // Existence pre-check OUTSIDE the transaction, so a popular followee's
    // profile is never a transactional read (no lock contention on hot docs).
    const [followee, follower] = await Promise.all([followeeRef.get(), followerRef.get()]);
    const ref = edgeRef(followeeId, followerId);
    return db.runTransaction(async (txn) => {
        var _a;
        const edge = await txn.get(ref);
        if (!edge.exists || ((_a = edge.data()) === null || _a === void 0 ? void 0 : _a.counted) === true)
            return false;
        txn.update(ref, { counted: true });
        if (followee.exists) {
            txn.update(followeeRef, { followersCount: FieldValue.increment(1) });
        }
        if (follower.exists) {
            txn.update(followerRef, { followingCount: FieldValue.increment(1) });
        }
        return true;
    });
}
/** Decrement a counter on [ref] by one, never below zero; no-op if missing. */
async function decrementClamped(ref, field) {
    await db.runTransaction(async (txn) => {
        var _a;
        const snap = await txn.get(ref);
        if (!snap.exists)
            return;
        const current = Number((_a = snap.get(field)) !== null && _a !== void 0 ? _a : 0);
        txn.update(ref, { [field]: Math.max(0, (Number.isFinite(current) ? current : 0) - 1) });
    });
}
/** Claim a permanent dedup key (true = first time). */
async function claimOnce(key) {
    try {
        await db.collection('notif_dedup').doc(key).create({ at: FieldValue.serverTimestamp() });
        return true;
    }
    catch (_a) {
        return false;
    }
}
// ── Follow created → count + notify the followee ────────────────────────────
exports.onUserFollowCreated = (0, firestore_1.onDocumentCreated)({ document: EDGE_PATH, memory: pushRuntime_1.PUSH_MEMORY }, (0, monitoring_1.monitored)('onUserFollowCreated', async (event) => {
    var _a;
    const followeeId = event.params.followeeId;
    const followerId = event.params.followerId;
    if (!followeeId || !followerId)
        return;
    if (followeeId === followerId || (await isBlockedEitherWay(followeeId, followerId))) {
        // Remove the edge UNCOUNTED (its delete trigger sees no `counted` flag).
        await Promise.all([
            edgeRef(followeeId, followerId).delete().catch(() => undefined),
            mirrorRef(followerId, followeeId).delete().catch(() => undefined),
        ]);
        return;
    }
    const counted = await countEdge(followeeId, followerId);
    if (!counted)
        return;
    // Business accounts are notified by onBusinessFollowed ('business_follow');
    // everyone else gets a 'new_follower'. Once per follower → followee, ever,
    // so follow/unfollow loops cannot spam.
    const followee = await db.collection('profiles').doc(followeeId).get();
    if (!followee.exists || ((_a = followee.data()) === null || _a === void 0 ? void 0 : _a.isBusiness) === true)
        return;
    if (!(await claimOnce(`new_follower_${followeeId}_${followerId}`)))
        return;
    const actor = await (0, notifyHelpers_1.resolveActor)(followerId);
    await (0, notifyHelpers_1.emitNotification)({
        recipientId: followeeId,
        type: 'new_follower',
        title: 'started following you',
        body: 'Tap to see their profile',
        data: {
            type: 'new_follower',
            action: 'open_profile',
            profileId: followerId,
            actorId: followerId,
        },
        actor,
    });
}));
// ── Follow deleted → decrement (only edges that were counted) ───────────────
exports.onUserFollowDeleted = (0, firestore_1.onDocumentDeleted)({ document: EDGE_PATH, memory: pushRuntime_1.PUSH_MEMORY }, (0, monitoring_1.monitored)('onUserFollowDeleted', async (event) => {
    var _a, _b;
    const followeeId = event.params.followeeId;
    const followerId = event.params.followerId;
    if (((_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data()) === null || _b === void 0 ? void 0 : _b.counted) !== true)
        return;
    await Promise.all([
        decrementClamped(db.collection('profiles').doc(followeeId), 'followersCount'),
        decrementClamped(db.collection('profiles').doc(followerId), 'followingCount'),
    ]);
}));
/**
 * Admin-only, resumable backfill: counts every legacy edge that predates the
 * triggers (no `counted` flag) into `followersCount` / `followingCount`.
 * Pages the `followers` collection group by document path; call repeatedly
 * with the returned `cursor` until `done`. Safe to re-run: `countEdge` skips
 * edges that are already counted.
 */
exports.backfillFollowCounts = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 540 }, async (request) => {
    var _a, _b, _c, _d;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const me = await db.collection('users').doc(uid).get();
    if (!((_b = me.data()) === null || _b === void 0 ? void 0 : _b.isAdmin))
        throw new https_1.HttpsError('permission-denied', 'Admin only.');
    const pageSize = Math.min(Math.max(Number((_c = request.data) === null || _c === void 0 ? void 0 : _c.pageSize) || 300, 1), 500);
    let q = db
        .collectionGroup('followers')
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(pageSize);
    if ((_d = request.data) === null || _d === void 0 ? void 0 : _d.cursor)
        q = q.startAfter(request.data.cursor);
    const page = await q.get();
    let counted = 0;
    for (const doc of page.docs) {
        const followeeDoc = doc.ref.parent.parent;
        if (!followeeDoc || followeeDoc.parent.id !== 'business_followers')
            continue;
        if (doc.get('counted') === true)
            continue;
        try {
            if (await countEdge(followeeDoc.id, doc.id))
                counted++;
        }
        catch (_e) {
            // leave it for the next run
        }
    }
    const last = page.docs[page.docs.length - 1];
    return {
        scanned: page.size,
        counted,
        cursor: last ? last.ref.path : null,
        done: page.size < pageSize,
    };
});
//# sourceMappingURL=follows.js.map