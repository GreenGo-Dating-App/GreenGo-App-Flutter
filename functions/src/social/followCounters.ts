/**
 * Follow-counter core — exactly-once, never-negative maintenance of
 * `follow_counts/{followee}.followersCount` and
 * `follow_counts/{follower}.followingCount`.
 *
 * PRIVATE (owner rule 2026-10-17): follower / following counts are visible
 * ONLY to the account itself (users AND businesses). They live in the
 * owner-only `follow_counts/{uid}` document (rules: read by the owner or an
 * admin-panel user, never written by a client), NOT on the public
 * `profiles/{uid}`. A dedicated collection (rather than `profiles_private`)
 * so a follow fires no profile trigger (syncCoarseFromPrivateProfile /
 * mirrorPrivateProfileFields) and a hot counter never contends with profile
 * edits. scripts/move-follow-counts-private.ts moves legacy public values.
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

/* eslint-disable @typescript-eslint/no-explicit-any */

export type CounterField = 'followersCount' | 'followingCount' | 'storesCount';

/**
 * Edge flag: this edge was counted into the follower's `storesCount` (the
 * followee was a business account when it was counted). Decrements follow
 * the FLAG, not the followee's current isBusiness, so an account that turns
 * business later never drifts the count.
 */
export const STORE_COUNTED_FLAG = 'countedStore';

/**
 * Mirror flag (`user_business_following/{follower}/businesses/{followee}`):
 * the followee is a business. Server-written with [STORE_COUNTED_FLAG]; the
 * app's "Stores" list is `where(isStore == true)` on the follower's own
 * mirror collection (automatic single-field index).
 */
export const MIRROR_STORE_FLAG = 'isStore';

export interface FollowCounterDeps {
  /** A `firebase-admin` Firestore (or a structurally compatible fake). */
  db: any;
  /** `FieldValue.increment` (or a fake sentinel factory in tests). */
  increment: (n: number) => unknown;
  /** Clock (injectable for tests). */
  now?: () => Date;
}

/** Marker docs for processed unfollow events (TTL on `expireAt`). */
export const UNCOUNT_MARKERS = 'follow_counter_events';

/** How long an unfollow-event marker is kept (retries stop after 7 days). */
const MARKER_TTL_MS = 8 * 24 * 60 * 60 * 1000;

/** Coerce a stored counter to a non-negative integer (missing/NaN → 0). */
export function clampCount(v: unknown): number {
  const n = typeof v === 'number' ? v : Number(v ?? 0);
  if (!Number.isFinite(n) || n <= 0) return 0;
  return Math.floor(n);
}

export function edgeRef(db: any, followeeId: string, followerId: string) {
  return db
    .collection('business_followers')
    .doc(followeeId)
    .collection('followers')
    .doc(followerId);
}

export function mirrorRef(db: any, followerId: string, followeeId: string) {
  return db
    .collection('user_business_following')
    .doc(followerId)
    .collection('businesses')
    .doc(followeeId);
}

function profileRef(db: any, uid: string) {
  return db.collection('profiles').doc(uid);
}

/** Owner-only counters document (see the header). */
export const FOLLOW_COUNTS = 'follow_counts';

export function countsRef(db: any, uid: string) {
  return db.collection(FOLLOW_COUNTS).doc(uid);
}

/**
 * Count ONE edge exactly once. Returns true when this call did the counting.
 * Profiles that do not exist (deleted accounts) are skipped instead of being
 * resurrected as counter-only stubs.
 */
export async function countEdge(
  deps: FollowCounterDeps,
  followeeId: string,
  followerId: string,
): Promise<boolean> {
  const { db, increment } = deps;
  const followeeRef = profileRef(db, followeeId);
  const followerRef = profileRef(db, followerId);
  // Existence pre-check OUTSIDE the transaction, so a popular followee's
  // profile is never a transactional read (no lock contention on hot docs).
  const [followee, follower] = await Promise.all([followeeRef.get(), followerRef.get()]);

  const ref = edgeRef(db, followeeId, followerId);
  return db.runTransaction(async (txn: any) => {
    const edge = await txn.get(ref);
    if (!edge.exists || edge.data()?.counted === true) return false;
    // Following a BUSINESS also counts into the follower's private
    // `storesCount` (the "Stores" column of the own profile).
    const isStore = followee.exists && followee.data()?.isBusiness === true;
    const mirror = isStore ? await txn.get(mirrorRef(db, followerId, followeeId)) : null;
    txn.update(ref, isStore ? { counted: true, [STORE_COUNTED_FLAG]: true } : { counted: true });
    if (mirror?.exists) txn.update(mirror.ref, { [MIRROR_STORE_FLAG]: true });
    // merge-set: the counters doc is created on the first follow.
    if (followee.exists) {
      txn.set(countsRef(db, followeeId), { followersCount: increment(1) }, { merge: true });
    }
    if (follower.exists) {
      txn.set(
        countsRef(db, followerId),
        isStore ? { followingCount: increment(1), storesCount: increment(1) } : { followingCount: increment(1) },
        { merge: true },
      );
    }
    return true;
  });
}

/**
 * Undo the count of ONE deleted edge, exactly once per delete event.
 * [wasCounted] is the `counted` flag of the deleted snapshot: an edge removed
 * before it was ever counted must not move the counters. Returns true when
 * this call decremented.
 */
export async function uncountEdge(
  deps: FollowCounterDeps,
  eventId: string,
  followeeId: string,
  followerId: string,
  wasCounted: boolean,
  opts: { wasStoreCounted?: boolean } = {},
): Promise<boolean> {
  if (!wasCounted || !followeeId || !followerId) return false;
  const store = opts.wasStoreCounted === true;
  const { db, increment } = deps;
  const now = (deps.now ?? (() => new Date()))();
  const followeeRef = profileRef(db, followeeId);
  const followerRef = profileRef(db, followerId);
  const [followee, follower] = await Promise.all([followeeRef.get(), followerRef.get()]);

  const marker = db
    .collection(UNCOUNT_MARKERS)
    .doc(eventId || `unfollow_${followeeId}_${followerId}_${now.getTime()}`);
  const did: boolean = await db.runTransaction(async (txn: any) => {
    const m = await txn.get(marker);
    if (m.exists) return false; // retried delivery of an event already applied
    txn.set(marker, {
      kind: 'unfollow',
      followeeId,
      followerId,
      at: now,
      expireAt: new Date(now.getTime() + MARKER_TTL_MS),
    });
    if (followee.exists) {
      txn.set(countsRef(db, followeeId), { followersCount: increment(-1) }, { merge: true });
    }
    if (follower.exists) {
      txn.set(
        countsRef(db, followerId),
        store ? { followingCount: increment(-1), storesCount: increment(-1) } : { followingCount: increment(-1) },
        { merge: true },
      );
    }
    return true;
  });
  if (did) {
    await Promise.all([
      followee.exists ? clampNonNegative(deps, countsRef(db, followeeId), 'followersCount') : null,
      follower.exists ? clampNonNegative(deps, countsRef(db, followerId), 'followingCount') : null,
      follower.exists && store ? clampNonNegative(deps, countsRef(db, followerId), 'storesCount') : null,
    ]);
  }
  return did;
}

/**
 * Pull a counter that drifted below zero back to 0. Cheap in the normal case
 * (one plain read); the transaction only runs when a fix is needed.
 */
export async function clampNonNegative(
  deps: FollowCounterDeps,
  ref: any,
  field: CounterField,
): Promise<void> {
  const snap = await ref.get();
  if (!snap.exists) return;
  const v = snap.get(field);
  if (typeof v === 'number' && v >= 0) return;
  if (v === undefined || v === null) return;
  await deps.db.runTransaction(async (txn: any) => {
    const s = await txn.get(ref);
    if (!s.exists) return;
    const cur = s.get(field);
    if (typeof cur === 'number' && cur >= 0) return;
    txn.update(ref, { [field]: clampCount(cur) });
  });
}

/**
 * Backfill ONE legacy business-follow edge into the follower's `storesCount`
 * (edges counted before `storesCount` existed). Exactly once: the
 * [STORE_COUNTED_FLAG] is set in the same transaction as the increment.
 * Only for an edge that is already `counted` (an uncounted edge gets both
 * from [countEdge]). Returns true when this call counted it.
 */
export async function countStoreEdge(
  deps: FollowCounterDeps,
  followeeId: string,
  followerId: string,
): Promise<boolean> {
  const { db, increment } = deps;
  const follower = await profileRef(db, followerId).get();
  const ref = edgeRef(db, followeeId, followerId);
  return db.runTransaction(async (txn: any) => {
    const edge = await txn.get(ref);
    const d = edge.exists ? edge.data() : undefined;
    if (!d || d.counted !== true || d[STORE_COUNTED_FLAG] === true) return false;
    const mirror = await txn.get(mirrorRef(db, followerId, followeeId));
    txn.update(ref, { [STORE_COUNTED_FLAG]: true });
    if (mirror.exists) txn.update(mirror.ref, { [MIRROR_STORE_FLAG]: true });
    if (follower.exists) {
      txn.set(countsRef(db, followerId), { storesCount: increment(1) }, { merge: true });
    }
    return true;
  });
}
