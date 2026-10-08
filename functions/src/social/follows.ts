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
import {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentWritten,
} from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { requireAdmin, SUPER_ADMIN_ONLY } from '../shared/adminAuth';
import { monitored } from '../shared/monitoring';
import { PUSH_MEMORY } from '../shared/pushRuntime';
import { resolveActor, emitNotification } from '../notifications/notifyHelpers';
import '../shared/firebaseAdmin';
import {
  FollowCounterDeps,
  countEdge as coreCountEdge,
  uncountEdge,
  edgeRef as coreEdgeRef,
  mirrorRef as coreMirrorRef,
} from './followCounters';
import { FOLLOW_CLEANUP_JOBS, removeFollowGraphRound } from './followCleanup';

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const EDGE_PATH = 'business_followers/{followeeId}/followers/{followerId}';

const deps: FollowCounterDeps = { db, increment: (n) => FieldValue.increment(n) };

const edgeRef = (followeeId: string, followerId: string): admin.firestore.DocumentReference =>
  coreEdgeRef(db, followeeId, followerId);
const mirrorRef = (followerId: string, followeeId: string): admin.firestore.DocumentReference =>
  coreMirrorRef(db, followerId, followeeId);

/** Notifications for a follow older than this are not sent (late retries). */
const NOTIFY_MAX_AGE_MS = 60 * 60 * 1000;

/** True when either user has blocked the other (bounded: 2 x limit(1)). */
async function isBlockedEitherWay(a: string, b: string): Promise<boolean> {
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
  } catch {
    return false; // fail open: a lookup hiccup must not eat a real follow
  }
}

const countEdge = (followeeId: string, followerId: string) =>
  coreCountEdge(deps, followeeId, followerId);

/** Claim a permanent dedup key (true = first time). */
async function claimOnce(key: string): Promise<boolean> {
  try {
    await db.collection('notif_dedup').doc(key).create({ at: FieldValue.serverTimestamp() });
    return true;
  } catch {
    return false;
  }
}

// ── Follow created → count + notify the followee ────────────────────────────
export const onUserFollowCreated = onDocumentCreated(
  // retry: a dropped event (cold-start crash, contention) used to leave the
  // counters permanently off by one. Safe: counting is flag-guarded and the
  // notification is claimed once.
  { document: EDGE_PATH, memory: PUSH_MEMORY, retry: true },
  monitored('onUserFollowCreated', async (event) => {
    const followeeId = event.params.followeeId as string;
    const followerId = event.params.followerId as string;
    if (!followeeId || !followerId) return;

    // A follow of a deleted account (stale client) would only inflate the
    // follower's followingCount for a ghost: remove it uncounted.
    const followeeGone = !(await db.collection('profiles').doc(followeeId).get()).exists;
    if (
      followeeGone ||
      followeeId === followerId ||
      (await isBlockedEitherWay(followeeId, followerId))
    ) {
      // Remove the edge UNCOUNTED (its delete trigger sees no `counted` flag).
      await Promise.all([
        edgeRef(followeeId, followerId).delete().catch(() => undefined),
        mirrorRef(followerId, followeeId).delete().catch(() => undefined),
      ]);
      return;
    }

    const counted = await countEdge(followeeId, followerId);
    if (!counted) return;
    const ageMs = Date.now() - Date.parse(event.time || '');
    if (Number.isFinite(ageMs) && ageMs > NOTIFY_MAX_AGE_MS) return;

    // Business accounts are notified by onBusinessFollowed ('business_follow');
    // everyone else gets a 'new_follower'. Once per follower → followee, ever,
    // so follow/unfollow loops cannot spam.
    const followee = await db.collection('profiles').doc(followeeId).get();
    if (!followee.exists || followee.data()?.isBusiness === true) return;
    if (!(await claimOnce(`new_follower_${followeeId}_${followerId}`))) return;

    const actor = await resolveActor(followerId);
    await emitNotification({
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
  }),
);

// ── Follow deleted → decrement (only edges that were counted) ───────────────
// Decrements BOTH sides: the followee's followersCount and the follower's
// followingCount, exactly once per delete event (event-id marker), never
// below zero.
export const onUserFollowDeleted = onDocumentDeleted(
  { document: EDGE_PATH, memory: PUSH_MEMORY, retry: true },
  monitored('onUserFollowDeleted', async (event) => {
    const followeeId = event.params.followeeId as string;
    const followerId = event.params.followerId as string;
    if (!followeeId || !followerId) return;
    const wasCounted = event.data?.data()?.counted === true;
    await uncountEdge(deps, event.id, followeeId, followerId, wasCounted);
    // Keep the mirror in step with the canonical edge (a client that deleted
    // only the edge, or a server-side edge removal, must not leave a ghost in
    // the follower's "Following" list).
    // Transactional so a quick re-follow (edge re-created) keeps its mirror.
    const edge = edgeRef(followeeId, followerId);
    const mirror = mirrorRef(followerId, followeeId);
    await db
      .runTransaction(async (txn) => {
        const [e, m] = await Promise.all([txn.get(edge), txn.get(mirror)]);
        if (!e.exists && m.exists) txn.delete(mirror);
      })
      .catch(() => undefined);
  }),
);

// ── Account deleted → remove its follow graph in BOTH directions ────────────
// A job doc `follow_cleanup_jobs/{uid}` is created by onProfileDeleted and by
// onUserDeletedCleanup (one job per uid). Each run removes pages of edges
// under a deadline; if work is left it bumps `round`, which re-fires this
// trigger, so an account with millions of followers is drained in bounded
// steps. Counters of the OTHER side are adjusted by onUserFollowDeleted.
const CLEANUP_MAX_ROUNDS = 2000;
const CLEANUP_BUDGET_MS = 420_000; // under the 540 s timeout

export const onFollowCleanupJob = onDocumentWritten(
  {
    document: `${FOLLOW_CLEANUP_JOBS}/{uid}`,
    memory: '512MiB',
    timeoutSeconds: 540,
    retry: true,
  },
  monitored('onFollowCleanupJob', async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return; // job finished (deleted)
    const uid = event.params.uid as string;
    const round = Number(after.get('round') ?? 0);
    if (round > CLEANUP_MAX_ROUNDS) {
      console.error('onFollowCleanupJob: giving up after max rounds', uid, round);
      return;
    }
    const r = await removeFollowGraphRound(deps, uid, {
      deadlineMs: Date.now() + CLEANUP_BUDGET_MS,
    });
    if (r.done) {
      await after.ref.delete();
      console.log(`onFollowCleanupJob: done for ${uid} (round ${round})`);
      return;
    }
    // More to do: the write re-fires this trigger. merge-set (not update) so a
    // retried, late event never throws on an already-finished job.
    await after.ref.set(
      { round: round + 1, lastRunAt: new Date(), lastRemoved: r.asFollower + r.asFollowee },
      { merge: true },
    );
  }),
);

/**
 * Admin-only, resumable backfill: counts every legacy edge that predates the
 * triggers (no `counted` flag) into `followersCount` / `followingCount`.
 * Pages the `followers` collection group by document path; call repeatedly
 * with the returned `cursor` until `done`. Safe to re-run: `countEdge` skips
 * edges that are already counted.
 */
export const backfillFollowCounts = onCall<{ cursor?: string; pageSize?: number }>(
  { memory: '512MiB', timeoutSeconds: 540 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
    await requireAdmin(request.auth, SUPER_ADMIN_ONLY); // P1-6 (was users.isAdmin)

    const pageSize = Math.min(Math.max(Number(request.data?.pageSize) || 300, 1), 500);
    let q = db
      .collectionGroup('followers')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (request.data?.cursor) q = q.startAfter(request.data.cursor);

    const page = await q.get();
    let counted = 0;
    for (const doc of page.docs) {
      const followeeDoc = doc.ref.parent.parent;
      if (!followeeDoc || followeeDoc.parent.id !== 'business_followers') continue;
      if (doc.get('counted') === true) continue;
      try {
        if (await countEdge(followeeDoc.id, doc.id)) counted++;
      } catch {
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
  },
);
