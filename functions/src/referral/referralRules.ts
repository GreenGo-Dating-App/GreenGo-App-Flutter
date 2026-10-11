/**
 * Invite-friends programme: the rules, as pure data + pure functions (no IO),
 * so the callable, the backfill script and the tests share ONE definition.
 *
 * Mirrored for display by lib/features/referral/data/services/referral_service.dart
 * (the server stays the source of truth).
 *
 *  - The INVITED user (a new account redeeming a code) gets 1 week of BASE
 *    membership (the separate hasBaseMembership flag, not a tier).
 *  - The INVITER earns REFERRER_COIN_REWARD coins per successful invitation,
 *    capped at REFERRER_MONTHLY_CAP coins per calendar month (UTC). Every
 *    invitation counts toward the milestones, capped or not.
 *  - Lifetime milestones (each granted once): 5 -> 1 month SILVER,
 *    10 -> 1 month GOLD, 20 -> 1 month PLATINUM.
 */

import type { TierName } from '../shared/grants';

export const DAY_MS = 24 * 60 * 60 * 1000;

/** 1 week of Base membership for the invited user. */
export const INVITEE_BASE_DURATION_MS = 7 * DAY_MS;

/** Coins the inviter earns per successful invitation. */
export const REFERRER_COIN_REWARD = 50;

/** Monthly (calendar month, UTC) cap on referral coins for one inviter. */
export const REFERRER_MONTHLY_CAP = 1000;

/** "1 month" everywhere in membership grants (same constant as before). */
export const MILESTONE_DURATION_MS = 30 * DAY_MS;

export interface ReferralMilestone {
  /** Lifetime successful invitations needed. */
  count: number;
  tier: TierName;
  durationMs: number;
}

/** Ascending by count. */
export const REFERRAL_MILESTONES: readonly ReferralMilestone[] = [
  { count: 5, tier: 'SILVER', durationMs: MILESTONE_DURATION_MS },
  { count: 10, tier: 'GOLD', durationMs: MILESTONE_DURATION_MS },
  { count: 20, tier: 'PLATINUM', durationMs: MILESTONE_DURATION_MS },
];

/** `yyyymm` (UTC) of [now] - the key of referralMonthlyGrants/{ownerId}_{yyyymm}. */
export function referralPeriod(now: Date): string {
  return `${now.getUTCFullYear()}${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
}

/**
 * Coins to award for one more invitation when [alreadyThisMonth] coins were
 * already paid this month: the full reward, or 0 once the cap would be
 * exceeded (never a partial payment).
 */
export function referralCoinsFor(alreadyThisMonth: number): number {
  const already = Number.isFinite(alreadyThisMonth) && alreadyThisMonth > 0 ? alreadyThisMonth : 0;
  return already + REFERRER_COIN_REWARD <= REFERRER_MONTHLY_CAP ? REFERRER_COIN_REWARD : 0;
}

/** Sanitises a stored `milestonesGranted` value into a set of counts. */
export function grantedSet(value: unknown): Set<number> {
  const out = new Set<number>();
  if (Array.isArray(value)) {
    for (const v of value) {
      if (typeof v === 'number' && Number.isInteger(v)) out.add(v);
    }
  }
  return out;
}

/**
 * Milestones to grant NOW for an inviter whose lifetime count is [count] and
 * who already received [alreadyGranted]. Every milestone whose threshold is
 * reached and that was not granted yet is returned (ascending), so a skipped
 * count (e.g. the backfill jumping from 0 to 12) grants each one once.
 */
export function milestonesToGrant(count: number, alreadyGranted: Iterable<number>): ReferralMilestone[] {
  const done = new Set<number>(alreadyGranted);
  const n = Number.isFinite(count) ? count : 0;
  return REFERRAL_MILESTONES.filter((m) => n >= m.count && !done.has(m.count));
}

/** The next milestone not reached yet, or null when all are reached. */
export function nextMilestone(count: number): ReferralMilestone | null {
  return REFERRAL_MILESTONES.find((m) => count < m.count) ?? null;
}

/** Brand name of a tier for notification texts ("GOLD" -> "Gold"; not translated). */
export function tierLabel(tier: string): string {
  const v = String(tier || '').toLowerCase();
  return v ? v[0].toUpperCase() + v.slice(1) : v;
}
