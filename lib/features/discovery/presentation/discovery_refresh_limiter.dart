import 'package:shared_preferences/shared_preferences.dart';

/// Caps MANUAL pull-to-refreshes of the Discovery grid per user per local
/// calendar day (owner rule 2026-10-14: 10 a day). A Discovery reload reads
/// 500-2,500 Firestore documents, so the cap keeps the cost per user bounded.
/// Automatic loads (opening the tab, changing filters, scrolling for more)
/// are not counted.
///
/// The count lives on the device (SharedPreferences, one key per user and
/// day, older days removed); it is a cost guard, not a security boundary.
class DiscoveryRefreshLimiter {
  DiscoveryRefreshLimiter({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const int dailyLimit = 10;
  static const String _prefix = 'discovery_refresh_';

  final DateTime Function() _clock;

  String _dayKey(String uid) {
    final d = _clock();
    final day = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '$_prefix${uid}_$day';
  }

  /// Refreshes still allowed today (0..[dailyLimit]).
  Future<int> remaining(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_dayKey(uid)) ?? 0;
    return (dailyLimit - used).clamp(0, dailyLimit);
  }

  /// Uses one refresh. Returns the refreshes left AFTER this one, or null
  /// when today's limit is already reached (nothing is used).
  Future<int?> tryConsume(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey(uid);
    final used = prefs.getInt(key) ?? 0;
    if (used >= dailyLimit) return null;
    await prefs.setInt(key, used + 1);
    // Drop this user's counters from earlier days.
    for (final k in prefs.getKeys().where((k) => k.startsWith('$_prefix${uid}_') && k != key).toList()) {
      await prefs.remove(k);
    }
    return dailyLimit - used - 1;
  }
}
