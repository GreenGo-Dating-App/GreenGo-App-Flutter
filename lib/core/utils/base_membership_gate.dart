import 'package:flutter/material.dart';
import '../../features/membership/domain/entities/membership.dart';
import '../../features/profile/domain/entities/profile.dart';
import '../widgets/base_membership_dialog.dart';

/// Centralized gate that blocks interactions for non-members.
///
/// Returns `true` when the user is allowed to proceed.
/// Shows [BaseMembershipDialog] when they are not.
class BaseMembershipGate {
  static Future<bool> checkAndGate({
    required BuildContext context,
    required Profile? profile,
    required String userId,
  }) async {
    if (profile == null) return false;
    if (profile.membershipTier == MembershipTier.test) return true;
    if (profile.isBaseMembershipActive) return true;

    // User is not a member – show purchase dialog
    // Returns true if the user successfully purchased
    final purchased = await BaseMembershipDialog.show(
      context: context,
      userId: userId,
    );
    return purchased;
  }
}
