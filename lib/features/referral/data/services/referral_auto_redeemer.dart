import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'pending_referral_store.dart';

/// Outcome of one automatic redemption attempt.
enum ReferralRedeemOutcome {
  /// Nothing to do (no pending code, or not signed in).
  none,

  /// Redeemed; the pending code was cleared.
  redeemed,

  /// The server refused for good (already used a code, unknown code, own
  /// code, account too old...); the pending code was cleared.
  rejected,

  /// Transient failure (network, server); the code is kept for a retry.
  retryLater,
}

/// Redeems an invite captured from an invite LINK, automatically and
/// silently. There is NO code-entry UI anywhere: the code only ever comes from
/// a `/r/{CODE}` link (see DeepLinkService + PendingReferralStore).
///
/// Triggered after onboarding completes and whenever the signed-in home shell
/// attaches (so a link opened after onboarding, or a retry after a network
/// error, is still picked up). The server (`redeemReferral`) enforces every
/// rule: new accounts only (30 days), one code per user, no self-referral.
/// The friend learns about the Base week from the server's welcome
/// notification, so nothing is shown here.
class ReferralAutoRedeemer {
  ReferralAutoRedeemer({
    PendingReferralStore? store,
    Future<void> Function(String code)? redeem,
    String? Function()? currentUserId,
  })  : _store = store ?? PendingReferralStore(),
        _redeem = redeem ?? _callRedeemReferral,
        _currentUserId =
            currentUserId ?? (() => FirebaseAuth.instance.currentUser?.uid);

  static final ReferralAutoRedeemer instance = ReferralAutoRedeemer();

  /// Server error codes that can never succeed on a retry.
  static const Set<String> terminalErrorCodes = {
    'already-exists', // this account already used a code
    'not-found', // unknown code
    'failed-precondition', // own code, or account older than 30 days
    'invalid-argument',
    'permission-denied',
  };

  final PendingReferralStore _store;
  final Future<void> Function(String code) _redeem;
  final String? Function() _currentUserId;
  Future<ReferralRedeemOutcome>? _inFlight;

  PendingReferralStore get store => _store;

  static Future<void> _callRedeemReferral(String code) async {
    await FirebaseFunctions.instance
        .httpsCallable('redeemReferral',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)))
        .call<dynamic>(<String, dynamic>{'code': code});
  }

  /// Attempts the redemption once; concurrent calls share one attempt.
  Future<ReferralRedeemOutcome> tryRedeem() {
    return _inFlight ??= _attempt().whenComplete(() => _inFlight = null);
  }

  Future<ReferralRedeemOutcome> _attempt() async {
    try {
      final uid = _currentUserId();
      if (uid == null || uid.isEmpty) return ReferralRedeemOutcome.none;
      final pending = await _store.read();
      if (pending == null) return ReferralRedeemOutcome.none;
      try {
        await _redeem(pending.code);
        await _store.clear();
        return ReferralRedeemOutcome.redeemed;
      } on FirebaseFunctionsException catch (e) {
        if (terminalErrorCodes.contains(e.code)) {
          await _store.clear();
          return ReferralRedeemOutcome.rejected;
        }
        debugPrint('ReferralAutoRedeemer: will retry (${e.code})');
        return ReferralRedeemOutcome.retryLater;
      }
    } catch (e) {
      debugPrint('ReferralAutoRedeemer: will retry ($e)');
      return ReferralRedeemOutcome.retryLater;
    }
  }
}
