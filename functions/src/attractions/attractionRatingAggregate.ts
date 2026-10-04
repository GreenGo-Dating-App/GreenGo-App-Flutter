/**
 * Attraction user-rating aggregate — exactly-once maintenance of the rating
 * fields on `attraction_stats/{attractionId}`:
 *   ratingSum, ratingCount, ratingAvg, ratingDist { "1".."5" }, ratingUpdatedAt
 *
 * Source of truth: `attraction_ratings/{attractionId}/ratings/{uid}`
 * { stars: 1..5, createdAt, updatedAt } — one doc per user, written by that
 * user (create / change stars / delete).
 *
 * Kept free of trigger plumbing (and of a hard `firebase-admin` import) so it
 * is unit-testable against an in-memory Firestore (see __tests__).
 *
 * Model:
 *  - Every write event carries its own BEFORE and AFTER snapshot, so the
 *    change it represents is a pure delta (old stars out, new stars in).
 *    Deltas commute, so out-of-order delivery still converges.
 *  - The event id is claimed in the SAME transaction that applies the delta
 *    (marker doc `attraction_rating_events/{eventId}`, TTL on `expireAt`): a
 *    retried / duplicated delivery finds the marker and does nothing.
 *  - The stats doc is read inside the transaction so `ratingAvg` is computed
 *    from the exact new sum / count. Rating writes are rare (one per user per
 *    attraction) so this is never a hot-spot; `viewCount` keeps using its own
 *    `increment` (the transaction simply retries if it races with one).
 *  - Sums are stored RAW (not clamped): while deltas are applied out of order
 *    a count can transiently dip below its final value, and clamping would
 *    lose that information. Readers treat `ratingCount <= 0` as "no ratings";
 *    `ratingAvg` is only published when the sum is consistent with the count.
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

export interface RatingAggregateDeps {
  /** A `firebase-admin` Firestore (or a structurally compatible fake). */
  db: any;
  /** Clock (injectable for tests). */
  now?: () => Date;
  /** `FieldValue.serverTimestamp()` in production; defaults to `now()`. */
  serverTimestamp?: () => unknown;
}

export const RATING_EVENT_MARKERS = 'attraction_rating_events';
export const STATS_COLLECTION = 'attraction_stats';

/** How long a processed-event marker is kept (retries stop after 7 days). */
const MARKER_TTL_MS = 8 * 24 * 60 * 60 * 1000;

/** Valid star value (int 1..5) or null. */
export function validStars(v: unknown): number | null {
  return typeof v === 'number' && Number.isInteger(v) && v >= 1 && v <= 5 ? v : null;
}

/** Attraction ids are numeric catalogue ids (same pattern the rules pin). */
export function validAttractionId(id: unknown): id is string {
  return typeof id === 'string' && /^[0-9]{1,12}$/.test(id);
}

export interface RatingDelta {
  sum: number;
  count: number;
  dist: Record<string, number>;
}

/** The change one write event represents (null = nothing to apply). */
export function ratingDelta(beforeStars: unknown, afterStars: unknown): RatingDelta | null {
  const b = validStars(beforeStars);
  const a = validStars(afterStars);
  if (b === a) return null; // no-op write (e.g. only updatedAt changed)
  const dist: Record<string, number> = {};
  if (b !== null) dist[String(b)] = (dist[String(b)] ?? 0) - 1;
  if (a !== null) dist[String(a)] = (dist[String(a)] ?? 0) + 1;
  return {
    sum: (a ?? 0) - (b ?? 0),
    count: (a !== null ? 1 : 0) - (b !== null ? 1 : 0),
    dist,
  };
}

function num(v: unknown): number {
  const n = typeof v === 'number' ? v : Number(v ?? 0);
  return Number.isFinite(n) ? n : 0;
}

/** Average rounded to 2 decimals, or 0 when the totals are not (yet) sane. */
export function averageOf(sum: number, count: number): number {
  if (count <= 0 || sum < count || sum > 5 * count) return 0;
  return Math.round((sum / count) * 100) / 100;
}

/**
 * Apply ONE rating write event exactly once. Returns true when this call
 * changed the aggregate.
 */
export async function applyRatingEvent(
  deps: RatingAggregateDeps,
  eventId: string,
  attractionId: string,
  beforeStars: unknown,
  afterStars: unknown,
): Promise<boolean> {
  if (!validAttractionId(attractionId)) return false;
  const delta = ratingDelta(beforeStars, afterStars);
  if (!delta) return false;
  const { db } = deps;
  const now = (deps.now ?? (() => new Date()))();
  const stamp = deps.serverTimestamp ? deps.serverTimestamp() : now;

  const statsRef = db.collection(STATS_COLLECTION).doc(attractionId);
  const marker = db
    .collection(RATING_EVENT_MARKERS)
    .doc(eventId || `rating_${attractionId}_${now.getTime()}`);

  return db.runTransaction(async (txn: any) => {
    // All reads before any write (Firestore transaction rule).
    const [m, s] = await Promise.all([txn.get(marker), txn.get(statsRef)]);
    if (m.exists) return false; // retried delivery of an event already applied

    const cur = s.exists ? s.data() ?? {} : {};
    const curDist = (cur.ratingDist && typeof cur.ratingDist === 'object') ? cur.ratingDist : {};
    const dist: Record<string, number> = {};
    for (let k = 1; k <= 5; k++) {
      const key = String(k);
      dist[key] = num(curDist[key]) + (delta.dist[key] ?? 0);
    }
    const sum = num(cur.ratingSum) + delta.sum;
    const count = num(cur.ratingCount) + delta.count;

    txn.set(marker, {
      kind: 'attraction_rating',
      attractionId,
      at: now,
      expireAt: new Date(now.getTime() + MARKER_TTL_MS),
    });
    const patch = {
      ratingSum: sum,
      ratingCount: count,
      ratingAvg: averageOf(sum, count),
      ratingDist: dist,
      ratingUpdatedAt: stamp,
    };
    // `set(merge)` creates the stats doc when the attraction has never been
    // viewed, and leaves viewCount untouched otherwise.
    txn.set(statsRef, patch, { merge: true });
    return true;
  });
}
