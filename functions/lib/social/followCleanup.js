"use strict";
/**
 * Account deletion → remove the deleted user's WHOLE follow graph, both
 * directions, bounded and resumable:
 *
 *  - as FOLLOWER: every `business_followers/{x}/followers/{uid}` edge (found via
 *    the mirror `user_business_following/{uid}/businesses/{x}`) + the mirror;
 *  - as FOLLOWEE: every `business_followers/{uid}/followers/{f}` edge + the
 *    follower's mirror `user_business_following/{f}/businesses/{uid}`.
 *
 * Counters: this module NEVER touches `followersCount` / `followingCount`.
 * Deleting a canonical edge fires onUserFollowDeleted, which decrements the
 * OTHER side exactly once (only edges that were counted; event-id marker
 * against retries) and skips the deleted user's own, already-gone profile.
 * Only the legacy client field `followerCount` (old app versions) is
 * decremented here, for edges that actually existed.
 *
 * Bounded: work is done in pages under a deadline; the caller re-runs (the
 * `follow_cleanup_jobs/{uid}` chain in follows.ts) until `done`. Resume is by
 * RE-QUERYING the source collections (each page is deleted, so the next query
 * returns what is left) — no saved offset.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.FOLLOW_CLEANUP_JOBS = void 0;
exports.removeFollowGraphRound = removeFollowGraphRound;
exports.enqueueFollowGraphCleanup = enqueueFollowGraphCleanup;
/* eslint-disable @typescript-eslint/no-explicit-any */
const followCounters_1 = require("./followCounters");
exports.FOLLOW_CLEANUP_JOBS = 'follow_cleanup_jobs';
const followersCol = (db, uid) => db.collection('business_followers').doc(uid).collection('followers');
const followingMirrorCol = (db, uid) => db.collection('user_business_following').doc(uid).collection('businesses');
/**
 * One bounded round of follow-graph removal for [uid]. Stops between pages
 * once [deadlineMs] (epoch ms) has passed; returns `done: false` then.
 */
async function removeFollowGraphRound(deps, uid, opts) {
    var _a, _b;
    const { db, increment } = deps;
    // <= 3 writes per doc in a page and a batch takes at most 500 writes.
    const pageSize = Math.max(1, Math.min((_a = opts.pageSize) !== null && _a !== void 0 ? _a : 150, 150));
    const now = (_b = opts.nowMs) !== null && _b !== void 0 ? _b : (() => Date.now());
    const res = { done: false, asFollower: 0, asFollowee: 0 };
    if (!uid)
        return Object.assign(Object.assign({}, res), { done: true });
    // Every round processes at least one page, so a round can never stall.
    let worked = false;
    const outOfTime = () => worked && now() > opts.deadlineMs;
    // 1) Edges where the deleted user is the FOLLOWER (bounded by their mirror).
    for (;;) {
        if (outOfTime())
            return res;
        const page = await followingMirrorCol(db, uid).limit(pageSize).get();
        if (page.empty)
            break;
        const followeeIds = page.docs.map((m) => m.id);
        const [edges, followees] = await Promise.all([
            db.getAll(...followeeIds.map((x) => (0, followCounters_1.edgeRef)(db, x, uid))),
            db.getAll(...followeeIds.map((x) => db.collection('profiles').doc(x))),
        ]);
        const batch = db.batch();
        page.docs.forEach((m, i) => {
            batch.delete(m.ref);
            if (edges[i].exists) {
                batch.delete(edges[i].ref);
                res.asFollower++;
                // Legacy client-maintained counter (old app versions) — only for a
                // real edge on a live profile (an update on a missing doc would fail
                // the whole batch, which is how orphans used to survive).
                if (followees[i].exists) {
                    batch.update(followees[i].ref, { followerCount: increment(-1) });
                }
            }
        });
        await batch.commit();
        worked = true;
    }
    // 2) Edges where the deleted user is the FOLLOWEE.
    for (;;) {
        if (outOfTime())
            return res;
        const page = await followersCol(db, uid).limit(pageSize).get();
        if (page.empty)
            break;
        const batch = db.batch();
        for (const e of page.docs) {
            batch.delete(e.ref);
            batch.delete((0, followCounters_1.mirrorRef)(db, e.id, uid));
            res.asFollowee++;
        }
        await batch.commit();
        worked = true;
    }
    return Object.assign(Object.assign({}, res), { done: true });
}
/** Queue the follow-graph removal for [uid] (idempotent: one job per uid). */
async function enqueueFollowGraphCleanup(db, uid) {
    if (!uid)
        return;
    try {
        await db.collection(exports.FOLLOW_CLEANUP_JOBS).doc(uid).create({
            uid,
            round: 0,
            createdAt: new Date(),
        });
    }
    catch (e) {
        // ALREADY_EXISTS (code 6): a job is already queued / running — fine.
        if ((e === null || e === void 0 ? void 0 : e.code) !== 6 && !/already exists/i.test(String(e === null || e === void 0 ? void 0 : e.message)))
            throw e;
    }
}
//# sourceMappingURL=followCleanup.js.map