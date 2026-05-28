/**
 * Multi-grant coupon types and normalisation helper.
 *
 * A coupon can carry an array of independent grants — e.g. coins + base
 * membership + a tier — so a single promo bundle can deliver multiple
 * entitlements in one redemption. Legacy single-type coupons (no `grants`
 * field) are normalised to a one-element grant list by `effectiveGrants`,
 * so the rest of the codebase only deals with the array shape.
 *
 * Distinct from `../shared/grants.ts`, which holds the helpers that
 * actually apply a grant to a profile / coin balance.
 */

import { TierName, TIER_RANK } from '../shared/grants';

export type GrantKind = 'coins' | 'membership' | 'base_membership';

export const VALID_DURATIONS_DAYS = [7, 14, 30, 60, 90, 180, 365] as const;
export type GrantDurationDays = typeof VALID_DURATIONS_DAYS[number];

export interface Grant {
  kind: GrantKind;
  tier?: TierName;          // membership only
  durationDays?: number;    // membership / base_membership only
  coinAmount?: number;      // coins only
}

/** Throws a descriptive Error if the grant is malformed. */
export function validateGrant(g: Grant, index = 0): void {
  const prefix = `grants[${index}]`;
  if (!g || typeof g !== 'object') {
    throw new Error(`${prefix}: must be an object`);
  }
  if (g.kind !== 'coins' && g.kind !== 'membership' && g.kind !== 'base_membership') {
    throw new Error(`${prefix}.kind: must be one of coins / membership / base_membership`);
  }
  if (g.kind === 'membership') {
    if (!g.tier || !(g.tier in TIER_RANK)) {
      throw new Error(`${prefix}.tier: membership grant requires a valid tier`);
    }
    if (
      typeof g.durationDays !== 'number' ||
      !VALID_DURATIONS_DAYS.includes(g.durationDays as GrantDurationDays)
    ) {
      throw new Error(
        `${prefix}.durationDays: must be one of ${VALID_DURATIONS_DAYS.join(', ')}`,
      );
    }
  } else if (g.kind === 'base_membership') {
    if (
      typeof g.durationDays !== 'number' ||
      !VALID_DURATIONS_DAYS.includes(g.durationDays as GrantDurationDays)
    ) {
      throw new Error(
        `${prefix}.durationDays: must be one of ${VALID_DURATIONS_DAYS.join(', ')}`,
      );
    }
  } else if (g.kind === 'coins') {
    if (typeof g.coinAmount !== 'number' || g.coinAmount <= 0) {
      throw new Error(`${prefix}.coinAmount: coin grant requires a positive amount`);
    }
  }
}

/**
 * Returns the grants this coupon should apply.
 * - If `coupon.grants` is a non-empty array, use it as-is.
 * - Otherwise build a one-element grant from the legacy fields so the
 *   loop in callers works uniformly.
 *
 * Accepts the raw Firestore doc data — callers pass `couponSnap.data()`.
 */
export function effectiveGrants(coupon: any): Grant[] {
  if (Array.isArray(coupon?.grants) && coupon.grants.length > 0) {
    return coupon.grants as Grant[];
  }
  // Legacy fallback
  const type = coupon?.type as GrantKind | undefined;
  if (type === 'membership') {
    return [
      {
        kind: 'membership',
        tier: coupon.tier as TierName,
        durationDays: Number(coupon.durationDays) || 0,
      },
    ];
  }
  if (type === 'base_membership') {
    return [
      {
        kind: 'base_membership',
        durationDays: Number(coupon.durationDays) || 0,
      },
    ];
  }
  if (type === 'coins') {
    return [
      {
        kind: 'coins',
        coinAmount: Number(coupon.coinAmount) || 0,
      },
    ];
  }
  return [];
}

/** True if the coupon's effective grants include at least one base_membership entry. */
export function hasBaseGrant(coupon: any): boolean {
  return effectiveGrants(coupon).some((g) => g.kind === 'base_membership');
}

/** Builds a human-readable summary like "GOLD +30d · BASE +90d · +500 coins". */
export function summariseGrants(grants: Grant[]): string {
  const parts: string[] = [];
  for (const g of grants) {
    if (g.kind === 'membership') {
      parts.push(`${g.tier} +${g.durationDays}d`);
    } else if (g.kind === 'base_membership') {
      parts.push(`BASE +${g.durationDays}d`);
    } else if (g.kind === 'coins') {
      parts.push(`+${g.coinAmount} coins`);
    }
  }
  return parts.join(' · ');
}
