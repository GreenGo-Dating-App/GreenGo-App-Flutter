/**
 * THE single server-side rule for "which membership tier is this user entitled
 * to right now". Mirrors the client's `lib/core/services/effective_tier.dart`.
 *
 * Source of truth is `profiles/{uid}`:
 *   - `membershipTier`    'PLATINUM' | 'GOLD' | 'SILVER' | 'BASIC' | 'FREE' | 'TEST'
 *   - `membershipEndDate` when the paid tier stops
 *   - `hasBaseMembership` + `baseMembershipEndDate`: the SEPARATE Base plan
 *
 * Mirrors (`users/{uid}.subscriptionTier`, `memberships/*`, `subscriptions/*`)
 * drift, and `memberships/*` is client-writable, so NO server decision may be
 * based on them.
 *
 * Rules:
 *   - TEST stays TEST (internal testers).
 *   - Admins (`profiles.isAdmin === true`, which the rules forbid the owner to
 *     set) keep their stored SILVER/GOLD/PLATINUM regardless of end date.
 *   - SILVER / GOLD / PLATINUM are active only while `membershipEndDate` is
 *     after `now`. A MISSING end date means NOT active: no server writer grants
 *     a paid tier without an end date (audited: grants.ts, redeemCoupon.ts,
 *     applySignupGrants.ts, redeemReferral.ts, grantEntitlement.ts,
 *     stripeCheckout.ts, subscription/index.ts, storeNotifications.ts all
 *     write one). There is deliberately no "lifetime" flag: any new profile
 *     field would be client-writable under the current profile rules.
 *   - 'BASIC' / 'BASE' / 'FREE' / unknown → FREE. Base is tracked by
 *     [isBaseMembershipActive], never by the tier.
 */

import * as admin from 'firebase-admin';

export type EffectiveTier = 'FREE' | 'SILVER' | 'GOLD' | 'PLATINUM' | 'TEST';
export type PaidTier = 'SILVER' | 'GOLD' | 'PLATINUM';

export const PAID_TIERS: readonly PaidTier[] = ['SILVER', 'GOLD', 'PLATINUM'];

/** Stored spellings that mean a paid tier (queries must match raw values). */
export const PAID_TIER_STORED_VALUES: readonly string[] = [
  'SILVER', 'GOLD', 'PLATINUM', 'silver', 'gold', 'platinum',
];

/** Stored spellings of the legacy 'BASIC' tier (read by the client as SILVER). */
export const LEGACY_BASIC_STORED_VALUES: readonly string[] = ['BASIC', 'basic', 'BASE', 'base'];

/** Rank used for "never downgrade an active higher tier". FREE/TEST = 0. */
export const EFFECTIVE_TIER_RANK: Record<string, number> = {
  FREE: 0,
  SILVER: 1,
  GOLD: 2,
  PLATINUM: 3,
};

/** Base-membership product ids (canonical, iOS-prefixed). */
export const BASE_PRODUCT_IDS: readonly string[] = [
  'greengo_base_membership',
  'subscription_greengo_base_membership',
];

/** `users/{uid}.subscriptionTier` value written when a paid tier ends. */
export const USERS_FREE_TIER = 'free';

export function isPaidTier(tier: unknown): tier is PaidTier {
  return typeof tier === 'string' && (PAID_TIERS as readonly string[]).includes(tier.toUpperCase());
}

/** Normalises a stored tier string to its canonical upper-case form. */
export function normalizeStoredTier(raw: unknown): EffectiveTier | 'BASIC' {
  const v = typeof raw === 'string' ? raw.trim().toUpperCase() : '';
  switch (v) {
    case 'SILVER':
    case 'GOLD':
    case 'PLATINUM':
    case 'TEST':
      return v;
    case 'BASIC':
    case 'BASE':
      return 'BASIC';
    default:
      return 'FREE';
  }
}

/** Firestore value (Timestamp / Date / millis / ISO string / {_seconds}) → Date. */
export function tierDateFromValue(v: unknown): Date | null {
  if (v === null || v === undefined) return null;
  if (v instanceof admin.firestore.Timestamp) return v.toDate();
  if (v instanceof Date) return isNaN(v.getTime()) ? null : v;
  if (typeof v === 'number') return new Date(v);
  if (typeof v === 'string') {
    const d = new Date(v);
    return isNaN(d.getTime()) ? null : d;
  }
  if (typeof v === 'object') {
    const o = v as any;
    if (typeof o.toDate === 'function') return o.toDate();
    const secs = o._seconds ?? o.seconds;
    if (typeof secs === 'number') return new Date(secs * 1000);
  }
  return null;
}

export function isProfileAdmin(profile: Record<string, any> | null | undefined): boolean {
  return profile?.isAdmin === true;
}

/** The tier `profile` is entitled to at `now`. See the file header for the rules. */
export function effectiveTier(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): EffectiveTier {
  if (!profile) return 'FREE';
  const stored = normalizeStoredTier(profile.membershipTier);
  if (stored === 'TEST') return 'TEST';
  if (stored === 'FREE' || stored === 'BASIC') return 'FREE';
  if (isProfileAdmin(profile)) return stored;
  const end = tierDateFromValue(profile.membershipEndDate);
  if (!end) return 'FREE';
  return end.getTime() > now.getTime() ? stored : 'FREE';
}

/** True when `profile` currently holds an ACTIVE SILVER/GOLD/PLATINUM with a future end date. */
export function hasActivePaidTier(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): boolean {
  if (!profile) return false;
  const stored = normalizeStoredTier(profile.membershipTier);
  if (!isPaidTier(stored)) return false;
  const end = tierDateFromValue(profile.membershipEndDate);
  return !!end && end.getTime() > now.getTime();
}

/** Base membership: `hasBaseMembership` AND a future `baseMembershipEndDate`. */
export function isBaseMembershipActive(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): boolean {
  if (!profile || profile.hasBaseMembership !== true) return false;
  const end = tierDateFromValue(profile.baseMembershipEndDate);
  return !!end && end.getTime() > now.getTime();
}

export function tierRank(tier: unknown): number {
  const t = typeof tier === 'string' ? tier.toUpperCase() : '';
  return EFFECTIVE_TIER_RANK[t] ?? 0;
}

export function isBaseProductId(productId: unknown): boolean {
  return typeof productId === 'string' && BASE_PRODUCT_IDS.includes(productId);
}
