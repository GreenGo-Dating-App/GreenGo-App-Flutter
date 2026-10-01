/**
 * User experiences — rating aggregate math (PURE: no Firestore access).
 *
 * The experience document carries SERVER-maintained aggregates:
 *   ratingSum, ratingCount, ratingAvg, reviewCount, ratingDist {"1".."5"}
 * Only reviews whose status is 'visible' count. A review write is turned into
 * a delta (before contribution → after contribution) which is applied to the
 * experience inside a transaction. Deltas commute, so out-of-order trigger
 * deliveries still converge; duplicate deliveries are filtered by event id in
 * the trigger.
 */

export interface RatingContribution {
  rating: number; // 1..5, or 0 when the review does not count
  counted: boolean;
}

export interface AggregateDelta {
  sum: number;
  count: number;
  dist: Record<string, number>; // "1".."5" → delta
}

export interface RatingAggregate {
  ratingSum: number;
  ratingCount: number;
  ratingAvg: number;
  reviewCount: number;
  ratingDist: Record<string, number>;
}

const STARS = ['1', '2', '3', '4', '5'];

/** Integer rating 1..5, or null for anything else. */
export function validRating(v: unknown): number | null {
  if (typeof v !== 'number' || !Number.isInteger(v)) return null;
  return v >= 1 && v <= 5 ? v : null;
}

/** What one review document contributes to the aggregate. */
export function ratingContribution(
  review: Record<string, unknown> | null | undefined,
): RatingContribution {
  if (!review || review.status !== 'visible') return { rating: 0, counted: false };
  const r = validRating(review.rating);
  if (r === null) return { rating: 0, counted: false };
  return { rating: r, counted: true };
}

/** Delta between a review's state before and after a write. */
export function computeAggregateDelta(
  before: Record<string, unknown> | null | undefined,
  after: Record<string, unknown> | null | undefined,
): AggregateDelta {
  const b = ratingContribution(before);
  const a = ratingContribution(after);
  const dist: Record<string, number> = {};
  if (b.counted) dist[String(b.rating)] = (dist[String(b.rating)] ?? 0) - 1;
  if (a.counted) dist[String(a.rating)] = (dist[String(a.rating)] ?? 0) + 1;
  for (const k of Object.keys(dist)) if (dist[k] === 0) delete dist[k];
  return {
    sum: (a.counted ? a.rating : 0) - (b.counted ? b.rating : 0),
    count: (a.counted ? 1 : 0) - (b.counted ? 1 : 0),
    dist,
  };
}

export function isZeroDelta(d: AggregateDelta): boolean {
  return d.sum === 0 && d.count === 0 && Object.keys(d.dist).length === 0;
}

function num(v: unknown): number {
  return typeof v === 'number' && Number.isFinite(v) ? v : 0;
}

/** Rounds to 2 decimals (what the cards show is 1 decimal). */
function round2(v: number): number {
  return Math.round(v * 100) / 100;
}

/**
 * Applies [delta] to the experience's current aggregate fields. Never goes
 * negative (a drifted aggregate is clamped rather than shown as -1 reviews).
 */
export function applyAggregateDelta(
  current: Record<string, unknown> | null | undefined,
  delta: AggregateDelta,
): RatingAggregate {
  const c = current ?? {};
  const ratingCount = Math.max(0, num(c.ratingCount) + delta.count);
  const ratingSum = ratingCount === 0 ? 0 : Math.max(0, num(c.ratingSum) + delta.sum);
  const curDist = (c.ratingDist && typeof c.ratingDist === 'object')
    ? (c.ratingDist as Record<string, unknown>)
    : {};
  const ratingDist: Record<string, number> = {};
  for (const s of STARS) {
    ratingDist[s] = ratingCount === 0
      ? 0
      : Math.max(0, num(curDist[s]) + (delta.dist[s] ?? 0));
  }
  return {
    ratingSum,
    ratingCount,
    ratingAvg: ratingCount === 0 ? 0 : round2(ratingSum / ratingCount),
    reviewCount: ratingCount,
    ratingDist,
  };
}

/** Recomputes the aggregate from scratch (used by tests and repairs). */
export function aggregateFromReviews(
  reviews: Array<Record<string, unknown>>,
): RatingAggregate {
  let agg = applyAggregateDelta({}, { sum: 0, count: 0, dist: {} });
  for (const r of reviews) agg = applyAggregateDelta(agg as any, computeAggregateDelta(null, r));
  return agg;
}
