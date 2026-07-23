import '../../features/membership/domain/entities/membership.dart';

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

/// A single, renderable perk row for the marketplace (Part 3).
///
/// [labelKey] is an l10n key NAME (not a display string) so the marketplace
/// can localize it. [valueText] is a raw, already-formatted value fragment
/// (e.g. "5", "Unlimited", "5 coins") — Part 3 is free to reformat/localize it.
/// [enabled] lets boolean perks render as a check / cross without parsing text.
class TierPerk {
  const TierPerk({
    required this.labelKey,
    required this.valueText,
    this.enabled,
  });

  /// l10n key NAME for the perk label (e.g. 'tierPerkEvents').
  final String labelKey;

  /// Human-facing value fragment for this tier (e.g. "50", "Unlimited").
  final String valueText;

  /// For boolean perks: whether the tier has it. null for numeric perks.
  final bool? enabled;
}

/// SINGLE SOURCE OF TRUTH for what each membership tier can do.
///
/// This is Part 1 (foundation / config only). Nothing here enforces anything —
/// features read these accessors in Part 2, and the marketplace renders
/// [perksFor] in Part 3. Keep ALL tunable numbers in the `// adjustable`
/// consts at the top so tiers can be re-balanced in one place.
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

  // --- Max ONGOING events a user may have (null = unlimited). ---
  // "Ongoing" = events that haven't ended yet. Mirrored by
  // TierLimitsService.maxEvents (which delegates here).
  static const int _eventsFree = 1; // adjustable
  static const int _eventsSilver = 3; // Silver: max 3 ongoing events
  static const int _eventsGold = 5; // Gold: max 5 ongoing events
  static const int? _eventsPlatinum = null; // Platinum: unlimited (∞)

  // --- Groups a user may create (null = unlimited). ---
  // Mirrored by TierLimitsService.maxGroups (which now delegates here).
  static const int _groupsFree = 1; // adjustable
  static const int? _groupsSilver = null; // adjustable (∞)
  static const int? _groupsGold = null; // adjustable (∞)
  static const int? _groupsPlatinum = null; // adjustable (∞)

  // --- New-people connects / first-messages per day (null = unlimited). ---
  static const int _dailyConnectsFree = 10; // adjustable
  static const int _dailyConnectsSilver = 50; // adjustable
  static const int _dailyConnectsGold = 200; // adjustable
  static const int? _dailyConnectsPlatinum = null; // adjustable (∞)

  // --- Profile boosts granted per month. ---
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
  static const int _monthlyCoinsFree = 100; // adjustable
  static const int _monthlyCoinsSilver = 500; // adjustable
  static const int _monthlyCoinsGold = 1500; // adjustable
  static const int _monthlyCoinsPlatinum = 5000; // adjustable

  // --- Discovery: profiles a viewer can reveal for FREE before the coin gate. ---
  // Starting reveal ceiling in the network-discovery grid; beyond it the user
  // spends coins to "see more". Platinum is effectively uncapped.
  // People a viewer can see at a time in discovery, per tier (Base → Platinum).
  // Beyond the cap, +25 more people can be unlocked for 25 coins (see
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

  /// Max events a tier may create (null = unlimited / ∞).
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

  /// Number of profile boosts granted per month.
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

  /// Human-readable cadence describing the monthly boost grant
  /// (l10n happens in Part 2/3; this is a stable English hint).
  static String boostCadence(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return 'None';
      case MembershipTier.silver:
        return '1 per month';
      case MembershipTier.gold:
        return '~1 per week';
      case MembershipTier.platinum:
      case MembershipTier.test:
        return '~1 per day';
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

  /// Whether the tier can see the list of who connected with them.
  static bool canSeeWhoConnected(MembershipTier tier) {
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

  /// Whether the tier gets priority customer support.
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
  /// followers, lead capture and verification request).
  ///
  /// Platinum-exclusive perk (test users get it too for QA). Every other tier
  /// sees the upgrade dialog on the Business Account screen.
  static bool canBecomeBusiness(MembershipTier tier) {
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

  /// Whether a business account's capabilities are currently ACTIVE.
  ///
  /// Business capabilities require an active Platinum membership. The stored
  /// [isBusiness] flag is permanent (never cleared), but the storefront,
  /// analytics, leads, promotion and verification tools only work while the
  /// user actually holds Platinum. If their Platinum lapses (tier rolls back to
  /// free/base on expiry), the account keeps its [isBusiness] flag but operates
  /// as a normal Base account until Platinum is renewed — at which point the
  /// business capabilities are restored automatically.
  static bool isBusinessActive(MembershipTier tier, bool isBusiness) {
    return isBusiness &&
        (tier == MembershipTier.platinum || tier == MembershipTier.test);
  }

  // ===========================================================================
  // MARKETPLACE (Part 3) — structured, iterable description of the matrix.
  // Renders a per-tier feature list WITHOUT duplicating any numbers above.
  // Labels are l10n key NAMES (Part 3 adds the English strings to app_en.arb).
  // ===========================================================================

  /// Stable l10n key NAMES for each perk row. Part 3 will add the matching
  /// English strings to `app_en.arb`. Exposed so the marketplace and any
  /// tests can reference keys without magic strings.
  static const String perkKeyEvents = 'tierPerkEvents';
  static const String perkKeyGroups = 'tierPerkGroups';
  static const String perkKeyDailyConnects = 'tierPerkDailyConnects';
  static const String perkKeyBoostsPerMonth = 'tierPerkBoostsPerMonth';
  static const String perkKeyBoostedVisible = 'tierPerkBoostedVisible';
  static const String perkKeyMonthlyCoins = 'tierPerkMonthlyCoins';
  static const String perkKeySearchFilters = 'tierPerkSearchFilters';
  static const String perkKeySeeWhoConnected = 'tierPerkSeeWhoConnected';
  static const String perkKeyTravelMode = 'tierPerkTravelMode';
  static const String perkKeyTtsCost = 'tierPerkTtsCost';
  static const String perkKeyPrioritySupport = 'tierPerkPrioritySupport';

  /// Format an "int? (null = ∞)" value for display.
  static String _fmtCount(int? v) => v == null ? '∞' : '$v';

  /// Format a boolean perk for display.
  static String _fmtBool(bool v) => v ? 'Yes' : 'No';

  /// Human-facing name for a search-filter level.
  static String _fmtFilterLevel(SearchFilterLevel l) {
    switch (l) {
      case SearchFilterLevel.none:
        return 'Basic';
      case SearchFilterLevel.basic:
        return 'Standard';
      case SearchFilterLevel.plus:
        return 'Advanced';
      case SearchFilterLevel.all:
        return 'All filters';
    }
  }

  /// The full, ordered perk list for a tier — everything derived from the
  /// accessors above, so there is no duplication of the tunable numbers.
  /// The marketplace can render this directly (localizing [TierPerk.labelKey]).
  static List<TierPerk> perksFor(MembershipTier tier) {
    return [
      TierPerk(
        labelKey: perkKeyEvents,
        valueText: _fmtCount(maxEvents(tier)),
      ),
      TierPerk(
        labelKey: perkKeyGroups,
        valueText: _fmtCount(maxGroups(tier)),
      ),
      TierPerk(
        labelKey: perkKeyDailyConnects,
        valueText: _fmtCount(maxDailyConnects(tier)),
      ),
      TierPerk(
        labelKey: perkKeyBoostsPerMonth,
        valueText: '${boostsPerMonth(tier)}',
      ),
      TierPerk(
        labelKey: perkKeyBoostedVisible,
        valueText: '${maxBoostedVisible(tier)}',
      ),
      TierPerk(
        labelKey: perkKeyMonthlyCoins,
        valueText: '${monthlyCoins(tier)}',
      ),
      TierPerk(
        labelKey: perkKeySearchFilters,
        valueText: _fmtFilterLevel(searchFilterLevel(tier)),
      ),
      TierPerk(
        labelKey: perkKeySeeWhoConnected,
        valueText: _fmtBool(canSeeWhoConnected(tier)),
        enabled: canSeeWhoConnected(tier),
      ),
      TierPerk(
        labelKey: perkKeyTravelMode,
        valueText: _fmtBool(travelModeEnabled(tier)),
        enabled: travelModeEnabled(tier),
      ),
      // Flat for every tier: 5 coins per translation (no discount, no quota).
      const TierPerk(
        labelKey: perkKeyTtsCost,
        valueText: '$ttsCostCoins coins per translation',
      ),
      TierPerk(
        labelKey: perkKeyPrioritySupport,
        valueText: _fmtBool(prioritySupport(tier)),
        enabled: prioritySupport(tier),
      ),
    ];
  }
}
