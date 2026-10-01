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
import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import { PUSH_MEMORY } from '../shared/pushRuntime';
import { resolveActor, emitNotification } from '../notifications/notifyHelpers';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const EDGE_PATH = 'business_followers/{followeeId}/followers/{followerId}';

function edgeRef(followeeId: string, followerId: string) {
  return db
    .collection('business_followers')
    .doc(followeeId)
    .collection('followers')
    .doc(followerId);
}

function mirrorRef(followerId: string, followeeId: string) {
  return db
    .collection('user_business_following')
    .doc(followerId)
    .collection('businesses')
    .doc(followeeId);
}

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

/**
 * Count ONE edge exactly once. Returns true when this call did the counting.
 * Profiles that do not exist (deleted accounts) are skipped instead of being
 * resurrected as counter-only stubs.
 */
async function countEdge(followeeId: string, followerId: string): Promise<boolean> {
  const followeeRef = db.collection('profiles').doc(followeeId);
  const followerRef = db.collection('profiles').doc(followerId);
  // Existence pre-check OUTSIDE the transaction, so a popular followee's
  // profile is never a transactional read (no lock contention on hot docs).
  const [followee, follower] = await Promise.all([followeeRef.get(), followerRef.get()]);

  const ref = edgeRef(followeeId, followerId);
  return db.runTransaction(async (txn) => {
    const edge = await txn.get(ref);
    if (!edge.exists || edge.data()?.counted === true) return false;
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
async function decrementClamped(
  ref: admin.firestore.DocumentReference,
  field: 'followersCount' | 'followingCount',
): Promise<void> {
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    if (!snap.exists) return;
    const current = Number(snap.get(field) ?? 0);
    txn.update(ref, { [field]: Math.max(0, (Number.isFinite(current) ? current : 0) - 1) });
  });
}

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
  { document: EDGE_PATH, memory: PUSH_MEMORY },
  monitored('onUserFollowCreated', async (event) => {
    const followeeId = event.params.followeeId as string;
    const followerId = event.params.followerId as string;
    if (!followeeId || !followerId) return;

    if (followeeId === followerId || (await isBlockedEitherWay(followeeId, followerId))) {
      // Remove the edge UNCOUNTED (its delete trigger sees no `counted` flag).
      await Promise.all([
        edgeRef(followeeId, followerId).delete().catch(() => undefined),
        mirrorRef(followerId, followeeId).delete().catch(() => undefined),
      ]);
      return;
    }

    const counted = await countEdge(followeeId, followerId);
    if (!counted) return;

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
export const onUserFollowDeleted = onDocumentDeleted(
  { document: EDGE_PATH, memory: PUSH_MEMORY },
  monitored('onUserFollowDeleted', async (event) => {
    const followeeId = event.params.followeeId as string;
    const followerId = event.params.followerId as string;
    if (event.data?.data()?.counted !== true) return;
    await Promise.all([
      decrementClamped(db.collection('profiles').doc(followeeId), 'followersCount'),
      decrementClamped(db.collection('profiles').doc(followerId), 'followingCount'),
    ]);
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
    const me = await db.collection('users').doc(uid).get();
    if (!me.data()?.isAdmin) throw new HttpsError('permission-denied', 'Admin only.');

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
