/**
 * Private follow counts (owner rule 2026-10-17): "followers and following are
 * visible only on the profile page as information for the user, not to let
 * people know the followers of a user" - for users AND businesses.
 *
 * Since this change the follow triggers write the counters ONLY to the
 * owner-only `follow_counts/{uid}` (followCounters.ts). The public
 * `profiles/{uid}` of existing accounts still carries the legacy values, and
 * from the deploy on the private doc holds only the changes made since then.
 * scripts/move-follow-counts-private.ts uses [planFollowCountMove] to fold
 * the public value INTO the private one and delete the public fields in ONE
 * transaction, so each public value is added exactly once (a re-run finds
 * nothing left to move).
 *
 * Pure: no Firestore import, unit-tested in __tests__/followCountsPrivacy.
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

/** Server counters that move to `follow_counts/{uid}`. */
export const PRIVATE_FOLLOW_COUNTER_FIELDS = ['followersCount', 'followingCount'] as const;

/**
 * Public fields removed from `profiles/{uid}`: the two server counters plus
 * the legacy client-written `followerCount` (old app versions' business
 * follow; not trustworthy, so it is dropped, not copied).
 */
export const PUBLIC_FOLLOW_COUNT_FIELDS = [
  ...PRIVATE_FOLLOW_COUNTER_FIELDS,
  'followerCount',
] as const;

export interface FollowCountMove {
  /** merge-set for `follow_counts/{uid}` (empty = nothing to write). */
  privateSet: Record<string, number>;
  /** Public fields to delete (empty = nothing to do). */
  publicDelete: string[];
}

function num(v: unknown): number {
  return typeof v === 'number' && Number.isFinite(v) ? v : 0;
}

/**
 * What to do for one account. [pub] = the public profile data, [priv] = the
 * current `follow_counts/{uid}` data (undefined when missing). The private
 * result is public + private (the private doc only holds post-deploy
 * deltas), clamped at 0 and floored.
 */
export function planFollowCountMove(
  pub: Record<string, any> | undefined,
  priv: Record<string, any> | undefined,
): FollowCountMove {
  const publicDelete = PUBLIC_FOLLOW_COUNT_FIELDS.filter((f) => pub?.[f] !== undefined);
  const privateSet: Record<string, number> = {};
  for (const f of PRIVATE_FOLLOW_COUNTER_FIELDS) {
    if (pub?.[f] === undefined) continue;
    privateSet[f] = Math.max(0, Math.floor(num(pub[f]) + num(priv?.[f])));
  }
  return { privateSet, publicDelete };
}
