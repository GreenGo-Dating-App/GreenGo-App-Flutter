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

// ─────────────────────────────────────────────────────────────── host totals
//
// The host's OVERALL rating across all their experiences lives on
// `profiles/{hostId}`: hostRatingSum, hostRatingCount, hostRatingAvg (all
// server-owned). Invariant: host totals == Σ aggregates of the host's
// experiences that carry `hostRatingCounted: true`.
//  - a review delta is applied to the experience AND (when the experience is
//    counted) to the host, in the same transaction, deduplicated by event id;
//  - deleting an experience subtracts its last aggregate (its reviews are then
//    deleted, but their triggers find the experience gone and change nothing);
//  - `backfillHostRatings` adds an uncounted experience's aggregate and sets
//    the flag in one transaction (exactly once per experience).

export interface HostRatingDelta {
  sum: number;
  count: number;
}

export interface HostRatingTotals {
  hostRatingSum: number;
  hostRatingCount: number;
  hostRatingAvg: number;
}

/** The part of a review delta that moves the host totals. */
export function hostDeltaFromAggregateDelta(d: AggregateDelta): HostRatingDelta {
  return { sum: d.sum, count: d.count };
}

/** What one experience currently contributes to its host's totals. */
export function experienceHostContribution(
  experience: Record<string, unknown> | null | undefined,
): HostRatingDelta {
  const e = experience ?? {};
  const count = Math.max(0, Math.trunc(num(e.ratingCount)));
  const sum = count === 0 ? 0 : Math.max(0, num(e.ratingSum));
  return { sum, count };
}

export function negateHostDelta(d: HostRatingDelta): HostRatingDelta {
  return { sum: d.sum === 0 ? 0 : -d.sum, count: d.count === 0 ? 0 : -d.count };
}

export function isZeroHostDelta(d: HostRatingDelta): boolean {
  return d.sum === 0 && d.count === 0;
}

/**
 * Applies [delta] to the host's current totals (profile fields). Clamped at 0
 * so a drifted total never shows a negative count or average.
 */
export function applyHostRatingDelta(
  profile: Record<string, unknown> | null | undefined,
  delta: HostRatingDelta,
): HostRatingTotals {
  const p = profile ?? {};
  const hostRatingCount = Math.max(0, num(p.hostRatingCount) + delta.count);
  const hostRatingSum = hostRatingCount === 0
    ? 0
    : Math.max(0, num(p.hostRatingSum) + delta.sum);
  return {
    hostRatingSum,
    hostRatingCount,
    hostRatingAvg: hostRatingCount === 0 ? 0 : round2(hostRatingSum / hostRatingCount),
  };
}
