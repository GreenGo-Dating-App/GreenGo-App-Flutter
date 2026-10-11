/// Reads the SERVER-owned usage counters behind the membership caps:
/// `entitlement_usage/{uid}` (written only by Cloud Functions -
/// functions/src/entitlements/usage.ts and spendCoins - and read by the
/// Firestore rules that refuse an over-cap create). The app shows the same
/// numbers the server enforces.
///
/// Windows are UTC, like the server: connects per UTC day, free boosts per
/// UTC calendar month.
library;

const String kEntitlementUsageCollection = 'entitlement_usage';

const int _dayMs = 86400000;

/// Start of the UTC day of [now], in epoch millis.
int utcDayStartMs(DateTime now) =>
    (now.toUtc().millisecondsSinceEpoch ~/ _dayMs) * _dayMs;

/// UTC calendar month key, e.g. "2026-10".
String utcMonthKey(DateTime now) {
  final u = now.toUtc();
  return '${u.year}-${u.month.toString().padLeft(2, '0')}';
}

int _int(Object? v) => v is num ? v.toInt() : 0;

/// New one-to-one conversations started today (UTC).
int connectsTodayFrom(Map<String, dynamic>? usage, DateTime now) {
  if (usage == null) return 0;
  return _int(usage['connectDayStartMs']) == utcDayStartMs(now)
      ? _int(usage['connectCount'])
      : 0;
}

/// Free boosts already used this (UTC) month.
int freeBoostsUsedFrom(Map<String, dynamic>? usage, DateTime now) {
  if (usage == null) return 0;
  return usage['boostMonth'] == utcMonthKey(now) ? _int(usage['boostsUsed']) : 0;
}

/// Ongoing event slots (a recurring series is one) at [now].
int ongoingEventSlotsFrom(Map<String, dynamic>? usage, DateTime now) {
  final ends = usage?['eventActiveEnds'];
  if (ends is! List) return 0;
  final nowMs = now.millisecondsSinceEpoch;
  return ends.where((e) => e is num && e > nowMs).length;
}

/// Paid extra events (coins) not used yet.
int extraEventCreditsLeftFrom(Map<String, dynamic>? usage) {
  if (usage == null) return 0;
  final left = _int(usage['eventExtraCredits']) - _int(usage['eventExtraUsed']);
  return left > 0 ? left : 0;
}

/// Groups this user created that still exist.
int groupsCreatedFrom(Map<String, dynamic>? usage) =>
    _int(usage?['groupsCreated']);
