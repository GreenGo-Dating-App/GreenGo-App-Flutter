import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'membership_remote_datasource.dart';

/// Local, single-slot store for a coupon code the user typed on the
/// registration screen *before* an account existed.
///
/// The code is captured at signup and redeemed later — once the account is
/// created and (importantly) after the welcome-coins balance doc has been
/// written, so the coupon's coin batch is appended rather than clobbered.
/// Cleared on success or on a terminal validation failure.
class PendingSignupCoupon {
  static const String _key = 'pending_signup_coupon_code';

  /// Persist a normalized (trimmed, uppercase) coupon code. No-op if blank.
  static Future<void> setPending(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, normalized);
  }

  /// Returns the pending code, or null if none is stored.
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
}

/// Result of attempting to redeem the pending signup coupon.
sealed class SignupCouponOutcome extends Equatable {
  const SignupCouponOutcome();
  @override
  List<Object?> get props => [];
}

/// No coupon was pending — nothing to do.
class SignupCouponNothing extends SignupCouponOutcome {
  const SignupCouponNothing();
}

/// The coupon was redeemed; [grantSummary] describes the items granted.
class SignupCouponApplied extends SignupCouponOutcome {
  final String grantSummary;
  const SignupCouponApplied(this.grantSummary);
  @override
  List<Object?> get props => [grantSummary];
}

/// The coupon was rejected for a terminal reason (invalid / expired / etc).
/// The pending code has been cleared.
class SignupCouponRejected extends SignupCouponOutcome {
  final CouponFailure failure;
  const SignupCouponRejected(this.failure);
  @override
  List<Object?> get props => [failure.runtimeType, failure.message];
}

/// A transient error occurred (e.g. network) — the code was kept for a later
/// retry and no user-facing error should be shown.
class SignupCouponDeferred extends SignupCouponOutcome {
  const SignupCouponDeferred();
}

/// Redeems the pending signup coupon (if any) for the given user via the
/// existing secure `redeemCoupon` callable.
class SignupCouponService {
  final MembershipRemoteDataSource _membership;

  SignupCouponService({MembershipRemoteDataSource? membership})
      : _membership = membership ??
            MembershipRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);

  /// Attempts redemption. Safe to call repeatedly: it no-ops when nothing is
  /// pending, and the server enforces one-redemption-per-user.
  Future<SignupCouponOutcome> tryRedeemPending(String userId) async {
    final code = await PendingSignupCoupon.getPending();
    if (code == null) return const SignupCouponNothing();

    try {
      final result = await _membership.redeemCouponCode(
        userId: userId,
        couponCode: code,
      );
      await PendingSignupCoupon.clear();
      return SignupCouponApplied(result.grantSummary);
    } on CouponGenericFailure {
      // Unknown / likely transient (network, internal). Keep the code so the
      // launch-time retry can try again later.
      return const SignupCouponDeferred();
    } on CouponFailure catch (failure) {
      // Terminal validation failure (not-found / expired / max / disabled /
      // email mismatch / already redeemed). Drop the code — retrying is futile.
      await PendingSignupCoupon.clear();
      return SignupCouponRejected(failure);
    }
  }
}
