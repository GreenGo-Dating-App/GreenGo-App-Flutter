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
exports.backfillFollowCounts = exports.onFollowCleanupJob = exports.onUserFollowDeleted = exports.onUserFollowCreated = void 0;
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
 * Exactly-once counting (see followCounters.ts): the create trigger marks the
 * edge `counted: true` in the same transaction that increments the counters,
 * and the delete trigger only decrements an edge whose deleted snapshot
 * carries `counted: true`, claiming the delete event id so a retry never
 * decrements twice. Both triggers RETRY (a dropped event used to leave the
 * counters off by one forever). Legacy edges (created before this shipped)
 * only move the counters once `backfillFollowCounts` (or
 * scripts/recount_follow_counters.js) has counted them.
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
const followCounters_1 = require("./followCounters");
const followCleanup_1 = require("./followCleanup");
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const EDGE_PATH = 'business_followers/{followeeId}/followers/{followerId}';
const deps = { db, increment: (n) => FieldValue.increment(n) };
const edgeRef = (followeeId, followerId) => (0, followCounters_1.edgeRef)(db, followeeId, followerId);
const mirrorRef = (followerId, followeeId) => (0, followCounters_1.mirrorRef)(db, followerId, followeeId);
/** Notifications for a follow older than this are not sent (late retries). */
const NOTIFY_MAX_AGE_MS = 60 * 60 * 1000;
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
const countEdge = (followeeId, followerId) => (0, followCounters_1.countEdge)(deps, followeeId, followerId);
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
exports.onUserFollowCreated = (0, firestore_1.onDocumentCreated)(
// retry: a dropped event (cold-start crash, contention) used to leave the
// counters permanently off by one. Safe: counting is flag-guarded and the
// notification is claimed once.
{ document: EDGE_PATH, memory: pushRuntime_1.PUSH_MEMORY, retry: true }, (0, monitoring_1.monitored)('onUserFollowCreated', async (event) => {
    var _a;
    const followeeId = event.params.followeeId;
    const followerId = event.params.followerId;
    if (!followeeId || !followerId)
        return;
    // A follow of a deleted account (stale client) would only inflate the
    // follower's followingCount for a ghost: remove it uncounted.
    const followeeGone = !(await db.collection('profiles').doc(followeeId).get()).exists;
    if (followeeGone ||
        followeeId === followerId ||
        (await isBlockedEitherWay(followeeId, followerId))) {
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
    const ageMs = Date.now() - Date.parse(event.time || '');
    if (Number.isFinite(ageMs) && ageMs > NOTIFY_MAX_AGE_MS)
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
// Decrements BOTH sides: the followee's followersCount and the follower's
// followingCount, exactly once per delete event (event-id marker), never
// below zero.
exports.onUserFollowDeleted = (0, firestore_1.onDocumentDeleted)({ document: EDGE_PATH, memory: pushRuntime_1.PUSH_MEMORY, retry: true }, (0, monitoring_1.monitored)('onUserFollowDeleted', async (event) => {
    var _a, _b;
    const followeeId = event.params.followeeId;
    const followerId = event.params.followerId;
    if (!followeeId || !followerId)
        return;
    const wasCounted = ((_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data()) === null || _b === void 0 ? void 0 : _b.counted) === true;
    await (0, followCounters_1.uncountEdge)(deps, event.id, followeeId, followerId, wasCounted);
    // Keep the mirror in step with the canonical edge (a client that deleted
    // only the edge, or a server-side edge removal, must not leave a ghost in
    // the follower's "Following" list).
    // Transactional so a quick re-follow (edge re-created) keeps its mirror.
    const edge = edgeRef(followeeId, followerId);
    const mirror = mirrorRef(followerId, followeeId);
    await db
        .runTransaction(async (txn) => {
        const [e, m] = await Promise.all([txn.get(edge), txn.get(mirror)]);
        if (!e.exists && m.exists)
            txn.delete(mirror);
    })
        .catch(() => undefined);
}));
// ── Account deleted → remove its follow graph in BOTH directions ────────────
// A job doc `follow_cleanup_jobs/{uid}` is created by onProfileDeleted and by
// onUserDeletedCleanup (one job per uid). Each run removes pages of edges
// under a deadline; if work is left it bumps `round`, which re-fires this
// trigger, so an account with millions of followers is drained in bounded
// steps. Counters of the OTHER side are adjusted by onUserFollowDeleted.
const CLEANUP_MAX_ROUNDS = 2000;
const CLEANUP_BUDGET_MS = 420000; // under the 540 s timeout
exports.onFollowCleanupJob = (0, firestore_1.onDocumentWritten)({
    document: `${followCleanup_1.FOLLOW_CLEANUP_JOBS}/{uid}`,
    memory: '512MiB',
    timeoutSeconds: 540,
    retry: true,
}, (0, monitoring_1.monitored)('onFollowCleanupJob', async (event) => {
    var _a, _b;
    const after = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after;
    if (!(after === null || after === void 0 ? void 0 : after.exists))
        return; // job finished (deleted)
    const uid = event.params.uid;
    const round = Number((_b = after.get('round')) !== null && _b !== void 0 ? _b : 0);
    if (round > CLEANUP_MAX_ROUNDS) {
        console.error('onFollowCleanupJob: giving up after max rounds', uid, round);
        return;
    }
    const r = await (0, followCleanup_1.removeFollowGraphRound)(deps, uid, {
        deadlineMs: Date.now() + CLEANUP_BUDGET_MS,
    });
    if (r.done) {
        await after.ref.delete();
        console.log(`onFollowCleanupJob: done for ${uid} (round ${round})`);
        return;
    }
    // More to do: the write re-fires this trigger. merge-set (not update) so a
    // retried, late event never throws on an already-finished job.
    await after.ref.set({ round: round + 1, lastRunAt: new Date(), lastRemoved: r.asFollower + r.asFollowee }, { merge: true });
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