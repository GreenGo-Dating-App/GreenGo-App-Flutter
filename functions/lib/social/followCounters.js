"use strict";
/**
 * Follow-counter core — exactly-once, never-negative maintenance of
 * `profiles/{followee}.followersCount` and `profiles/{follower}.followingCount`.
 *
 * Kept free of trigger plumbing (and of a hard `firebase-admin` import) so it
 * can be unit-tested against an in-memory Firestore: callers pass the db and
 * the `increment` sentinel factory (`FieldValue.increment` in production).
 *
 * Model:
 *  - FOLLOW: `countEdge` marks the edge `counted: true` in the SAME
 *    transaction that increments both counters. A retried / duplicated create
 *    event finds the flag and does nothing.
 *  - UNFOLLOW: `uncountEdge` runs only for a deleted edge whose last snapshot
 *    carried `counted: true`, and claims the delete EVENT id in the same
 *    transaction that decrements both counters, so a retried delete event
 *    never decrements twice.
 *  - Counters use `increment` (no transactional read of a hot profile doc, so
 *    a followee with millions of followers is never a lock hot-spot). A value
 *    that would have gone below zero (drifted legacy data) is clamped back to
 *    0 right after.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.UNCOUNT_MARKERS = void 0;
exports.clampCount = clampCount;
exports.edgeRef = edgeRef;
exports.mirrorRef = mirrorRef;
exports.countEdge = countEdge;
exports.uncountEdge = uncountEdge;
exports.clampNonNegative = clampNonNegative;
/** Marker docs for processed unfollow events (TTL on `expireAt`). */
exports.UNCOUNT_MARKERS = 'follow_counter_events';
/** How long an unfollow-event marker is kept (retries stop after 7 days). */
const MARKER_TTL_MS = 8 * 24 * 60 * 60 * 1000;
/** Coerce a stored counter to a non-negative integer (missing/NaN → 0). */
function clampCount(v) {
    const n = typeof v === 'number' ? v : Number(v !== null && v !== void 0 ? v : 0);
    if (!Number.isFinite(n) || n <= 0)
        return 0;
    return Math.floor(n);
}
function edgeRef(db, followeeId, followerId) {
    return db
        .collection('business_followers')
        .doc(followeeId)
        .collection('followers')
        .doc(followerId);
}
function mirrorRef(db, followerId, followeeId) {
    return db
        .collection('user_business_following')
        .doc(followerId)
        .collection('businesses')
        .doc(followeeId);
}
function profileRef(db, uid) {
    return db.collection('profiles').doc(uid);
}
/**
 * Count ONE edge exactly once. Returns true when this call did the counting.
 * Profiles that do not exist (deleted accounts) are skipped instead of being
 * resurrected as counter-only stubs.
 */
async function countEdge(deps, followeeId, followerId) {
    const { db, increment } = deps;
    const followeeRef = profileRef(db, followeeId);
    const followerRef = profileRef(db, followerId);
    // Existence pre-check OUTSIDE the transaction, so a popular followee's
    // profile is never a transactional read (no lock contention on hot docs).
    const [followee, follower] = await Promise.all([followeeRef.get(), followerRef.get()]);
    const ref = edgeRef(db, followeeId, followerId);
    return db.runTransaction(async (txn) => {
        var _a;
        const edge = await txn.get(ref);
        if (!edge.exists || ((_a = edge.data()) === null || _a === void 0 ? void 0 : _a.counted) === true)
            return false;
        txn.update(ref, { counted: true });
        if (followee.exists)
            txn.update(followeeRef, { followersCount: increment(1) });
        if (follower.exists)
            txn.update(followerRef, { followingCount: increment(1) });
        return true;
    });
}
/**
 * Undo the count of ONE deleted edge, exactly once per delete event.
 * [wasCounted] is the `counted` flag of the deleted snapshot: an edge removed
 * before it was ever counted must not move the counters. Returns true when
 * this call decremented.
 */
async function uncountEdge(deps, eventId, followeeId, followerId, wasCounted) {
    var _a;
    if (!wasCounted || !followeeId || !followerId)
        return false;
    const { db, increment } = deps;
    const now = ((_a = deps.now) !== null && _a !== void 0 ? _a : (() => new Date()))();
    const followeeRef = profileRef(db, followeeId);
    const followerRef = profileRef(db, followerId);
    const [followee, follower] = await Promise.all([followeeRef.get(), followerRef.get()]);
    const marker = db
        .collection(exports.UNCOUNT_MARKERS)
        .doc(eventId || `unfollow_${followeeId}_${followerId}_${now.getTime()}`);
    const did = await db.runTransaction(async (txn) => {
        const m = await txn.get(marker);
        if (m.exists)
            return false; // retried delivery of an event already applied
        txn.set(marker, {
            kind: 'unfollow',
            followeeId,
            followerId,
            at: now,
            expireAt: new Date(now.getTime() + MARKER_TTL_MS),
        });
        if (followee.exists)
            txn.update(followeeRef, { followersCount: increment(-1) });
        if (follower.exists)
            txn.update(followerRef, { followingCount: increment(-1) });
        return true;
    });
    if (did) {
        await Promise.all([
            followee.exists ? clampNonNegative(deps, followeeRef, 'followersCount') : null,
            follower.exists ? clampNonNegative(deps, followerRef, 'followingCount') : null,
        ]);
    }
    return did;
}
/**
 * Pull a counter that drifted below zero back to 0. Cheap in the normal case
 * (one plain read); the transaction only runs when a fix is needed.
 */
async function clampNonNegative(deps, ref, field) {
    const snap = await ref.get();
    if (!snap.exists)
        return;
    const v = snap.get(field);
    if (typeof v === 'number' && v >= 0)
        return;
    if (v === undefined || v === null)
        return;
    await deps.db.runTransaction(async (txn) => {
        const s = await txn.get(ref);
        if (!s.exists)
            return;
        const cur = s.get(field);
        if (typeof cur === 'number' && cur >= 0)
            return;
        txn.update(ref, { [field]: clampCount(cur) });
    });
}
//# sourceMappingURL=followCounters.js.map