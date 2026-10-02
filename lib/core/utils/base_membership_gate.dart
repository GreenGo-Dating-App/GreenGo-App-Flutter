import 'package:flutter/material.dart';
import '../../features/membership/domain/entities/membership.dart';
import '../../features/profile/domain/entities/profile.dart';
import '../../features/subscription/presentation/screens/membership_screen.dart';
import '../services/own_profile_store.dart';

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
    profile ??= OwnProfileStore.instance.peek(userId) ??
        await OwnProfileStore.instance
            .current(userId)
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
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
}
