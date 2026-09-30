import '../../features/membership/domain/entities/membership.dart';
import 'tier_entitlements.dart';

/// One concrete, ENFORCED difference between two membership tiers.
///
/// Every kind here is read from the same source the app's gates use:
///   • [TierEntitlements] — connects/day (TierGate), events & groups
///     (TierLimitsService), boosts/month (TierGate), monthly coins, discovery
///     reveal ceiling (network discovery), see-who-connected, travel mode
///     (TierGate), analytics (TierGate), business account.
///   • [MembershipRules] — the swipe-deck limits (DiscoveryBloc), only when the
///     swipe deck exists in this build.
enum UpgradeBenefitKind {
  dailyConnects,
  events,
  groups,
  boostsPerMonth,
  monthlyCoins,
  discoveryReveal,
  seeWhoConnected,
  travelMode,
  analytics,
  businessAccount,
  // Swipe deck (full flavor only).
  hourlyConnects,
  hourlyPasses,
  hourlyPriorityConnects,
  dailyPriorityConnects,
}

/// A value on one side of an [UpgradeBenefit]: a count (null = unlimited) or
/// an on/off flag.
class BenefitValue {
  const BenefitValue.count(int? value)
      : count = value,
        flag = null;
  const BenefitValue.flag(bool value)
      : count = null,
        flag = value;

  /// Numeric value; null together with a null [flag] means UNLIMITED.
  final int? count;

  /// On/off value for boolean perks; null for numeric perks.
  final bool? flag;

  bool get isFlag => flag != null;
  bool get isUnlimited => flag == null && count == null;

  @override
  bool operator ==(Object other) =>
      other is BenefitValue && other.count == count && other.flag == flag;

  @override
  int get hashCode => Object.hash(count, flag);

  @override
  String toString() =>
      isFlag ? (flag! ? 'yes' : 'no') : (isUnlimited ? '∞' : '$count');
}

/// "[kind]: [from] → [to]" — one row of the Upgrade Benefits list.
class UpgradeBenefit {
  const UpgradeBenefit(this.kind, this.from, this.to);

  final UpgradeBenefitKind kind;
  final BenefitValue from;
  final BenefitValue to;

  @override
  bool operator ==(Object other) =>
      other is UpgradeBenefit &&
      other.kind == kind &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(kind, from, to);

  @override
  String toString() => '${kind.name}: $from → $to';
}

/// The next purchasable tier above [tier]; null at the top (Platinum / TEST).
MembershipTier? nextTierUp(MembershipTier tier) {
  switch (tier) {
    case MembershipTier.free:
      return MembershipTier.silver;
    case MembershipTier.silver:
      return MembershipTier.gold;
    case MembershipTier.gold:
      return MembershipTier.platinum;
    case MembershipTier.platinum:
    case MembershipTier.test:
      return null;
  }
}

/// `-1 = unlimited` (MembershipRules) → `null = unlimited`.
int? _rulesCount(int v) => v < 0 ? null : v;

/// The value of [kind] for [tier].
BenefitValue benefitValueFor(UpgradeBenefitKind kind, MembershipTier tier) {
  final rules = MembershipRules.getDefaultsForTier(tier);
  switch (kind) {
    case UpgradeBenefitKind.dailyConnects:
      return BenefitValue.count(TierEntitlements.maxDailyConnects(tier));
    case UpgradeBenefitKind.events:
      return BenefitValue.count(TierEntitlements.maxEvents(tier));
    case UpgradeBenefitKind.groups:
      return BenefitValue.count(TierEntitlements.maxGroups(tier));
    case UpgradeBenefitKind.boostsPerMonth:
      return BenefitValue.count(TierEntitlements.boostsPerMonth(tier));
    case UpgradeBenefitKind.monthlyCoins:
      return BenefitValue.count(TierEntitlements.monthlyCoins(tier));
    case UpgradeBenefitKind.discoveryReveal:
      return BenefitValue.count(TierEntitlements.discoveryFreeReveal(tier));
    case UpgradeBenefitKind.seeWhoConnected:
      return BenefitValue.flag(TierEntitlements.canSeeWhoConnected(tier));
    case UpgradeBenefitKind.travelMode:
      return BenefitValue.flag(TierEntitlements.travelModeEnabled(tier));
    case UpgradeBenefitKind.analytics:
      return BenefitValue.flag(TierEntitlements.analyticsEnabled(tier));
    case UpgradeBenefitKind.businessAccount:
      return BenefitValue.flag(TierEntitlements.canBecomeBusiness(tier));
    case UpgradeBenefitKind.hourlyConnects:
      return BenefitValue.count(_rulesCount(rules.hourlyConnectLimit));
    case UpgradeBenefitKind.hourlyPasses:
      return BenefitValue.count(_rulesCount(rules.hourlyPassLimit));
    case UpgradeBenefitKind.hourlyPriorityConnects:
      return BenefitValue.count(_rulesCount(rules.hourlyPriorityConnectLimit));
    case UpgradeBenefitKind.dailyPriorityConnects:
      return BenefitValue.count(_rulesCount(rules.dailyPriorityConnectLimit));
  }
}

const List<UpgradeBenefitKind> _swipeKinds = [
  UpgradeBenefitKind.hourlyConnects,
  UpgradeBenefitKind.hourlyPasses,
  UpgradeBenefitKind.hourlyPriorityConnects,
  UpgradeBenefitKind.dailyPriorityConnects,
];

/// The REAL differences between [from] and [to], in display order — only the
/// rows whose value actually changes.
///
/// [includeSwipeLimits] adds the swipe-deck limits; pass
/// `FlavorConfig.enableSwipeDiscovery` (those limits mean nothing in a build
/// without the swipe deck).
List<UpgradeBenefit> upgradeBenefits(
  MembershipTier from,
  MembershipTier to, {
  bool includeSwipeLimits = false,
}) {
  final kinds = [
    for (final k in UpgradeBenefitKind.values)
      if (includeSwipeLimits || !_swipeKinds.contains(k)) k,
  ];
  return [
    for (final k in kinds)
      if (benefitValueFor(k, from) != benefitValueFor(k, to))
        UpgradeBenefit(k, benefitValueFor(k, from), benefitValueFor(k, to)),
  ];
}

/// Benefits of moving from [tier] to the next tier up; empty at the top.
List<UpgradeBenefit> nextTierBenefits(
  MembershipTier tier, {
  bool includeSwipeLimits = false,
}) {
  final next = nextTierUp(tier);
  if (next == null) return const [];
  return upgradeBenefits(tier, next, includeSwipeLimits: includeSwipeLimits);
}
