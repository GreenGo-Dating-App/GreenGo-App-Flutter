/// ISO-8601 week key + weekly-XP bookkeeping for the weekly leaderboard.
///
/// MUST stay byte-for-byte equivalent to `functions/src/gamification/weekKey.ts`
/// — both are checked against the same fixture file
/// (`test/unit/gamification/fixtures/iso_week_keys.json`).
///
/// Every XP writer keeps two fields on `user_levels/{uid}`:
///   * `weekKey`  — ISO week of the last grant, computed in UTC ("2026-W40")
///   * `weeklyXP` — XP earned in that week
/// When the stored `weekKey` differs from the current one the counter restarts
/// at the grant amount, otherwise it is incremented. Callers apply the result
/// inside the same transaction that bumps `totalXP`, so it is atomic.
library;

/// ISO-8601 week key ("YYYY-Www") of [instant], evaluated in UTC.
///
/// Weeks start on Monday; week 1 is the week containing the year's first
/// Thursday, so e.g. 2027-01-01 (a Friday) is "2026-W53".
String isoWeekKey(DateTime instant) {
  final utc = instant.toUtc();
  final day = DateTime.utc(utc.year, utc.month, utc.day);
  // Thursday of the same ISO week decides the ISO year.
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final isoYear = thursday.year;
  final dayOfYear =
      thursday.difference(DateTime.utc(isoYear)).inDays; // 0-based
  final week = dayOfYear ~/ 7 + 1;
  return '$isoYear-W${week.toString().padLeft(2, '0')}';
}

/// ISO week key of "now" in UTC.
String currentIsoWeekKey() => isoWeekKey(DateTime.now().toUtc());

/// The `weekKey` / `weeklyXP` fields to write when granting [xp] to a user
/// whose current `user_levels` data is [existing] (null if no doc yet).
Map<String, dynamic> weeklyXpFields(
  Map<String, dynamic>? existing,
  int xp, {
  DateTime? now,
}) {
  final key = isoWeekKey(now ?? DateTime.now().toUtc());
  final storedKey = existing?['weekKey'];
  final storedXp = (existing?['weeklyXP'] as num?)?.toInt() ?? 0;
  return {
    'weekKey': key,
    'weeklyXP': storedKey == key ? storedXp + xp : xp,
  };
}
