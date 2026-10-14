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
import { EffectiveTier, effectiveTier, hasBaseAccess } from './effectiveTier';

type Cap = number | null;

/** Server-owned per-user usage counters (see entitlements/usage.ts). */
export const USAGE_COLLECTION = 'entitlement_usage';

/**
 * Max ACTIVE events at a time (owner rule 2026-10-14): end date in the future,
 * not cancelled / completed, not hidden by a plan downgrade; a recurring
 * series counts once. Ended or deleted events free their slot. FREE here is
 * Base (no plan cannot create at all: hasBaseAccess). Base events are free
 * only (paid listings need an active business = Silver and up).
 */
export const MAX_EVENTS: Record<EffectiveTier, Cap> = {
  FREE: 1, SILVER: 5, GOLD: 10, PLATINUM: null, TEST: null,
};

/**
 * Max ACTIVE member-hosted experiences at a time: every experience the host
 * has that is not deleted and not hidden by a plan downgrade (drafts count,
 * as before). Deleting one frees the slot. Admins are unlimited.
 */
export const MAX_EXPERIENCES: Record<EffectiveTier, Cap> = {
  FREE: 1, SILVER: 5, GOLD: 10, PLATINUM: null, TEST: null,
};

/** Max groups a user may have created (that still exist). */
export const MAX_GROUPS: Record<EffectiveTier, Cap> = {
  FREE: 1, SILVER: null, GOLD: null, PLATINUM: null, TEST: null,
};

/** New one-to-one conversations a user may START per UTC day. */
export const MAX_DAILY_CONNECTS: Record<EffectiveTier, Cap> = {
  FREE: 10, SILVER: 50, GOLD: 200, PLATINUM: null, TEST: null,
};

/**
 * People an account WITHOUT Base (no plan at all) may chat with per UTC day:
 * a taste of the app (owner rule 2026-10-13). Base and every paid tier chat
 * without this limit; events and experiences stay Base-only.
 * Mirrors TierEntitlements.freeDailyChats and `freeChatOk` in the rules.
 */
export const FREE_DAILY_CHATS = 3;

/**
 * Characters of chat / text translation a user may send to the paid
 * translation API per UTC day, by membership (owner rule 2026-10-13). Stored
 * translations, the cross-chat cache and same-language messages cost nothing
 * and are not counted. A medium user needs about 300 a day; the caps stop the
 * worst case (50,000/day was up to $30 per user per month on Google).
 * Mirrors TierEntitlements.translateCharsPerDay in the app.
 */
export const TRANSLATE_CHARS_DAILY = {
  NONE: 3_000, // no plan (3 free chats a day)
  BASE: 10_000,
  SILVER: 25_000,
  GOLD: 50_000,
  PLATINUM: 100_000,
} as const;

/** The daily translation allowance of a profile (effective tier; TEST = Platinum). */
export function translateCharsDailyLimit(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): number {
  const tier = effectiveTier(profile, now);
  if (tier === 'PLATINUM' || tier === 'TEST') return TRANSLATE_CHARS_DAILY.PLATINUM;
  if (tier === 'GOLD') return TRANSLATE_CHARS_DAILY.GOLD;
  if (tier === 'SILVER') return TRANSLATE_CHARS_DAILY.SILVER;
  return hasBaseAccess(profile, now) ? TRANSLATE_CHARS_DAILY.BASE : TRANSLATE_CHARS_DAILY.NONE;
}

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
