import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local, single-slot store for a REFERRAL code the user typed on the
/// registration screen before their account existed.
///
/// The code is captured at signup and redeemed later — after the account exists
/// AND onboarding completes — by the secure `redeemReferral` Cloud Function,
/// which grants the referrer +100 coins (capped at 1000/month) and gives the new
/// user 1 month of Platinum. Cleared on success or a terminal rejection.
class PendingSignupReferral {
  static const String _key = 'pending_signup_referral_code';

  /// Persist a normalized (trimmed, uppercase) referral code. No-op if blank.
  static Future<void> setPending(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, normalized);
  }

  static Future<String?> getPending() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == null || code.trim().isEmpty) return null;
    return code;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Redeems the pending referral code (if any) for [userId] via the secure
  /// `redeemReferral` callable. Safe to call repeatedly — the server enforces
  /// one-redemption-per-user and the monthly cap. Never throws.
  ///
  /// Clears the code on a terminal outcome (redeemed, or a permanent rejection
  /// such as self-referral / already-redeemed / unknown code). Keeps it on a
  /// transient error so a later launch-time retry can try again.
  static Future<void> tryRedeemPending(String userId) async {
    final code = await getPending();
    if (code == null) return;
    try {
      await FirebaseFunctions.instance
          .httpsCallable('redeemReferral')
          .call<dynamic>({'code': code});
      await clear();
    } on FirebaseFunctionsException catch (e) {
      // Permanent rejections → stop retrying. Transient (unavailable/internal)
      // → keep the code for the launch-time retry.
      const terminal = {
        'invalid-argument',
        'not-found',
        'failed-precondition',
        'already-exists',
        'permission-denied',
      };
      if (terminal.contains(e.code)) {
        await clear();
      }
    } catch (_) {
      // Unknown/transient — keep for retry.
    }
  }
}
