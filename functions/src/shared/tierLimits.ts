/**
 * Server mirror of the app's per-tier caps (lib/core/services/tier_entitlements.dart,
 * TierEntitlements). The app shows these numbers; the server and the Firestore
 * rules enforce them. `null` = unlimited.
 *
 * __tests__/unit/tierLimits.test.ts parses tier_entitlements.dart and fails
 * when the two tables drift, and the same numbers are written into
 * firestore.rules / firestore.additive.rules (`tierCap*` helpers).
 *
 * Every lookup takes the EFFECTIVE tier (shared/effectiveTier.ts): an expired
 * paid tier is FREE, TEST is Platinum.
 */
import { EffectiveTier } from './effectiveTier';

type Cap = number | null;

/** Server-owned per-user usage counters (see entitlements/usage.ts). */
export const USAGE_COLLECTION = 'entitlement_usage';

/** Max ONGOING events (end date in the future; a recurring series counts once). */
export const MAX_EVENTS: Record<EffectiveTier, Cap> = {
  FREE: 1, SILVER: 3, GOLD: 5, PLATINUM: null, TEST: null,
};

/** Max groups a user may have created (that still exist). */
export const MAX_GROUPS: Record<EffectiveTier, Cap> = {
  FREE: 1, SILVER: null, GOLD: null, PLATINUM: null, TEST: null,
};

/** New one-to-one conversations a user may START per UTC day. */
export const MAX_DAILY_CONNECTS: Record<EffectiveTier, Cap> = {
  FREE: 10, SILVER: 50, GOLD: 200, PLATINUM: null, TEST: null,
};

/** FREE profile boosts per calendar month (UTC). Extra boosts cost coins. */
export const FREE_BOOSTS_PER_MONTH: Record<EffectiveTier, number> = {
  FREE: 0, SILVER: 1, GOLD: 4, PLATINUM: 30, TEST: 30,
};

/** Tiers whose support tickets are handled first (priority support). */
export function hasPrioritySupport(tier: EffectiveTier): boolean {
  return tier === 'GOLD' || tier === 'PLATINUM' || tier === 'TEST';
}

/** Travel mode: Silver and up (Platinum free, the others pay per day). */
export function travelModeEnabled(tier: EffectiveTier): boolean {
  return tier !== 'FREE';
}

/** Travel mode without the daily coin price. */
export function travelModeFree(tier: EffectiveTier): boolean {
  return tier === 'PLATINUM' || tier === 'TEST';
}

/** Smart replies / word breakdown (AI chat helpers): Silver and up. */
export function aiChatHelpersEnabled(tier: EffectiveTier): boolean {
  return tier !== 'FREE';
}

/** Support-queue priority stored on support_chats (`priority`, `priorityRank`). */
export function supportPriorityFor(tier: EffectiveTier): { priority: 'high' | 'normal'; priorityRank: number } {
  return hasPrioritySupport(tier)
    ? { priority: 'high', priorityRank: 2 }
    : { priority: 'normal', priorityRank: 1 };
}

/** UTC calendar month key, e.g. "2026-10" (free-boost allowance window). */
export function monthKeyUtc(d: Date): string {
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}

/** Start of the UTC day of `ms`, in epoch millis (daily-connect window). */
export function utcDayStartMs(ms: number): number {
  return Math.floor(ms / 86_400_000) * 86_400_000;
}
