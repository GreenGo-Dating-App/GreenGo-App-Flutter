import 'package:shared_preferences/shared_preferences.dart';

/// Enforces the "update your location at most once per month" rule for the
/// web build. The timestamp is stored per user in SharedPreferences
/// (localStorage on web), so switching accounts in the same browser is tracked
/// independently.
class WebLocationLimit {
  WebLocationLimit._();

  static const Duration window = Duration(days: 30);
  static String _key(String userId) => 'web_location_updated_at_$userId';

  /// Timestamp of the last web location update for [userId], or null if never.
  static Future<DateTime?> lastUpdated(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Whether [userId] may update their location on web right now.
  static Future<bool> canUpdate(String userId) async {
    final last = await lastUpdated(userId);
    if (last == null) return true;
    return DateTime.now().difference(last) >= window;
  }

  /// The earliest date [userId] may update again, or null if they can now.
  static Future<DateTime?> nextAllowed(String userId) async {
    final last = await lastUpdated(userId);
    if (last == null) return null;
    final next = last.add(window);
    return next.isAfter(DateTime.now()) ? next : null;
  }

  /// Record that [userId] just updated their location on web.
  static Future<void> markUpdated(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), DateTime.now().toIso8601String());
  }
}
