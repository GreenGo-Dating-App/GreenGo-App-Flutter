"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.validRating = validRating;
exports.ratingContribution = ratingContribution;
exports.computeAggregateDelta = computeAggregateDelta;
exports.isZeroDelta = isZeroDelta;
exports.applyAggregateDelta = applyAggregateDelta;
exports.aggregateFromReviews = aggregateFromReviews;
exports.hostDeltaFromAggregateDelta = hostDeltaFromAggregateDelta;
exports.experienceHostContribution = experienceHostContribution;
exports.negateHostDelta = negateHostDelta;
exports.isZeroHostDelta = isZeroHostDelta;
exports.applyHostRatingDelta = applyHostRatingDelta;
const STARS = ['1', '2', '3', '4', '5'];
/** Integer rating 1..5, or null for anything else. */
function validRating(v) {
    if (typeof v !== 'number' || !Number.isInteger(v))
        return null;
    return v >= 1 && v <= 5 ? v : null;
}
/** What one review document contributes to the aggregate. */
function ratingContribution(review) {
    if (!review || review.status !== 'visible')
        return { rating: 0, counted: false };
    const r = validRating(review.rating);
    if (r === null)
        return { rating: 0, counted: false };
    return { rating: r, counted: true };
}
/** Delta between a review's state before and after a write. */
function computeAggregateDelta(before, after) {
    var _a, _b;
    const b = ratingContribution(before);
    const a = ratingContribution(after);
    const dist = {};
    if (b.counted)
        dist[String(b.rating)] = ((_a = dist[String(b.rating)]) !== null && _a !== void 0 ? _a : 0) - 1;
    if (a.counted)
        dist[String(a.rating)] = ((_b = dist[String(a.rating)]) !== null && _b !== void 0 ? _b : 0) + 1;
    for (const k of Object.keys(dist))
        if (dist[k] === 0)
            delete dist[k];
    return {
        sum: (a.counted ? a.rating : 0) - (b.counted ? b.rating : 0),
        count: (a.counted ? 1 : 0) - (b.counted ? 1 : 0),
        dist,
    };
}
function isZeroDelta(d) {
    return d.sum === 0 && d.count === 0 && Object.keys(d.dist).length === 0;
}
function num(v) {
    return typeof v === 'number' && Number.isFinite(v) ? v : 0;
}
/** Rounds to 2 decimals (what the cards show is 1 decimal). */
function round2(v) {
    return Math.round(v * 100) / 100;
}
/**
 * Applies [delta] to the experience's current aggregate fields. Never goes
 * negative (a drifted aggregate is clamped rather than shown as -1 reviews).
 */
function applyAggregateDelta(current, delta) {
    var _a;
    const c = current !== null && current !== void 0 ? current : {};
    const ratingCount = Math.max(0, num(c.ratingCount) + delta.count);
    const ratingSum = ratingCount === 0 ? 0 : Math.max(0, num(c.ratingSum) + delta.sum);
    const curDist = (c.ratingDist && typeof c.ratingDist === 'object')
        ? c.ratingDist
        : {};
    const ratingDist = {};
    for (const s of STARS) {
        ratingDist[s] = ratingCount === 0
            ? 0
            : Math.max(0, num(curDist[s]) + ((_a = delta.dist[s]) !== null && _a !== void 0 ? _a : 0));
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
function aggregateFromReviews(reviews) {
    let agg = applyAggregateDelta({}, { sum: 0, count: 0, dist: {} });
    for (const r of reviews)
        agg = applyAggregateDelta(agg, computeAggregateDelta(null, r));
    return agg;
}
/** The part of a review delta that moves the host totals. */
function hostDeltaFromAggregateDelta(d) {
    return { sum: d.sum, count: d.count };
}
/** What one experience currently contributes to its host's totals. */
function experienceHostContribution(experience) {
    const e = experience !== null && experience !== void 0 ? experience : {};
    const count = Math.max(0, Math.trunc(num(e.ratingCount)));
    const sum = count === 0 ? 0 : Math.max(0, num(e.ratingSum));
    return { sum, count };
}
function negateHostDelta(d) {
    return { sum: d.sum === 0 ? 0 : -d.sum, count: d.count === 0 ? 0 : -d.count };
}
function isZeroHostDelta(d) {
    return d.sum === 0 && d.count === 0;
}
/**
 * Applies [delta] to the host's current totals (profile fields). Clamped at 0
 * so a drifted total never shows a negative count or average.
 */
function applyHostRatingDelta(profile, delta) {
    const p = profile !== null && profile !== void 0 ? profile : {};
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
//# sourceMappingURL=aggregates.js.map