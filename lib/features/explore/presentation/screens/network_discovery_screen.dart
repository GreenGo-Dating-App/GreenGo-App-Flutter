import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/flavor_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/blocked_users_service.dart';
import '../../../../core/services/interaction_log_service.dart';
import '../../../../core/services/tier_entitlements.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../chat/presentation/connect_and_chat.dart';
import '../../../coins/domain/repositories/coin_repository.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../business/presentation/screens/business_storefront_screen.dart';
import '../../../coins/presentation/screens/coin_shop_screen.dart';
import '../../../discovery/data/datasources/discovery_remote_datasource.dart';
import '../../../discovery/domain/entities/match_preferences.dart';
import '../../../discovery/presentation/screens/discovery_preferences_screen.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../discovery/presentation/widgets/network_grid_card.dart';
import '../../../globe_explore/presentation/bloc/globe_bloc.dart';
import '../../../globe_explore/presentation/screens/globe_screen.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../../matching/domain/entities/match_score.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../profile/data/datasources/people_tags_service.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/widgets/people_tags_editor.dart';
import '../../../saved_searches/data/saved_searches_service.dart';
import '../../../saved_searches/presentation/screens/saved_searches_screen.dart';

/// A full-screen, Apple-safe people directory reached from the Explore
/// "Network Discovery → See all" action.
///
/// This is an exact structural replica of the 2.2.4 discovery GRID (edge-to-edge
/// zero-spacing tiles, the user's own "You" card first, distance-ordered
/// candidates) built entirely from [NetworkGridCard]. It reuses
/// [DiscoveryRemoteDataSource.getDiscoveryStack] (which already applies
/// boost/ghost/blocked/hidden rules and returns candidates ordered nearest
/// first) purely to source and order people — there is deliberately NO swipe
/// deck, NO like / super-like / nope, and NO "match" anywhere.
///
/// Gestures per tile: tapping the PHOTO opens a chat immediately (no approval);
/// tapping the NAME opens the read-only [ProfileDetailScreen]; long-pressing
/// opens the PRIVATE people-tags editor.
class NetworkDiscoveryScreen extends StatefulWidget {
  const NetworkDiscoveryScreen({
    required this.userId,
    this.initialInterests,
    this.initialPreferences,
    this.initialTags,
    this.initialQuery,
    this.businessOnly = false,
    super.key,
  });

  final String userId;

  /// When true, the grid shows ONLY business accounts (profiles with
  /// `isBusiness == true`). Passed by Explore's "Business accounts → See all".
  final bool businessOnly;

  /// When non-null and non-empty, the grid opens PRE-FILTERED by these
  /// interests (seeded into the discovery [MatchPreferences] on load). Passed by
  /// Explore's "People with your same interests → See all" so the full grid
  /// reflects the same interest filter. Null = no seeded filter (default).
  final List<String>? initialInterests;

  /// Seeds used when RE-RUNNING a saved search: the full discovery filters, the
  /// selected private people-tags and the nickname query captured when the
  /// search was saved. When [initialPreferences] is non-null it wins over the
  /// user's persisted preferences for this session (the saved search "Run"
  /// re-applies exactly what was saved). All null = normal behaviour.
  final MatchPreferences? initialPreferences;
  final List<String>? initialTags;
  final String? initialQuery;

  @override
  State<NetworkDiscoveryScreen> createState() => _NetworkDiscoveryScreenState();
}

class _NetworkDiscoveryScreenState extends State<NetworkDiscoveryScreen> {
  /// How many tiles to reveal per page as the user scrolls (client-side
  /// progressive reveal over the full distance-ordered pool).
  static const int _pageSize = 30;

  /// Pre-tier fallback free-reveal ceiling, used only until the user's tier is
  /// resolved on load (then replaced by [TierEntitlements.discoveryFreeReveal]).
  static const int kFreeRevealLimit = 30; // adjustable
  /// Coins charged each time the user chooses to raise the discovery limit.
  static const int kCoinsToSeeMore = 20; // adjustable
  /// How many extra profiles a single coin-spend unlocks.
  static const int kRevealChunk = 20; // adjustable

  // null == still loading; empty == loaded but nothing to show. Excludes self.
  List<MatchCandidate>? _candidates;
  // Instant AppBar toggle: null follows the persisted/one-shot default
  // (_businessOnly); true = show businesses, false = show normal profiles.
  bool? _businessModeOverride;
  // The current user's own tile, rendered first with the gold "You" state.
  MatchCandidate? _selfCandidate;
  bool _hadError = false;

  // Endless-scroll cursor over the (filtered) pool.
  int _visibleCount = _pageSize;
  final ScrollController _scrollController = ScrollController();

  // Discovery reveal ceiling. Auto-reveal stops here; the user raises it by
  // spending coins. Seeded from the pre-tier fallback, then set to the user's
  // per-membership-tier free-reveal allotment once [_loadRevealCap] resolves.
  int _revealCap = kFreeRevealLimit;
  // Guards against double-charging while a coin-spend is in flight.
  bool _spending = false;

  // Nickname search (top-bar). Empty query shows everyone.
  bool _searching = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  // REAL exact-nickname lookup against the whole `profiles` collection (not just
  // the loaded pool). Debounced on change, also fired on submit. The found
  // person is wrapped in a [MatchCandidate] and pinned at the top of the grid so
  // the user can chat with them even if they are outside the discovery pool.
  Timer? _searchDebounce;
  MatchCandidate? _nicknameResult;
  bool _nicknameLoading = false;
  // Monotonic counter used to discard stale async lookups (a later keystroke or
  // a cleared box must win over an in-flight query).
  int _searchGeneration = 0;

  // The user's full discovery filters (the 2.2.4 preference model), loaded from
  // Firestore on init and re-loaded whenever the settings icon returns an edited
  // copy. Drives the candidate query via [getDiscoveryStack]. Null until the
  // first load completes; [_effectivePreferences] supplies a safe default.
  MatchPreferences? _preferences;

  /// Whether the "My Network" filter is on — sourced from the saved preferences.
  bool get _showMyNetwork => _preferences?.showMyNetwork ?? false;

  // Lazily loaded set of the user's network (people they've chatted with). Only
  // fetched the first time "My Network" is switched on — bounded, per-user,
  // index-free queries.
  Set<String>? _networkIds;

  // Per-user PRIVATE people tags (targetUserId -> tags) and the active filter.
  // Only the current user ever sees these; selecting chips filters the grid.
  final _tagsService = PeopleTagsService();
  StreamSubscription<Map<String, List<String>>>? _tagsSub;
  Map<String, List<String>> _peopleTags = const {};
  final Set<String> _selectedTags = {};

  /// Whether the grid shows ONLY business accounts. Sourced from the opener
  /// (Explore's Business accounts → See all passes `businessOnly: true` as a
  /// one-shot) OR from the persisted Discovery preference (the toggle now lives
  /// in Discovery preferences, not an in-screen chip).
  bool get _businessOnly =>
      widget.businessOnly || (_preferences?.businessOnly ?? false);

  @override
  void initState() {
    super.initState();
    // Re-running a saved search: seed the selected people-tags and the nickname
    // query so the grid opens exactly as it was saved. (Preferences are seeded
    // in [_loadPreferences].) Any seeded tag that no longer exists is dropped by
    // the people-tags subscription below.
    final seedTags = widget.initialTags;
    if (seedTags != null && seedTags.isNotEmpty) {
      _selectedTags.addAll(seedTags);
    }
    final seedQuery = widget.initialQuery;
    if (seedQuery != null && seedQuery.trim().isNotEmpty) {
      _query = seedQuery;
      _searchController.text = seedQuery;
      _searching = true;
    }
    _init();
    _scrollController.addListener(_onScroll);
    _tagsSub = _tagsService.watchAll(widget.userId).listen((tags) {
      if (!mounted) return;
      setState(() {
        _peopleTags = tags;
        // Drop any selected tag that no longer exists.
        final all = tags.values.expand((t) => t).toSet();
        _selectedTags.removeWhere((t) => !all.contains(t));
      });
    });
    // Remove a blocked person from the grid the instant a block happens anywhere.
    _blockedSub = di.sl<BlockedUsersService>().onUserBlocked.listen((id) {
      if (!mounted) return;
      final list = _candidates;
      if (list == null) return;
      setState(() {
        _candidates =
            list.where((c) => c.profile.userId != id).toList();
      });
    });
  }

  StreamSubscription<String>? _blockedSub;

  @override
  void dispose() {
    _tagsSub?.cancel();
    _blockedSub?.cancel();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      final total = _visibleList().length;
      // Never auto-reveal past the current reveal cap — spending coins is what
      // raises it. The coin CTA takes over once the cap is reached.
      final ceiling = total < _revealCap ? total : _revealCap;
      if (_visibleCount < ceiling) {
        setState(() => _visibleCount =
            (_visibleCount + _pageSize).clamp(0, ceiling));
      }
    }
  }

  /// All distinct tags the owner has applied across people, sorted.
  List<String> get _allTags {
    final set = <String>{};
    for (final list in _peopleTags.values) {
      set.addAll(list);
    }
    final out = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  /// A person passes the tag filter if no tags are selected, or they carry any
  /// of the selected tags (OR semantics).
  bool _matchesTagFilter(String targetUserId) {
    if (_selectedTags.isEmpty) return true;
    final tags = _peopleTags[targetUserId];
    if (tags == null) return false;
    return tags.any(_selectedTags.contains);
  }

  /// The filtered candidate list (tags + nickname search + optional network),
  /// excluding the self tile which is pinned separately at index 0.
  /// Whether Discovery is currently showing BUSINESSES (vs normal profiles).
  /// The instant AppBar toggle overrides the persisted/one-shot default.
  bool get _effectiveShowBusinesses => _businessModeOverride ?? _businessOnly;

  List<MatchCandidate> _visibleList() {
    final all = _candidates ?? const <MatchCandidate>[];
    final q = _query.trim().toLowerCase();
    final networkIds = _networkIds;
    final showBusinesses = _effectiveShowBusinesses;
    final list = all.where((c) {
      // Business vs normal-profile split (instant, client-side).
      if (c.profile.isBusiness != showBusinesses) return false;
      if (!_matchesTagFilter(c.profile.userId)) return false;
      if (_showMyNetwork &&
          networkIds != null &&
          !networkIds.contains(c.profile.userId)) {
        return false;
      }
      if (q.isNotEmpty && !c.displayName.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
    // In business mode, promoted storefronts float to the top. Partition (not
    // sort) so the existing distance order is preserved within each group — the
    // pool is already closest-first, so promoted stay closest-first too.
    if (showBusinesses) {
      final promoted = <MatchCandidate>[];
      final rest = <MatchCandidate>[];
      for (final c in list) {
        (c.profile.isBusinessPromoted ? promoted : rest).add(c);
      }
      // At most 5 promoted float to the very top (the closest, since the pool is
      // distance-ordered); any beyond 5 fall back into normal distance order.
      if (promoted.length > 5) {
        rest.insertAll(0, promoted.sublist(5));
        return [...promoted.sublist(0, 5), ...rest];
      }
      return [...promoted, ...rest];
    }
    return list;
  }

  /// Whether the self tile is currently shown (hidden only when a search query
  /// excludes it, or while filtering by network).
  bool get _showSelf {
    final self = _selfCandidate;
    if (self == null) return false;
    if (_showMyNetwork) return false;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !self.displayName.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }

  /// Loads the user's saved discovery filters from Firestore, then loads the
  /// candidate pool. If "My Network" was already on when the screen opens, its
  /// network set is warmed up first so the very first grid honours the filter.
  Future<void> _init() async {
    await _loadRevealCap();
    if (!mounted) return;
    await _loadPreferences();
    if (!mounted) return;
    if (_showMyNetwork) await _ensureNetworkIds();
    if (!mounted) return;
    await _load();
  }

  /// Resolves the user's membership tier from `profiles/{uid}.membershipTier`
  /// and sets the starting reveal ceiling from
  /// [TierEntitlements.discoveryFreeReveal] (Base 30 / Silver 100 / Gold 300 /
  /// Platinum ≈∞). The coins-to-see-more flow still raises it beyond that.
  Future<void> _loadRevealCap() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();
      final raw = doc.data()?['membershipTier'] as String?;
      final tier =
          raw == null ? MembershipTier.free : MembershipTier.fromString(raw);
      if (!mounted) return;
      setState(() => _revealCap = TierEntitlements.discoveryFreeReveal(tier));
    } catch (_) {
      // Non-fatal — keep the pre-tier fallback (kFreeRevealLimit).
    }
  }

  /// Reads the saved [MatchPreferences] from `users/{uid}.matchPreferences`
  /// (the same document [DiscoveryPreferencesScreen] persists to) so the full
  /// 2.2.4 filters persist across sessions. Falls back to sensible defaults.
  Future<void> _loadPreferences() async {
    // Re-running a saved search: adopt the saved filters verbatim (they win over
    // the user's persisted preferences for this session) and skip the remote
    // load entirely.
    final seededPrefs = widget.initialPreferences;
    if (seededPrefs != null) {
      _preferences = seededPrefs;
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final raw = doc.data()?['matchPreferences'];
      if (raw is Map) {
        _preferences =
            MatchPreferences.fromMap(Map<String, dynamic>.from(raw));
      }
    } catch (_) {
      // Non-fatal — fall back to defaults via [_effectivePreferences].
    }
    // Opened pre-filtered from Explore ("same interests → See all"): seed the
    // discovery filters with those interests so the grid honours them from the
    // first load (and [_preferences] reflects them across settings round-trips).
    final seed = widget.initialInterests;
    if (seed != null && seed.isNotEmpty) {
      final base = _preferences ?? MatchPreferences.defaultFor(widget.userId);
      _preferences = base.copyWith(preferredInterests: seed);
    }
  }

  /// The saved filters merged with the rules this Apple-safe grid always
  /// enforces: the official GreenGo account stays hidden, and in the culture
  /// flavor age is never a filter (age range is a dating signal — hidden from
  /// the UI and forced to the full 18–99 span so it excludes no one).
  MatchPreferences get _effectivePreferences {
    final base = _preferences ?? MatchPreferences.defaultFor(widget.userId);
    return base.copyWith(
      showSupportUser: false,
      minAge: FlavorConfig.enableMatching ? base.minAge : 18,
      maxAge: FlavorConfig.enableMatching ? base.maxAge : 99,
    );
  }

  Future<void> _load() async {
    try {
      // Load the current user's own profile (for the "You" tile) in parallel
      // with the distance-ordered discovery pool.
      final ds = di.sl<DiscoveryRemoteDataSource>();
      final preferences = _effectivePreferences;

      final results = await Future.wait<Object?>([
        di.sl<ProfileRepository>().getProfile(widget.userId),
        ds.getDiscoveryStack(
          userId: widget.userId,
          preferences: preferences,
          limit: 500,
        ),
      ]);

      // Build the self candidate from the loaded profile.
      final selfEither = results[0];
      Profile? selfProfile;
      // ProfileRepository.getProfile returns Either<Failure, Profile>.
      try {
        selfProfile = (selfEither as dynamic).fold(
          (_) => null,
          (p) => p as Profile,
        ) as Profile?;
      } catch (_) {
        selfProfile = null;
      }

      final list = (results[1] as List<MatchCandidate>)
          // Defensive client-side filter: never render admin/support accounts.
          .where((c) => !c.profile.isAdmin && !c.profile.isSupport)
          // Never render the user's own tile inside the pool (it is pinned).
          .where((c) => c.profile.userId != widget.userId)
          // NOTE: the business vs normal-profile split is applied at DISPLAY
          // time in _visibleList() so the AppBar toggle switches instantly with
          // no reload (the full pool is kept here).
          .toList();

      if (!mounted) return;
      setState(() {
        _selfCandidate =
            selfProfile != null ? _selfCandidateFor(selfProfile) : null;
        _candidates = list;
        _visibleCount = _pageSize;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hadError = true;
          _candidates = const <MatchCandidate>[];
        });
      }
    }
  }

  /// Wraps the current user's own [Profile] into a [MatchCandidate] rendered
  /// with the gold "You" state (score/distance are irrelevant for self).
  MatchCandidate _selfCandidateFor(Profile profile) {
    final now = DateTime.now();
    return MatchCandidate(
      profile: profile,
      matchScore: MatchScore(
        userId1: widget.userId,
        userId2: widget.userId,
        overallScore: 0,
        breakdown: const ScoreBreakdown(
          locationScore: 0,
          ageCompatibilityScore: 0,
          interestOverlapScore: 0,
        ),
        calculatedAt: now,
      ),
      distance: 0,
      suggestedAt: now,
    );
  }

  /// Lazily loads the user's network — the set of people they have actually
  /// exchanged messages with — from the `conversations` collection. Uses two
  /// bounded, single-field, index-free queries (`userId1 == uid` and
  /// `userId2 == uid`, the canonical 1:1 conversation schema used across the
  /// app), collecting the OTHER participant from each. Cached after the first
  /// fetch. This is "people I've chatted with", not matches.
  Future<void> _ensureNetworkIds() async {
    if (_networkIds != null) return;
    final ids = <String>{};
    try {
      final firestore = FirebaseFirestore.instance;
      final snaps = await Future.wait([
        firestore
            .collection('conversations')
            .where('userId1', isEqualTo: widget.userId)
            .get(),
        firestore
            .collection('conversations')
            .where('userId2', isEqualTo: widget.userId)
            .get(),
      ]);
      for (final snap in snaps) {
        for (final doc in snap.docs) {
          final data = doc.data();
          final u1 = data['userId1'] as String?;
          final u2 = data['userId2'] as String?;
          if (u1 != null && u1 != widget.userId) ids.add(u1);
          if (u2 != null && u2 != widget.userId) ids.add(u2);
        }
      }
    } catch (_) {
      // Non-fatal — an empty network simply shows nothing under the toggle.
    }
    _networkIds = ids;
  }

  // ── Top-bar actions ────────────────────────────────────────────────────────

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _searchController.clear();
        // Closing the box drops any in-flight/queued lookup and its result.
        _searchDebounce?.cancel();
        _searchGeneration++;
        _nicknameResult = null;
        _nicknameLoading = false;
      }
    });
  }

  /// Handles every keystroke in the search box: it filters the loaded pool live
  /// (via [_query]) AND debounces a REAL exact-nickname lookup against the whole
  /// `profiles` collection. An empty box clears the remote result immediately.
  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _visibleCount = _pageSize;
    });
    _searchDebounce?.cancel();
    final nickname = value.trim().toLowerCase();
    if (nickname.isEmpty) {
      // Invalidate any pending lookup and clear the remote result.
      _searchGeneration++;
      setState(() {
        _nicknameResult = null;
        _nicknameLoading = false;
      });
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _runNicknameLookup(nickname),
    );
  }

  /// Runs the exact-nickname Firestore lookup (same query the discovery nickname
  /// dialog uses) and, if a valid person is found, wraps them in a
  /// [MatchCandidate] pinned to the top of the grid so they are chat-able even
  /// when outside the loaded discovery pool. Excludes the current user, ghost
  /// mode and admin/support accounts. Guarded by [_searchGeneration] so a stale
  /// response (older keystroke, cleared box, or a changed query) never applies.
  Future<void> _runNicknameLookup(String nickname) async {
    final generation = ++_searchGeneration;
    if (!mounted) return;
    // Interaction logging (fire-and-forget, never throws): record the nickname
    // search so the backend can build recommendations.
    di.sl<InteractionLogService>().logSearch(widget.userId, nickname);
    setState(() => _nicknameLoading = true);

    MatchCandidate? result;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final profile = ProfileModel.fromFirestore(snapshot.docs.first);
        final excluded = profile.userId == widget.userId ||
            profile.isGhostMode ||
            profile.isAdmin ||
            profile.isSupport;
        if (!excluded) {
          result = _candidateFor(profile);
        }
      }
    } catch (_) {
      result = null;
    }

    if (!mounted) return;
    // Stale-guard: a newer lookup (or a cleared box) has superseded this one, or
    // the live query no longer matches what we searched for → drop the result.
    if (generation != _searchGeneration) return;
    if (_query.trim().toLowerCase() != nickname) return;
    setState(() {
      _nicknameResult = result;
      _nicknameLoading = false;
    });
  }

  /// Wraps an arbitrary found [Profile] into a zero-score [MatchCandidate] so it
  /// renders as a normal [NetworkGridCard] with the Apple-safe gestures.
  MatchCandidate _candidateFor(Profile profile) {
    final now = DateTime.now();
    return MatchCandidate(
      profile: profile,
      matchScore: MatchScore(
        userId1: widget.userId,
        userId2: profile.userId,
        overallScore: 0,
        breakdown: const ScoreBreakdown(
          locationScore: 0,
          ageCompatibilityScore: 0,
          interestOverlapScore: 0,
        ),
        calculatedAt: now,
      ),
      distance: 0,
      suggestedAt: now,
    );
  }

  /// Opens the FULL 2.2.4 discovery filter UI ([DiscoveryPreferencesScreen]).
  /// That screen persists the edited [MatchPreferences] to
  /// `users/{uid}.matchPreferences` and pops the saved copy back. On return we
  /// adopt it, warm the "My Network" set if that filter is now on, and reload
  /// the candidate pool through [getDiscoveryStack] so every filter (age in the
  /// full flavor, distance, languages, interests, countries, online-now,
  /// verified, recently-active, sort-by-distance) takes effect immediately.
  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<MatchPreferences>(
      MaterialPageRoute<MatchPreferences>(
        builder: (_) => DiscoveryPreferencesScreen(
          userId: widget.userId,
          currentPreferences: _preferences,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _preferences = result;
      // The candidate pool depends on the filters → clear it and re-fetch.
      _candidates = null;
      _visibleCount = _pageSize;
    });

    if (_showMyNetwork) await _ensureNetworkIds();
    if (!mounted) return;

    await _load();
  }

  // ── Saved searches ─────────────────────────────────────────────────────────

  /// Captures the CURRENT filter state (discovery preferences + selected private
  /// people-tags + nickname query) and persists it as a named saved search after
  /// prompting for a name. Confirms with a snackbar.
  Future<void> _onSaveThisSearch() async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _promptSearchName(l10n);
    if (name == null || name.trim().isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      // Persist the user's true selection (not [_effectivePreferences], whose
      // Apple-safe overrides are re-applied on load anyway).
      final prefs = _preferences ?? MatchPreferences.defaultFor(widget.userId);
      await di.sl<SavedSearchesService>().save(
            userId: widget.userId,
            name: name.trim(),
            preferences: prefs,
            tags: _selectedTags.toList(),
            query: _query.trim(),
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.savedSearchSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
    }
  }

  /// Small glass-styled name prompt for a new saved search.
  Future<String?> _promptSearchName(AppLocalizations l10n) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.saveThisSearch,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.richGold,
          decoration: InputDecoration(
            hintText: l10n.savedSearchesTitle,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
            child: Text(
              l10n.save,
              style: const TextStyle(color: AppColors.deepBlack),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the list of the user's saved searches.
  void _openSavedSearches() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedSearchesScreen(userId: widget.userId),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.richGold,
                decoration: InputDecoration(
                  hintText: l10n.searchByNameOrNickname,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (v) {
                  _searchDebounce?.cancel();
                  final nickname = v.trim().toLowerCase();
                  if (nickname.isEmpty) return;
                  _runNicknameLookup(nickname);
                },
              )
            // No title on the Discover page (removed per request). The
            // "Business accounts → See all" one-shot still labels its grid.
            : (widget.businessOnly
                ? Text(
                    l10n.exploreBusinessAccounts,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const SizedBox.shrink()),
        actions: [
          // Instant People ⇄ Businesses toggle (no reload — filters the pool).
          if (!_searching)
            IconButton(
              icon: Icon(_effectiveShowBusinesses
                  ? Icons.storefront
                  : Icons.people_alt_outlined),
              tooltip: _effectiveShowBusinesses
                  ? l10n.discoveryShowPeople
                  : l10n.discoveryShowBusinesses,
              color: _effectiveShowBusinesses ? AppColors.richGold : null,
              onPressed: () {
                setState(() {
                  _businessModeOverride = !_effectiveShowBusinesses;
                  _visibleCount = _pageSize;
                });
              },
            ),
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: l10n.searchByNicknameTooltip,
            onPressed: _toggleSearch,
          ),
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: l10n.settings,
              onPressed: _openSettings,
            ),
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.public),
              tooltip: l10n.networkWorldMap,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) => di.sl<GlobeBloc>(),
                    child: GlobeScreen(userId: widget.userId),
                  ),
                ),
              ),
            ),
          if (!_searching)
            PopupMenuButton<String>(
              icon: const Icon(Icons.bookmark_border),
              tooltip: l10n.savedSearchesTitle,
              color: AppColors.backgroundCard,
              onSelected: (value) {
                if (value == 'save') {
                  _onSaveThisSearch();
                } else if (value == 'list') {
                  _openSavedSearches();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'save',
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_add_outlined,
                          color: AppColors.richGold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.saveThisSearch,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'list',
                  child: Row(
                    children: [
                      const Icon(Icons.bookmarks_outlined,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.savedSearchesTitle,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _tagFilterBar(),
            Expanded(child: _body(context, l10n, reduceMotion)),
          ],
        ),
      ),
    );
  }

  /// Horizontal, overflow-safe filter chips of the owner's own people tags.
  /// Hidden entirely until the owner has tagged at least one person. Selecting
  /// chips narrows the grid to people carrying any selected tag (OR).
  Widget _tagFilterBar() {
    final tags = _allTags;
    if (tags.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final allSelected = _selectedTags.isEmpty;
    return Padding(
      // Breathing room above and (more) below the filter, before the grid.
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          // "All" clears every tag filter and shows the whole pool.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.filterAll),
              selected: allSelected,
              showCheckmark: false,
              selectedColor: AppColors.richGold,
              backgroundColor: AppColors.charcoal,
              side: BorderSide(color: AppGlass.border),
              labelStyle: TextStyle(
                color: allSelected
                    ? AppColors.deepBlack
                    : AppColors.textSecondary,
              ),
              onSelected: (_) {
                if (_selectedTags.isEmpty) return;
                setState(() {
                  _selectedTags.clear();
                  _visibleCount = _pageSize;
                });
              },
            ),
          ),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(tag),
                selected: _selectedTags.contains(tag),
                showCheckmark: false,
                selectedColor: AppColors.richGold,
                backgroundColor: AppColors.charcoal,
                side: BorderSide(color: AppGlass.border),
                labelStyle: TextStyle(
                  color: _selectedTags.contains(tag)
                      ? AppColors.deepBlack
                      : AppColors.textSecondary,
                ),
                onSelected: (sel) => setState(() {
                  if (sel) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                  _visibleCount = _pageSize;
                }),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    // Edge-to-edge 3-column grid with PORTRAIT people tiles (5:7) to match the
    // Explore page's 150×210 person cards. NetworkGridCard keeps its own rounded
    // corners for a "bit rounded" look.
    const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 3,
      mainAxisSpacing: 3,
      childAspectRatio: 5 / 7,
    );

    final candidates = _candidates;

    // Loading — a grid of skeleton tiles.
    if (candidates == null) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: gridDelegate,
        itemCount: 9,
        itemBuilder: (_, __) => _CandidateSkeleton(animate: !reduceMotion),
      );
    }

    // The REAL exact-nickname match (only while searching), pinned above the
    // loaded pool and deduped so it never renders twice.
    final nicknameCandidate = _searching ? _nicknameResult : null;
    final filtered = _visibleList()
        .where((c) =>
            nicknameCandidate == null ||
            c.profile.userId != nicknameCandidate.profile.userId)
        .toList();
    final showSelf = _showSelf;
    final query = _query.trim();
    final isSearchingQuery = _searching && query.isNotEmpty;

    // Loaded but empty (or errored, or filtered to nothing).
    if (filtered.isEmpty && !showSelf && nicknameCandidate == null) {
      // A remote nickname lookup is still in flight → subtle spinner, not a
      // premature "no profile found" message.
      if (isSearchingQuery && _nicknameLoading) {
        return const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.richGold,
            ),
          ),
        );
      }
      final message = _hadError
          ? l10n.exploreMapError
          : isSearchingQuery
              ? l10n.nicknameSearchNoProfile(query)
              : (candidates.isEmpty
                  ? l10n.exploreNoPartners
                  : l10n.groupNoSearchResults);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    // The reveal cap gates how far the endless scroll can progress. Auto-reveal
    // stops at [_revealCap]; beyond it the user must spend coins to see more.
    final cappedCount =
        _visibleCount < _revealCap ? _visibleCount : _revealCap;
    final revealed = filtered.take(cappedCount).toList();
    final moreBeyondRevealed = filtered.length > revealed.length;
    final reachedCap = revealed.length >= _revealCap;
    // Still more to progressively reveal within the current cap → spinner.
    final hasMore = moreBeyondRevealed && !reachedCap;
    // At the discovery limit with more candidates waiting → coin-gated prompt.
    final showLimitCta = moreBeyondRevealed && reachedCap;
    // Leading tiles: the pinned nickname match (if any) first, then the "You"
    // tile. Both sit above the distance-ordered pool.
    final nicknameLeading = nicknameCandidate != null ? 1 : 0;
    final selfLeading = showSelf ? 1 : 0;
    final leading = nicknameLeading + selfLeading;
    final footer = hasMore ? 1 : 0;
    final itemCount = leading + revealed.length + footer;

    return Column(
      children: [
        // Subtle in-flight indicator while a remote nickname lookup runs even
        // though some loaded candidates already match the query.
        if (isSearchingQuery && _nicknameLoading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.richGold,
            backgroundColor: Colors.transparent,
          ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            gridDelegate: gridDelegate,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Loading footer tile (endless-scroll spinner).
              if (hasMore && index == itemCount - 1) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.richGold,
                      ),
                    ),
                  ),
                );
              }

              // The REAL exact-nickname match, pinned first. A normal
              // NetworkGridCard → tapping its photo opens a chat immediately.
              if (nicknameCandidate != null && index == 0) {
                return _tile(nicknameCandidate, isSelf: false);
              }

              // The user's own "You" tile, pinned next.
              if (showSelf && index == nicknameLeading) {
                return _tile(_selfCandidate!, isSelf: true);
              }

              final candidate = revealed[index - leading];
              return _tile(candidate, isSelf: false);
            },
          ),
        ),
        if (showLimitCta) _seeMoreBanner(l10n),
      ],
    );
  }

  /// Bottom "discovery limit reached" prompt inviting the user to spend coins to
  /// reveal more profiles. Glass-styled, overflow-safe, Apple-safe wording.
  Widget _seeMoreBanner(AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: GlassContainer(
          active: true,
          padding: const EdgeInsets.all(14),
          onTap: _spending ? null : _onSpendCoinsToSeeMore,
          child: Row(
            children: [
              const Icon(Icons.lock_open_rounded,
                  color: AppColors.richGold, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.discoveryLimitReached,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.discoverySeeMoreCoins(kCoinsToSeeMore),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (_spending)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.richGold,
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.richGold, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Charges [kCoinsToSeeMore] coins and raises the reveal cap by
  /// [kRevealChunk]. Reuses the coin system's `purchaseFeature` spend path (the
  /// same one used for direct-message / super-like), tagged with a clear feature
  /// name so it is auditable in the transaction history. If the user cannot
  /// afford it, routes them to the coin shop.
  Future<void> _onSpendCoinsToSeeMore() async {
    if (_spending) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _spending = true);
    try {
      final coinRepository = di.sl<CoinRepository>();
      final balanceResult = await coinRepository.getBalance(widget.userId);
      if (!mounted) return;

      final hasEnough = balanceResult.fold(
        (_) => false,
        (balance) => balance.availableCoins >= kCoinsToSeeMore,
      );

      if (!hasEnough) {
        setState(() => _spending = false);
        _showInsufficientCoinsDialog();
        return;
      }

      final spendResult = await coinRepository.purchaseFeature(
        userId: widget.userId,
        featureName: 'discovery_see_more',
        cost: kCoinsToSeeMore,
      );
      if (!mounted) return;

      spendResult.fold(
        (failure) {
          setState(() => _spending = false);
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.somethingWentWrong)),
          );
        },
        (_) {
          setState(() {
            _revealCap += kRevealChunk;
            // Let the newly unlocked profiles reveal immediately.
            _visibleCount = _revealCap;
            _spending = false;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _spending = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
    }
  }

  /// Insufficient-coins dialog that mirrors the app's existing pattern and
  /// routes the user to the coin shop.
  void _showInsufficientCoinsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.insufficientCoinsTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.discoverySeeMoreCoins(kCoinsToSeeMore),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) => di.sl<CoinBloc>()
                      ..add(LoadCoinBalance(widget.userId))
                      ..add(const LoadAvailablePackages()),
                    child: CoinShopScreen(userId: widget.userId),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold),
            child: Text(
              l10n.buyCoinsBtnLabel,
              style: const TextStyle(color: AppColors.deepBlack),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds one [NetworkGridCard] wired to the Apple-safe gestures.
  Widget _tile(MatchCandidate candidate, {required bool isSelf}) {
    final profile = candidate.profile;
    // Business accounts get the same premium effect as Explore's Featured
    // community-event card: a gold-framed tile that opens the public
    // storefront (on BOTH photo and name taps) instead of chat/profile.
    final isBusiness = !isSelf && profile.isBusiness;
    void openStorefront() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BusinessStorefrontScreen(
            business: profile,
            currentUserId: widget.userId,
          ),
        ),
      );
    }

    return NetworkGridCard(
      candidate: candidate,
      isSelf: isSelf,
      isBusiness: isBusiness,
      // Chat always opens a NORMAL 1:1 chat — even when the target is a business
      // account (you're messaging the person). Business chat is reached only via
      // the storefront's Contact button (open the profile card → storefront).
      onOpenChat: isSelf
          ? () {}
          : () => openConnectChat(
                context,
                currentUserId: widget.userId,
                otherUserId: profile.userId,
                otherUserProfile: profile,
              ),
      onOpenProfile: () {
        if (isBusiness) {
          openStorefront();
          return;
        }
        // Interaction logging (fire-and-forget, never throws): a profile-card
        // open in the discovery grid feeds the recommendation signal (skip the
        // user's own "You" tile).
        if (!isSelf) {
          di.sl<InteractionLogService>()
              .logProfileView(widget.userId, profile.userId);
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProfileDetailScreen(
              profile: profile,
              currentUserId: widget.userId,
            ),
          ),
        );
      },
      onLongPressTag: isSelf
          ? () {}
          : () => showPeopleTagsEditor(
                context,
                ownerId: widget.userId,
                targetUserId: profile.userId,
                targetName: candidate.displayName,
              ),
    );
  }
}

/// A pulsing skeleton tile shown while candidates load. Static when the user
/// prefers reduced motion. Zero-radius to sit flush in the edge-to-edge grid.
class _CandidateSkeleton extends StatefulWidget {
  const _CandidateSkeleton({required this.animate});

  final bool animate;

  @override
  State<_CandidateSkeleton> createState() => _CandidateSkeletonState();
}

class _CandidateSkeletonState extends State<_CandidateSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(color: AppGlass.surfaceHi),
    );
    if (_controller == null) {
      return Opacity(opacity: 0.5, child: box);
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.7).animate(_controller!),
      child: box,
    );
  }
}
