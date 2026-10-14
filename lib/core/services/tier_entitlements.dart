import '../../features/membership/domain/entities/membership.dart';
import '../../generated/app_localizations.dart';

/// Level of advanced search / discovery filters a tier can use.
///
/// Part 2 will map these levels to the concrete set of filters unlocked.
///   none  (0) = basic only (default free filters)
///   basic (1) = a small curated subset
///   plus  (2) = most filters
///   all   (3) = every filter
enum SearchFilterLevel {
  none(0),
  basic(1),
  plus(2),
  all(3);

  final int level;
  const SearchFilterLevel(this.level);
}

/// One row of the membership comparison table: a localized label and one
/// display value per tier, in [TierEntitlements.comparisonTiers] order.
class TierComparisonRow {
  const TierComparisonRow(this.label, this.values);

  final String label;

  /// Free (Base), Silver, Gold, Platinum.
  final List<String> values;
}

/// SINGLE SOURCE OF TRUTH for what each membership tier can do.
///
/// The app's gates and every promise screen (shop cards, the comparison
/// table [comparisonRows], Upgrade Benefits, the tier reveal) read these
/// accessors. The SERVER enforces the same numbers: they are mirrored in
/// functions/src/shared/tierLimits.ts (a unit test there parses this file and
/// fails on drift) and in the Firestore rules (`tierCap*`). Keep ALL tunable
/// numbers in the `// adjustable` consts at the top.
///
/// Convention: a `null` return means UNLIMITED / infinite (∞).
///
/// `MembershipTier.test` always maps to the same generous values as
/// `platinum` (unlimited where applicable).
class TierEntitlements {
  const TierEntitlements._();

  // ===========================================================================
  // ADJUSTABLE TUNABLES  (change tier balance here — one place, no divergence)
  // ===========================================================================

  // --- Max ACTIVE events a user may have AT A TIME (null = unlimited). ---
  // Owner rule 2026-10-14. "Active" = not ended, cancelled, deleted or hidden
  // by a plan downgrade; a recurring series counts once. Ending or deleting
  // an event frees its slot. `free` here is Base (no plan creates nothing,
  // see Profile.isBaseMembershipActive); Base events are free only.
  // Mirrored by TierLimitsService.maxEvents (which delegates here). There is
  // no way to buy extra events (the 50-coin extra event is retired).
  static const int _eventsFree = 1; // Base: 1 active event
  static const int _eventsSilver = 5; // Silver: 5 active events
  static const int _eventsGold = 10; // Gold: 10 active events
  static const int? _eventsPlatinum = null; // Platinum: unlimited (∞)

  // --- Groups a user may create (null = unlimited). ---
  // Mirrored by TierLimitsService.maxGroups (which now delegates here).
  static const int _groupsFree = 1; // adjustable
  static const int? _groupsSilver = null; // adjustable (∞)
  static const int? _groupsGold = null; // adjustable (∞)
  static const int? _groupsPlatinum = null; // adjustable (∞)

  // --- Member-hosted experiences a user may have AT A TIME (null = ∞). ---
  // Counts every experience the host has that is not deleted and not hidden
  // by a plan downgrade (drafts + published + moderation-hidden). Deleting
  // one frees the slot. Enforced server-side by the createUserExperience
  // callable (functions/src/shared/tierLimits.ts MAX_EXPERIENCES).
  static const int _experiencesFree = 1; // Base: 1 experience (free only)
  static const int _experiencesSilver = 5; // Silver: 5 experiences
  static const int _experiencesGold = 10; // Gold: 10 experiences
  static const int? _experiencesPlatinum = null; // Platinum: unlimited (∞)

  // --- Characters of translation per UTC day sent to the paid API. ---
  // By membership (owner rule 2026-10-13): no plan 3k, Base 10k, Silver 25k,
  // Gold 50k, Platinum 100k. Enforced by the server (TRANSLATE_CHARS_DAILY in
  // functions/src/shared/tierLimits.ts); stored translations are free.
  static const int translateCharsNoPlan = 3000;
  static int translateCharsPerDay(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.platinum:
      case MembershipTier.test:
        return 100000;
      case MembershipTier.gold:
        return 50000;
      case MembershipTier.silver:
        return 25000;
      default:
        return 10000; // Base
    }
  }

  // --- People an account WITHOUT Base may chat with per UTC day. ---
  // A taste of the app (owner rule 2026-10-13); Base and up are unlimited.
  // Mirrors FREE_DAILY_CHATS (functions/src/shared/tierLimits.ts), enforced
  // by the claimFreeChat callable and `freeChatOk` in the Firestore rules.
  static const int freeDailyChats = 3;

  // --- New-people connects / first-messages per day (null = unlimited). ---
  static const int _dailyConnectsFree = 10; // adjustable
  static const int _dailyConnectsSilver = 50; // adjustable
  static const int _dailyConnectsGold = 200; // adjustable
  static const int? _dailyConnectsPlatinum = null; // adjustable (∞)

  // --- FREE profile boosts per calendar month (UTC). ---
  // Counted by the server (spendCoins, entitlement_usage/{uid}); a boost
  // beyond the allowance costs CoinFeaturePrices.boost coins. Not available
  // on the free plan at all.
  static const int _boostsPerMonthFree = 0; // adjustable (none)
  static const int _boostsPerMonthSilver = 1; // adjustable (~1/month)
  static const int _boostsPerMonthGold = 4; // adjustable (~1/week)
  static const int _boostsPerMonthPlatinum = 30; // adjustable (~1/day)

  // --- How many boosted profiles a viewer of this tier can SEE. ---
  // Reused verbatim from DiscoveryRemoteDataSource._getMaxBoostedVisible
  // (FREE 2 / SILVER 5 / GOLD 10 / PLATINUM+TEST 999 ≈ unlimited).
  static const int _boostedVisibleFree = 2; // adjustable (mirror discovery)
  static const int _boostedVisibleSilver = 5; // adjustable (mirror discovery)
  static const int _boostedVisibleGold = 10; // adjustable (mirror discovery)
  static const int _boostedVisiblePlatinum = 999; // adjustable (mirror discovery, ≈∞)

  // --- Coins granted each month by the membership. ---
  // Must match MONTHLY_COINS in functions/src/coins/monthlyAllowance.ts (the
  // server pays them). Base (free tier) is paid only with an active Base
  // membership.
  static const int _monthlyCoinsFree = 20; // Base
  static const int _monthlyCoinsSilver = 300;
  static const int _monthlyCoinsGold = 400;
  static const int _monthlyCoinsPlatinum = 500;

  // --- Discovery: profiles a viewer can reveal for FREE before the coin gate. ---
  // Starting reveal ceiling in the network-discovery grid; beyond it the user
  // spends coins to "see more". Platinum is effectively uncapped.
  // People a viewer can see at a time in discovery, per tier (Base → Platinum).
  // Beyond the cap, +50 more people can be unlocked for 15 coins (see
  // network_discovery_screen.dart kRevealChunk / kCoinsToSeeMore).
  static const int _discoveryFreeRevealFree = 100; // Base: 100 at a time
  static const int _discoveryFreeRevealSilver = 200; // Silver: 200
  static const int _discoveryFreeRevealGold = 300; // Gold: 300
  static const int _discoveryFreeRevealPlatinum = 500; // Platinum: 500

  // --- TTS / translation cost: FLAT for ALL tiers (no discounts, no quota). ---
  // NOTE: this is a global (tier-independent) cost. It lives here as the
  // single source of truth for the coins/TTS config; if a dedicated coins
  // config emerges later, move it there and delegate.
  static const int ttsCostCoins = 5; // adjustable (flat, all tiers)

  // ===========================================================================
  // ACCESSORS  (keyed by MembershipTier — the public API features/UI read)
  // ===========================================================================

  /// Max ACTIVE events a tier may have at a time (null = unlimited / ∞).
  /// [MembershipTier.free] is Base; without any plan the allowance is 0
  /// (Profile.isBaseMembershipActive). When a plan drops, the listings over
  /// the new allowance are hidden by the server and restored on upgrade.
  static int? maxEvents(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return _eventsFree;
      case MembershipTier.silver:
        return _eventsSilver;
      case MembershipTier.gold:
        return _eventsGold;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return _eventsPlatinum;
    }
  }

  /// The cheapest tier whose active-listing allowance (events and
  /// experiences share the numbers) is larger than [tier]'s, or null when
  /// [tier] is already unlimited.
  static MembershipTier? nextTierForMoreListings(MembershipTier tier) {
    final current = maxEvents(tier);
    if (current == null) return null;
    for (final t in const [
      MembershipTier.silver,
      MembershipTier.gold,
      MembershipTier.platinum,
    ]) {
      final max = maxEvents(t);
      if (max == null || max > current) return t;
    }
    return null;
  }

  /// Max groups a tier may create (null = unlimited / ∞).
  static int? maxGroups(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return _groupsFree;
      case MembershipTier.silver:
        return _groupsSilver;
      case MembershipTier.gold:
        return _groupsGold;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return _groupsPlatinum;
    }
  }

  /// Max ACTIVE member-hosted experiences a tier may have at a time (null =
  /// unlimited / ∞). Pass the EFFECTIVE tier (an expired Silver is Base).
  /// Admins are unlimited regardless of tier (callers check that separately).
  static int? maxExperiences(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return _experiencesFree;
      case MembershipTier.silver:
        return _experiencesSilver;
      case MembershipTier.gold:
        return _experiencesGold;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return _experiencesPlatinum;
    }
  }

  /// Max new-people connects / first-messages per day (null = unlimited / ∞).
  static int? maxDailyConnects(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return _dailyConnectsFree;
      case MembershipTier.silver:
        return _dailyConnectsSilver;
      case MembershipTier.gold:
        return _dailyConnectsGold;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return _dailyConnectsPlatinum;
    }
  }

  /// FREE profile boosts per calendar month (more can be bought with coins).
  static int boostsPerMonth(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return _boostsPerMonthFree;
      case MembershipTier.silver:
        return _boostsPerMonthSilver;
      case MembershipTier.gold:
        return _boostsPerMonthGold;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return _boostsPerMonthPlatinum;
    }
  }

  /// Localized cadence describing the monthly boost grant.
  static String boostCadence(AppLocalizations l10n, MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return l10n.tierBoostCadenceNone;
      case MembershipTier.silver:
        return l10n.tierBoostCadenceMonthly;
      case MembershipTier.gold:
        return l10n.tierBoostCadenceWeekly;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return l10n.tierBoostCadenceDaily;
    }
  }

  /// How many boosted profiles a viewer of this tier can see in discovery.
  /// (Mirrors DiscoveryRemoteDataSource._getMaxBoostedVisible.)
  static int maxBoostedVisible(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return _boostedVisibleFree;
      case MembershipTier.silver:
        return _boostedVisibleSilver;
      case MembershipTier.gold:
        return _boostedVisibleGold;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return _boostedVisiblePlatinum;
    }
  }

  /// Coins granted each month by this membership tier.
  static int monthlyCoins(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return _monthlyCoinsFree;
      case MembershipTier.silver:
        return _monthlyCoinsSilver;
      case MembershipTier.gold:
        return _monthlyCoinsGold;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return _monthlyCoinsPlatinum;
    }
  }

  /// How many profiles a viewer of this tier can reveal for FREE in discovery
  /// before hitting the coin-gated "see more" flow (Platinum ≈ unlimited).
  static int discoveryFreeReveal(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return _discoveryFreeRevealFree;
      case MembershipTier.silver:
        return _discoveryFreeRevealSilver;
      case MembershipTier.gold:
        return _discoveryFreeRevealGold;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return _discoveryFreeRevealPlatinum;
    }
  }

  /// Advanced-search filter level unlocked for this tier.
  static SearchFilterLevel searchFilterLevel(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return SearchFilterLevel.none;
      case MembershipTier.silver:
        return SearchFilterLevel.basic;
      case MembershipTier.gold:
        return SearchFilterLevel.plus;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return SearchFilterLevel.all;
    }
  }

  /// Whether travel mode (browse/discover in another location) is enabled.
  static bool travelModeEnabled(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return false;
      case MembershipTier.silver:
      case MembershipTier.gold:
      case MembershipTier.platinum:
      case MembershipTier.test:
        return true;
    }
  }

  /// Whether travel mode is FREE for the tier (Platinum); the other tiers
  /// with travel mode pay CoinFeaturePrices.traveler coins per day.
  static bool travelModeFree(MembershipTier tier) =>
      tier == MembershipTier.platinum || tier == MembershipTier.test;

  /// Ghost mode (hidden from discovery and search), free and unlimited:
  /// Gold and up. The Firestore rules enforce the same.
  static bool ghostModeIncluded(MembershipTier tier) =>
      tier == MembershipTier.gold ||
      tier == MembershipTier.platinum ||
      tier == MembershipTier.test;

  /// Whether the tier gets priority customer support: its support tickets are
  /// ranked first in the support queue (set server-side by
  /// onSupportChatCreated from the effective tier).
  static bool prioritySupport(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
      case MembershipTier.silver:
        return false;
      case MembershipTier.gold:
      case MembershipTier.platinum:
      case MembershipTier.test:
        return true;
    }
  }

  /// Whether the tier unlocks the business Analytics dashboard.
  ///
  /// Platinum-exclusive perk (test users get it too for QA). Every other tier
  /// sees the locked / upgrade state on the Analytics screen.
  static bool analyticsEnabled(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
      case MembershipTier.silver:
      case MembershipTier.gold:
        return false;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return true;
    }
  }

  /// Whether the tier may convert a personal account into a public BUSINESS
  /// account (a one-time, irreversible upgrade that unlocks the storefront,
  /// followers, lead capture, verification request and PAID events /
  /// experiences).
  ///
  /// Silver, Gold and Platinum (owner rule 2026-10-14; test users too for
  /// QA). Base / no plan see the upgrade dialog on the Business Account
  /// screen. (Analytics and community sponsoring stay Platinum-only.)
  static bool canBecomeBusiness(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return false;
      case MembershipTier.silver:
      case MembershipTier.gold:
      case MembershipTier.platinum:
      case MembershipTier.test:
        return true;
    }
  }

  /// Whether a business account's capabilities are currently ACTIVE.
  ///
  /// Business capabilities require an active Silver, Gold or Platinum
  /// membership ([canBecomeBusiness]). The stored [isBusiness] flag is
  /// permanent (never cleared), but the storefront, leads, promotion, paid
  /// listings and verification tools only work while the user holds a paid
  /// tier. If it lapses (tier rolls back to Base / no plan on expiry), the
  /// account keeps its [isBusiness] flag but operates as a normal account
  /// (free listings only) until a paid tier is renewed — at which point the
  /// business capabilities are restored automatically.
  ///
  /// [tier] MUST be the EFFECTIVE tier (`Profile.effectiveTier` /
  /// `effectiveTierFromDoc`), never the raw stored `membershipTier` — the
  /// stored string still says PLATINUM until the server downgrade job runs.
  static bool isBusinessActive(MembershipTier tier, bool isBusiness) {
    return isBusiness && canBecomeBusiness(tier);
  }

  /// Whether listings created on [tier] may be PAID (tickets / bookings):
  /// Silver and up, and only through an active business account
  /// ([isBusinessActive]). Base listings are always free.
  static bool paidListingsAllowed(MembershipTier tier) =>
      canBecomeBusiness(tier);

  // ===========================================================================
  // COMPARISON TABLE — rendered by TierComparisonTable on the membership
  // screen. Every value is derived from the accessors above.
  // ===========================================================================

  /// Column order of [comparisonRows].
  static const List<MembershipTier> comparisonTiers = [
    MembershipTier.free,
    MembershipTier.silver,
    MembershipTier.gold,
    MembershipTier.platinum,
  ];

  /// Check / cross marks used for on-off perks in the table.
  static const String yesMark = '✓';
  static const String noMark = '✗';

  /// The comparison table rows. [travelCoinsPerDay] is the daily travel-mode
  /// price for the tiers that pay for it (CoinFeaturePrices.traveler).
  static List<TierComparisonRow> comparisonRows(
    AppLocalizations l10n, {
    required int travelCoinsPerDay,
  }) {
    String count(int? v) => v == null ? l10n.shopUnlimited : '$v';
    String mark(bool v) => v ? yesMark : noMark;
    List<String> each(String Function(MembershipTier t) f) =>
        [for (final t in comparisonTiers) f(t)];

    return [
      // Joining events / booking experiences: Base and every tier above
      // (owner rule 2026-10-11; enforced by the rules and the callables).
      TierComparisonRow(l10n.membershipBenefitJoinEvents, each((_) => mark(true))),
      TierComparisonRow(
          l10n.shopEventsCreate, each((t) => count(maxEvents(t)))),
      TierComparisonRow(l10n.shopGroupsCreate, each((t) => count(maxGroups(t)))),
      TierComparisonRow(
          l10n.shopDailyConnects, each((t) => count(maxDailyConnects(t)))),
      TierComparisonRow(
          l10n.shopExperiencesCreate, each((t) => count(maxExperiences(t)))),
      TierComparisonRow(
          l10n.shopMonthlyBoosts, each((t) => '${boostsPerMonth(t)}')),
      TierComparisonRow(
          l10n.shopMonthlyCoins, each((t) => '${monthlyCoins(t)}')),
      TierComparisonRow(
        l10n.tierTravelModeCostRow,
        each((t) => !travelModeEnabled(t)
            ? noMark
            : travelModeFree(t)
                ? l10n.tierFree
                : '$travelCoinsPerDay'),
      ),
      TierComparisonRow(
          l10n.profileGhostMode, each((t) => mark(ghostModeIncluded(t)))),
      TierComparisonRow(l10n.membershipPrioritySupport,
          each((t) => mark(prioritySupport(t)))),
      TierComparisonRow(
          l10n.shopBusinessAccount, each((t) => mark(canBecomeBusiness(t)))),
    ];
  }
}
