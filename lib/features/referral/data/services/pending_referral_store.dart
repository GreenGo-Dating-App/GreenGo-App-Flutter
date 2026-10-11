import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An invite code captured from an invite link (`/r/{CODE}`), waiting to be
/// redeemed automatically once the new account has finished onboarding.
@immutable
class PendingReferral {
  const PendingReferral(this.code, this.capturedAt);

  final String code;
  final DateTime capturedAt;
}

/// Local (per device) storage of the pending invite code.
///
/// The keys are shared with the `/r/{CODE}` web page rendered by the
/// `sharePreview` function (functions/src/share/referralPreviewCore.ts), which
/// writes them into localStorage for web sign-ups on the same origin:
/// shared_preferences on web stores `flutter.<key>` with JSON values.
class PendingReferralStore {
  PendingReferralStore({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const String codeKey = 'pending_referral_code';
  static const String capturedAtKey = 'pending_referral_at';

  /// A link older than this is ignored (the server only lets accounts created
  /// within 30 days redeem anyway).
  static const Duration maxAge = Duration(days: 30);

  static final RegExp _codePattern = RegExp(r'^[A-Z0-9]{4,16}$');

  final DateTime Function() _clock;

  /// Normalized code (trimmed, upper case) or null when malformed.
  static String? normalize(String? raw) {
    final code = raw?.trim().toUpperCase() ?? '';
    return _codePattern.hasMatch(code) ? code : null;
  }

  /// Stores [rawCode] (the latest link wins). Malformed codes are ignored.
  Future<bool> save(String rawCode) async {
    final code = normalize(rawCode);
    if (code == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(codeKey, code);
      await prefs.setInt(capturedAtKey, _clock().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      debugPrint('PendingReferralStore.save failed: $e');
      return false;
    }
  }

  /// The pending code, or null when there is none, it is malformed or it has
  /// expired (an expired code is removed).
  Future<PendingReferral?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = normalize(prefs.getString(codeKey));
      final at = prefs.get(capturedAtKey);
      final ms = at is int ? at : (at is double ? at.toInt() : null);
      if (code == null || ms == null) {
        if (prefs.containsKey(codeKey)) await clear();
        return null;
      }
      final capturedAt = DateTime.fromMillisecondsSinceEpoch(ms);
      if (_clock().difference(capturedAt) > maxAge) {
        await clear();
        return null;
      }
      return PendingReferral(code, capturedAt);
    } catch (e) {
      debugPrint('PendingReferralStore.read failed: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(codeKey);
      await prefs.remove(capturedAtKey);
    } catch (e) {
      debugPrint('PendingReferralStore.clear failed: $e');
    }
  }
}
