/**
 * ISO-8601 week key + weekly-XP bookkeeping for the weekly leaderboard.
 *
 * MUST stay equivalent to `lib/features/gamification/domain/utils/week_key.dart`
 * — both are checked against the same fixture file
 * (`test/unit/gamification/fixtures/iso_week_keys.json` in the app repo root).
 *
 * Every XP writer keeps on `user_levels/{uid}`:
 *   weekKey  — ISO week of the last grant, computed in UTC ("2026-W40")
 *   weeklyXP — XP earned in that week (restarts at the grant amount when the
 *              stored weekKey differs from the current one)
 * Callers apply the result inside the transaction that bumps totalXP.
 */

const DAY_MS = 24 * 60 * 60 * 1000;

/** ISO-8601 week key ("YYYY-Www") of `instant`, evaluated in UTC. */
export function isoWeekKey(instant: Date): string {
  const day = Date.UTC(
    instant.getUTCFullYear(),
    instant.getUTCMonth(),
    instant.getUTCDate(),
  );
  // ISO weekday: Monday=1 .. Sunday=7.
  const weekday = new Date(day).getUTCDay() || 7;
  // Thursday of the same ISO week decides the ISO year.
  const thursday = new Date(day + (4 - weekday) * DAY_MS);
  const isoYear = thursday.getUTCFullYear();
  const dayOfYear = Math.round(
    (thursday.getTime() - Date.UTC(isoYear, 0, 1)) / DAY_MS,
  ); // 0-based
  const week = Math.floor(dayOfYear / 7) + 1;
  return `${isoYear}-W${String(week).padStart(2, '0')}`;
}

/** ISO week key of "now" (UTC). */
export function currentIsoWeekKey(): string {
  return isoWeekKey(new Date());
}

/**
 * The `weekKey` / `weeklyXP` fields to write when granting `xp` to a user
 * whose current level data is `existing` (undefined if no doc yet).
 */
export function weeklyXpFields(
  existing: { weekKey?: unknown; weeklyXP?: unknown } | undefined | null,
  xp: number,
  now: Date = new Date(),
): { weekKey: string; weeklyXP: number } {
  const key = isoWeekKey(now);
  const storedXp =
    typeof existing?.weeklyXP === 'number' ? existing.weeklyXP : 0;
  return {
    weekKey: key,
    weeklyXP: existing?.weekKey === key ? storedXp + xp : xp,
  };
}
