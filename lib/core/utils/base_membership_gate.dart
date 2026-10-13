import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../features/membership/domain/entities/membership.dart';
import '../../features/profile/domain/entities/profile.dart';
import '../../features/subscription/presentation/screens/membership_screen.dart';
import '../../generated/app_localizations.dart';
import '../error/failures.dart';
import '../services/effective_tier.dart' show kBaseMembershipRequiredCode;
import '../services/own_profile_store.dart';
import '../widgets/base_membership_required_dialog.dart';

/// Centralized gate that blocks interactions for non-members.
///
/// Returns `true` when the user is allowed to proceed.
/// Opens [MembershipScreen] when they are not.
class BaseMembershipGate {
  static Future<bool> checkAndGate({
    required BuildContext context,
    required Profile? profile,
    required String userId,
  }) async {
    // A screen whose own profile hasn't loaded yet used to make every gated
    // tap do nothing. Fall back to the shared own-profile store (the shell's
    // live listener), reading it once if it's still empty.
    profile ??= await _ownProfile(userId);
    if (profile == null) return false;
    if (!context.mounted) return false;
    if (profile.effectiveTier == MembershipTier.test) return true;
    if (profile.isBaseMembershipActive) return true;

    // Not a member — send them to the membership screen rather than a popup.
    //
    // This deliberately returns false: the caller's action does not silently
    // continue behind the screen. Once a membership is bought, the next attempt
    // passes the checks above.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MembershipScreen(currentUserId: userId),
      ),
    );
    return false;
  }

  // ── Participation (owner rule 2026-10-11) ─────────────────────────────────
  //
  // Joining someone else's event (going / waitlist / tickets) and booking an
  // experience need the Base membership; an active Silver / Gold / Platinum
  // or TEST counts too. Same predicate as chat ([Profile.isBaseMembershipActive]
  // = canParticipateFromDoc), enforced by the server: Firestore rules
  // `canParticipate()` and the callables (refusal code
  // [kBaseMembershipRequiredCode]). Organizers / hosts on their own listing,
  // 'interested', cancelling and check-in are never gated.

  /// THE app-side participation check for a parsed profile.
  static bool canParticipate(Profile? profile) =>
      profile?.isBaseMembershipActive ?? false;

  /// Returns true when [userId] may join / book; otherwise shows the
  /// Base-membership dialog (CTA to the membership screen) and returns false.
  /// An unknown profile (still loading / offline) is let through: the server
  /// decides and its refusal is mapped by [handleParticipationError].
  static Future<bool> ensureCanParticipate({
    required BuildContext context,
    required String userId,
    Profile? profile,
  }) async {
    profile ??= await _ownProfile(userId);
    if (profile == null || canParticipate(profile)) return true;
    if (!context.mounted) return false;
    await BaseMembershipRequiredDialog.show(context, userId: userId);
    return false;
  }

  /// Creating events and experiences needs a plan too (owner rule
  /// 2026-10-13): Base or better, same predicate as [canParticipate],
  /// enforced by the event rules and `createUserExperience`. Editing an
  /// existing listing is never gated. An unknown profile is let through.
  static Future<bool> ensureCanCreate({
    required BuildContext context,
    required String userId,
    Profile? profile,
  }) async {
    profile ??= await _ownProfile(userId);
    if (profile == null || canParticipate(profile) || profile.isAdmin) {
      return true;
    }
    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    await BaseMembershipRequiredDialog.show(
      context,
      userId: userId,
      title: l10n.createNeedsPlanTitle,
      body: l10n.createNeedsPlanBody,
    );
    return false;
  }

  /// Maps a refused participation to the Base-membership dialog. Returns
  /// true when it was handled (the caller shows nothing else).
  ///
  /// * Callables: `details.code == 'base_membership_required'` (also carried
  ///   by TicketPaymentException.reason / BookingFailure.code - pass [reason]).
  /// * Direct Firestore writes (RSVP): a `permission-denied` - the own profile
  ///   is re-read from the server and the dialog shown when it is not
  ///   eligible (the local state was stale).
  static Future<bool> handleParticipationError(
    BuildContext context, {
    required String userId,
    Object? error,
    String? reason,
  }) async {
    final code = reason ?? errorCodeOf(error);
    if (code == kBaseMembershipRequiredCode) {
      if (context.mounted) {
        await BaseMembershipRequiredDialog.show(context, userId: userId);
      }
      return true;
    }
    if (code != 'permission-denied') return false;
    final fresh =
        await OwnProfileStore.instance.current(userId, forceServer: true);
    if (fresh == null || canParticipate(fresh) || !context.mounted) {
      return false;
    }
    await BaseMembershipRequiredDialog.show(context, userId: userId);
    return true;
  }

  /// The refusal code of [error]: the callable's `details.code` (else its
  /// code), a Firestore error code, or a known code inside a wrapped message
  /// (ServerException / Failure text).
  static String? errorCodeOf(Object? error) {
    if (error == null) return null;
    if (error is FirebaseFunctionsException) {
      final d = error.details;
      if (d is Map && d['code'] is String) return d['code'] as String;
      return error.code;
    }
    if (error is FirebaseException) return error.code;
    final text = error is Failure ? error.message : error.toString();
    if (text.contains(kBaseMembershipRequiredCode)) {
      return kBaseMembershipRequiredCode;
    }
    if (text.contains('permission-denied') ||
        text.contains('PERMISSION_DENIED')) {
      return 'permission-denied';
    }
    return null;
  }

  static Future<Profile?> _ownProfile(String userId) async =>
      OwnProfileStore.instance.peek(userId) ??
      await OwnProfileStore.instance
          .current(userId)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
}
