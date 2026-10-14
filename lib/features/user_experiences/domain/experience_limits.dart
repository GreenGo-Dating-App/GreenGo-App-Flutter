import '../../../core/services/tier_entitlements.dart';
import '../../membership/domain/entities/membership.dart';

/// How many ACTIVE experiences the host may have at a time (null =
/// unlimited): Base 1 (free only), Silver 5, Gold 10, Platinum unlimited.
/// [tier] must be the EFFECTIVE tier; admins are unlimited. Mirrors the
/// server's `maxExperiencesFor` (functions/src/user_experiences/validation.ts).
int? experienceLimitFor(MembershipTier tier, {bool isAdmin = false}) =>
    isAdmin ? null : TierEntitlements.maxExperiences(tier);

/// Whether a host who already has [count] ACTIVE experiences may create
/// another. Deleting one frees a slot; after a downgrade the server hides the
/// ones over the allowance (they no longer count).
bool canCreateAnotherExperience({
  required MembershipTier tier,
  required int count,
  bool isAdmin = false,
}) {
  final max = experienceLimitFor(tier, isAdmin: isAdmin);
  return max == null || count < max;
}

/// The cheapest tier that allows more than [count] active experiences, or null.
MembershipTier? tierNeededForExperiences(int count) {
  for (final t in const [
    MembershipTier.silver,
    MembershipTier.gold,
    MembershipTier.platinum,
  ]) {
    final max = TierEntitlements.maxExperiences(t);
    if (max == null || count < max) return t;
  }
  return null;
}
