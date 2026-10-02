/** Pure helpers of setExperienceFeatured (no Firebase imports: unit-testable). */

export const FEATURE_MAX_DAYS = 30;

/** Pure: the featured fields for [days] (0 = unfeature), or an error code. */
export function featuredPatch(
  days: unknown,
  nowMs: number,
): { isFeatured: boolean; featuredUntilMs: number | null } | { error: string } {
  if (typeof days !== 'number' || !Number.isInteger(days) || days < 0 || days > FEATURE_MAX_DAYS) {
    return { error: 'invalid_days' };
  }
  if (days === 0) return { isFeatured: false, featuredUntilMs: null };
  return { isFeatured: true, featuredUntilMs: nowMs + days * 24 * 60 * 60 * 1000 };
}
