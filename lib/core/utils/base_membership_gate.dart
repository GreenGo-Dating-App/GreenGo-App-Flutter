import 'package:flutter/material.dart';
import '../../features/membership/domain/entities/membership.dart';
import '../../features/profile/domain/entities/profile.dart';
import '../../features/subscription/presentation/screens/membership_screen.dart';

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
    if (profile == null) return false;
    if (profile.membershipTier == MembershipTier.test) return true;
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
