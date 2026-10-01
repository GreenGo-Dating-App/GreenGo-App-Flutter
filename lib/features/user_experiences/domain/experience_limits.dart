import '../../../core/services/tier_entitlements.dart';
import '../../membership/domain/entities/membership.dart';

/// How many experiences the host may have (null = unlimited). [tier] must be
/// the EFFECTIVE tier; admins are unlimited. Mirrors the server's
/// `maxExperiencesFor` (functions/src/user_experiences/validation.ts).
int? experienceLimitFor(MembershipTier tier, {bool isAdmin = false}) =>
    isAdmin ? null : TierEntitlements.maxExperiences(tier);

/// Whether a host who already has [count] experiences may create another.
/// A downgraded host over the limit keeps their experiences but gets `false`.
bool canCreateAnotherExperience({
  required MembershipTier tier,
  required int count,
  bool isAdmin = false,
}) {
  final max = experienceLimitFor(tier, isAdmin: isAdmin);
  return max == null || count < max;
}

/// The cheapest tier that allows more than [count] experiences, or null.
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
