import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/interaction_log_service.dart';
import '../../../../core/utils/language_flags.dart';
import '../../../../generated/app_localizations.dart';
import '../utils/community_l10n.dart';
import '../../../app_tour/presentation/tour_controller.dart';
import '../../../app_tour/presentation/tour_keys.dart';
import '../../../app_tour/presentation/widgets/gesture_glyphs.dart';
import '../../../app_tour/presentation/widgets/tour_showcase.dart';
import '../../../app_tour/presentation/widgets/tour_trigger.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../data/datasources/community_favorites_service.dart';
import '../../domain/community_language.dart';
import '../../domain/joined_favorites.dart';
import '../../domain/entities/community.dart';
import '../bloc/communities_bloc.dart';
import '../bloc/communities_event.dart';
import '../bloc/communities_state.dart';
import '../widgets/community_card.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';
import '../../../../core/widgets/helpful_empty_state.dart';

const int _kJoinedTab = 0;
const int _kDiscoverTab = 1;
const int _kManagedTab = 2;

/// Communities Screen
///
/// Main screen for the communities feature with three tabs, in this order:
/// Joined communities (default), Discover, My communities (created/managed).
/// On Joined, starred favorites are pinned on top (newest starred first, at
/// most [CommunityFavoritesService.maxFavorites]), then the rest, revealed
/// page by page as the user scrolls.
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({
    super.key,
    this.initialTab = _kJoinedTab,
    this.currentUserId,
    this.favoritesService,
  });

  /// Tab to open on. Defaults to Joined; callers may pass
  /// [CommunitiesScreen.discoverTab] / [CommunitiesScreen.managedTab].
  final int initialTab;

  /// Defaults to the signed-in Firebase user (tests pass one).
  final String? currentUserId;

  /// Defaults to [CommunityFavoritesService] (tests inject a fake).
  final CommunityFavoritesService? favoritesService;

  // Tab order (product spec): Joined, Discover, My communities.
  static const int joinedTab = _kJoinedTab;
  static const int discoverTab = _kDiscoverTab;
  static const int managedTab = _kManagedTab;

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CommunityType? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _managedSearchController = TextEditingController();
  final TextEditingController _joinedSearchController = TextEditingController();
  final ScrollController _discoverScrollController = ScrollController();
  String _searchQuery = '';
  String _joinedSearchQuery = '';

  // Per-user favorite communities (starred on the Joined tab). Loaded once,
  // toggled optimistically, persisted via [CommunityFavoritesService]; synced
  // across devices (server-side doc). Stored in starring order (oldest
  // first); their documents are loaded SEPARATELY (bounded: <= 50) so they
  // are always pinned on top whatever part of the joined list is shown.
  late final CommunityFavoritesService _favoritesService =
      widget.favoritesService ?? CommunityFavoritesService();
  List<String> _favoriteOrder = <String>[];
  Set<String> get _favoriteIds => _favoriteOrder.toSet();
  Map<String, Community> _favoriteDocs = <String, Community>{};

  /// Joined (non-favorite) communities revealed so far; grows by
  /// [_joinedPageSize] as the user nears the end of the list.
  static const int _joinedPageSize = 20;
  int _joinedShown = _joinedPageSize;
  String _managedSearchQuery = '';
  String? _currentUserId;
  // Last good list state. Opening a community detail makes the SHARED bloc emit
  // CommunityDetailLoaded (which carries none of the Discover/Joined/My lists),
  // and on pop-back that's still the current state — which blanked all tabs.
  // We remember the last CommunitiesLoaded and render from it whenever the live
  // state isn't a list state, so the tabs never go empty.
  CommunitiesLoaded? _lastLoaded;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _tabController.addListener(_onTabChanged);
    _currentUserId =
        widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    _discoverScrollController.addListener(_onDiscoverScroll);
    _loadInitialData();
    _loadFavorites();
  }

  /// The Communities first-time guide, in display order. Unmounted targets are
  /// filtered out at start time (e.g. search/card when the Joined tab is empty).
  static List<GlobalKey> get _communitiesTourKeys => [
        TourKeys.communitiesTabs,
        TourKeys.communitiesSearch,
        TourKeys.communitiesCard,
        TourKeys.communitiesCreate,
      ];

  /// Replay the page guide (from the "?" app-bar button). Jumps to the Joined
  /// tab ([_kJoinedTab]) first so the search + card steps have something to anchor to.
  void _replayTour(BuildContext showcaseContext) {
    if (_tabController.index != _kJoinedTab) {
      _tabController.animateTo(_kJoinedTab);
    }
    // Let the Joined tab build so its showcase targets are mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        TourController.instance
            .startMiniTourNow(showcaseContext, _communitiesTourKeys);
      }
    });
  }

  /// One cheap read of the user's starred ids (single doc), then their
  /// community documents by id (<= 50, at most 2 queries).
  Future<void> _loadFavorites() async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      final ids = await _favoritesService.getOrdered(uid);
      if (!mounted) return;
      setState(() => _favoriteOrder = ids);
      final docs = await _favoritesService.loadCommunities(ids);
      if (mounted) setState(() => _favoriteDocs = docs);
    } catch (_) {
      // Non-fatal: the stars just start un-filled / unpinned.
    }
  }

  /// Optimistically toggle a favorite, then persist (revert on failure).
  /// Starring past the cap shows a friendly message instead.
  Future<void> _toggleFavorite(Community community) async {
    final uid = _currentUserId;
    if (uid == null) return;
    final id = community.id;
    final wasFavorite = _favoriteIds.contains(id);
    if (!wasFavorite &&
        _favoriteOrder.length >= CommunityFavoritesService.maxFavorites) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!
            .communitiesFavoritesLimit(CommunityFavoritesService.maxFavorites)),
      ));
      return;
    }
    final before = _favoriteOrder;
    setState(() {
      _favoriteOrder = wasFavorite
          ? [for (final x in before) if (x != id) x]
          : [...before, id];
      if (!wasFavorite) _favoriteDocs = {..._favoriteDocs, id: community};
    });
    try {
      await _favoritesService.setFavorite(uid, id, !wasFavorite);
    } catch (_) {
      if (!mounted) return;
      setState(() => _favoriteOrder = before);
    }
  }

  bool _revealScheduled = false;

  /// Shows the next [_joinedPageSize] joined communities (once per frame).
  void _revealMoreJoined() {
    if (_revealScheduled) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (mounted) setState(() => _joinedShown += _joinedPageSize);
    });
  }

  /// Leaving (or deleting) a community drops its favorite, here and on the
  /// server, so it never comes back pinned.
  Future<void> _dropFavorite(String communityId) async {
    final uid = _currentUserId;
    if (uid == null || !_favoriteIds.contains(communityId)) return;
    setState(() {
      _favoriteOrder = [
        for (final x in _favoriteOrder)
          if (x != communityId) x
      ];
      _favoriteDocs = {..._favoriteDocs}..remove(communityId);
    });
    try {
      await _favoritesService.setFavorite(uid, communityId, false);
    } catch (_) {/* hidden anyway: not joined any more */}
  }

  bool _managedLoaded = false;

  /// Load "My communities" (created) the first time its tab is opened. Loading
  /// it lazily (instead of at init) keeps it out of the concurrent init-load
  /// race that was resetting managedCommunities back to empty.
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final userId = _currentUserId;
    if (userId == null) return;
    // Discover (0): guarantee the public list is loaded when the tab is opened
    // (it's also prefetched at init so it's usually already there).
    if (_tabController.index == _kDiscoverTab) {
      final s = context.read<CommunitiesBloc>().state;
      final hasDiscover = s is CommunitiesLoaded && s.communities.isNotEmpty;
      if (!hasDiscover) {
        context.read<CommunitiesBloc>().add(const LoadCommunities());
      }
    }
    // My communities (2): lazy-load the created list on first open.
    if (_tabController.index == _kManagedTab && !_managedLoaded) {
      _managedLoaded = true;
      context.read<CommunitiesBloc>().add(
            LoadManagedCommunities(userId: userId),
          );
    }
  }

  /// Endless scroll for the Discover tab — dispatch the next page when the user
  /// nears the bottom (guarded in the bloc against duplicate/again fetches).
  void _onDiscoverScroll() {
    if (!_discoverScrollController.hasClients) return;
    final pos = _discoverScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      context.read<CommunitiesBloc>().add(
            LoadMoreCommunities(
              type: _selectedFilter,
              searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
            ),
          );
    }
  }

  /// Re-fetch the community lists (after create/join/leave).
  void _reloadLists() => _loadInitialData();

  void _loadInitialData() {
    final userId = _currentUserId;
    if (userId == null) return;

    // Load user's communities
    context.read<CommunitiesBloc>().add(
          LoadUserCommunities(userId: userId),
        );
    // Prefetch "My communities" (created) IN ADVANCE so the tab is seamless.
    // Safe now that every emission preserves managedCommunities/managedLoaded.
    _managedLoaded = true;
    context.read<CommunitiesBloc>().add(
          LoadManagedCommunities(userId: userId),
        );

    // Personalisation from the profile (when already loaded): the viewer's
    // effective city (traveler location when active) and primary language.
    final profileState = context.read<ProfileBloc>().state;
    final profile = profileState is ProfileLoaded ? profileState.profile : null;
    final city = profile?.effectiveLocation.city.trim();
    final nearCity = (city == null || city.isEmpty) ? null : city;
    final nearLanguage = profile == null || profile.languages.isEmpty
        ? null
        : languageCode(profile.languages.first);

    // Discover: local + language + worldwide (memoised per session).
    context.read<CommunitiesBloc>().add(
          LoadCommunities(nearCity: nearCity, nearLanguage: nearLanguage),
        );

    // Load recommended based on profile languages. Always dispatch (don't gate
    // on ProfileBloc being loaded yet, which caused recommended to never load on
    // a cold start) — fall back to empty languages if the profile isn't ready.
    // Learning languages first, then spoken, then native — normalised to the
    // community code format (profiles store display names like "Portuguese").
    final langs = profile == null
        ? const <String>[]
        : normalizeCommunityLanguages([
            ...profile.preferredLanguages,
            ...profile.languages,
            profile.nativeLanguage,
          ]);
    context.read<CommunitiesBloc>().add(
          LoadRecommendedCommunities(
              userId: userId, languages: langs, city: nearCity),
        );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _managedSearchController.dispose();
    _joinedSearchController.dispose();
    _discoverScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tourUserId = _currentUserId;
    return ShowCaseWidget(
      builder: (showcaseContext) => TourTrigger(
        // First-time Communities tour: tabs -> search -> a community card
        // (open + favorite) -> the create button. Unmounted targets (e.g. the
        // search/card on an empty Joined tab) are skipped automatically.
        onVisible: (tourContext) {
          if (tourUserId == null) return;
          TourController.instance.maybeStartMiniTour(
            tourContext,
            tourId: TourController.communitiesTourId,
            userId: tourUserId,
            keys: _communitiesTourKeys,
          );
        },
        child: Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.communitiesTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textTertiary),
            tooltip: l10n.tourReplayGuide,
            onPressed: () => _replayTour(showcaseContext),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: TourShowcase(
            showcaseKey: TourKeys.communitiesTabs,
            title: l10n.tourCommunitiesTabsTitle,
            description: l10n.tourCommunitiesTabsDesc,
            gesture: TourGesture.tap,
            child: TabBar(
              controller: _tabController,
              // Full width like the Events page: the three tabs share it
              // equally; long translations scale down instead of overflowing.
              isScrollable: false,
              tabAlignment: TabAlignment.fill,
              indicatorColor: AppColors.richGold,
              labelColor: AppColors.richGold,
              unselectedLabelColor: AppColors.textTertiary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                for (final label in [
                  AppLocalizations.of(context)!.communitiesTabJoined,
                  AppLocalizations.of(context)!.communitiesTabDiscover,
                  AppLocalizations.of(context)!.communitiesTabManaged,
                ])
                  Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, maxLines: 1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: BlocConsumer<CommunitiesBloc, CommunitiesState>(
        // After a create/join/leave the bloc emits a terminal state (NOT
        // CommunitiesLoaded), which would blank all four tabs — so reload the
        // user's communities so the new one shows immediately.
        listenWhen: (prev, curr) =>
            curr is CommunityCreated ||
            curr is CommunityJoined ||
            curr is CommunityLeft ||
            curr is CommunityDeleted,
        listener: (context, state) {
          if (state is CommunityLeft) _dropFavorite(state.communityId);
          if (state is CommunityDeleted) _dropFavorite(state.communityId);
          _reloadLists();
        },
        builder: (context, state) {
          // Remember the last populated list state; fall back to it when the
          // live state is a non-list state (e.g. CommunityDetailLoaded after
          // opening/returning from a community) so the tabs never blank.
          if (state is CommunitiesLoaded) _lastLoaded = state;
          final effective =
              state is CommunitiesLoaded ? state : (_lastLoaded ?? state);
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMyGroupsTab(effective),
              _buildDiscoverTab(effective),
              _buildManagedTab(effective),
            ],
          );
        },
      ),
      floatingActionButton: TourShowcase(
        showcaseKey: TourKeys.communitiesCreate,
        title: l10n.tourCommunitiesCreateTitle,
        description: l10n.tourCommunitiesCreateDesc,
        gesture: TourGesture.tap,
        targetShapeBorder: const StadiumBorder(),
        child: FloatingActionButton.extended(
          onPressed: _navigateToCreateCommunity,
          backgroundColor: AppColors.richGold,
          icon: const Icon(Icons.add, color: AppColors.deepBlack),
          label: Text(
            AppLocalizations.of(context)!.communitiesCreateLabel,
            style: const TextStyle(
              color: AppColors.deepBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }

  /// My Groups Tab - User's joined communities
  Widget _buildMyGroupsTab(CommunitiesState state) {
    if (state is CommunitiesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    var userCommunities = <Community>[];
    if (state is CommunitiesLoaded) {
      userCommunities = state.userCommunities;
    }

    if (userCommunities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_outlined,
        title: AppLocalizations.of(context)!.communitiesNoCommunities,
        subtitle: AppLocalizations.of(context)!.communitiesJoinPrompt,
        actionLabel: AppLocalizations.of(context)!.communitiesDiscoverCommunities,
        onAction: () => _tabController.animateTo(_kDiscoverTab),
        secondaryLabel: AppLocalizations.of(context)!.xplCreateCommunity,
        onSecondary: _navigateToCreateCommunity,
      );
    }

    // Favorites pinned on top (newest starred first, loaded separately), then
    // the rest in the existing order, revealed page by page.
    final arranged = arrangeJoinedCommunities(
      joined: userCommunities,
      favoriteIds: _favoriteOrder,
      favoriteDocs: _favoriteDocs,
      joinedLoaded: state is CommunitiesLoaded,
      query: _joinedSearchQuery,
    );
    final favorites = arranged.favorites;
    final others = arranged.others.length > _joinedShown
        ? arranged.others.sublist(0, _joinedShown)
        : arranged.others;
    final hasMoreOthers = others.length < arranged.others.length;
    final l10n = AppLocalizations.of(context)!;
    // Rows: [Favorites header, favorites..., Joined header, others..., loader]
    final rows = <Widget Function(bool first)>[
      if (favorites.isNotEmpty)
        (_) => _sectionHeader(l10n.communitiesFavoritesSection),
      for (final c in favorites) (first) => _joinedCard(c, isFirst: first),
      if (favorites.isNotEmpty && others.isNotEmpty)
        (_) => _sectionHeader(l10n.communitiesJoinedSection,
            icon: Icons.groups_outlined),
      for (final c in others) (first) => _joinedCard(c, isFirst: first),
      // Building the loader means the end of the revealed page is (nearly)
      // on screen: reveal the next page after this frame.
      if (hasMoreOthers)
        (_) {
          _revealMoreJoined();
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            ),
          );
        },
    ];
    final firstCardRow = favorites.isNotEmpty ? 1 : 0;

    return Column(
      children: [
        _joinedSearchBar(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.richGold,
            backgroundColor: AppColors.backgroundCard,
            onRefresh: () async {
              if (_currentUserId != null) {
                context.read<CommunitiesBloc>().add(
                      LoadUserCommunities(userId: _currentUserId!),
                    );
                await _loadFavorites();
              }
            },
            child: arranged.isEmpty
                ? ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      _buildEmptyState(
                        icon: Icons.search_off,
                        title: l10n.communitiesNoCommunitiesFound,
                        subtitle: l10n.communitiesAdjustSearch,
                      ),
                    ],
                  )
                : ListView.builder(
                    key: const ValueKey('communities-joined-list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: AppDimensions.paddingS,
                      bottom: 80,
                    ),
                    itemCount: rows.length,
                    itemBuilder: (context, index) =>
                        rows[index](index == firstCardRow),
                  ),
          ),
        ),
      ],
    );
  }

  /// A joined-community card. The FIRST card is wrapped in a tour showcase step
  /// that explains tapping to open + the favorite star.
  Widget _joinedCard(Community c, {required bool isFirst}) {
    final card = CommunityCard(
      key: ValueKey('joined-${c.id}'),
      community: c,
      showFavorite: true,
      isFavorite: _favoriteIds.contains(c.id),
      onToggleFavorite: () => _toggleFavorite(c),
      onTap: () => _navigateToCommunityDetail(c),
    );
    if (!isFirst) return card;
    final l10n = AppLocalizations.of(context)!;
    return TourShowcase(
      showcaseKey: TourKeys.communitiesCard,
      title: l10n.tourCommunitiesCardTitle,
      description: l10n.tourCommunitiesCardDesc,
      gesture: TourGesture.tap,
      child: card,
    );
  }

  /// A small section header (e.g. "Favorites") above a group of cards.
  Widget _sectionHeader(String label, {IconData icon = Icons.star}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.richGold),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Search field for the "Joined" (My Groups) tab.
  Widget _joinedSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return TourShowcase(
      showcaseKey: TourKeys.communitiesSearch,
      title: l10n.tourCommunitiesSearchTitle,
      description: l10n.tourCommunitiesSearchDesc,
      gesture: TourGesture.tap,
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _joinedSearchController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.communitiesSearchHint,
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.6),
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
          suffixIcon: _joinedSearchQuery.isNotEmpty
              ? IconButton(tooltip: AppLocalizations.of(context)!.userFollowSearchClear,
                  icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                  onPressed: () {
                    _joinedSearchController.clear();
                    setState(() => _joinedSearchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.richGold),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => setState(() {
          _joinedSearchQuery = value;
          _joinedShown = _joinedPageSize;
        }),
      ),
      ),
    );
  }

  /// "My communities" Tab — communities this user OWNS / manages (created).
  /// A community's creator is its manager (createdByUserId), so we filter the
  /// user's communities down to the ones they created.
  Widget _buildManagedTab(CommunitiesState state) {
    if (state is CommunitiesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    var managed = <Community>[];
    if (state is CommunitiesLoaded) {
      // Communities the user CREATED — loaded via a direct createdByUserId
      // query (state.managedCommunities), so it no longer depends on the
      // creator having a member doc. Fall back to the old member-based filter
      // if the dedicated list hasn't loaded yet.
      managed = state.managedCommunities.isNotEmpty
          ? state.managedCommunities
          : state.userCommunities
              .where((c) => c.createdByUserId == _currentUserId)
              .toList();
    }

    // Still fetching the created-communities list → show a loader (prefetched at
    // init, so this is usually brief) rather than a premature "empty" state.
    if (state is CommunitiesLoaded && !state.managedLoaded && managed.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    if (managed.isEmpty) {
      return _buildEmptyState(
        icon: Icons.workspace_premium_outlined,
        title: AppLocalizations.of(context)!.communitiesNoManaged,
        subtitle: AppLocalizations.of(context)!.communitiesNoManagedSubtitle,
        actionLabel: AppLocalizations.of(context)!.communitiesCreateLabel,
        onAction: _navigateToCreateCommunity,
      );
    }

    // Search filter over the user's own communities.
    final q = _managedSearchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? managed
        : managed
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q))
            .toList();

    return Column(
      children: [
        _managedSearchBar(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.richGold,
            backgroundColor: AppColors.backgroundCard,
            onRefresh: () async {
              if (_currentUserId != null) {
                context.read<CommunitiesBloc>()
                  ..add(LoadUserCommunities(userId: _currentUserId!))
                  ..add(LoadManagedCommunities(userId: _currentUserId!));
              }
            },
            child: filtered.isEmpty
                ? ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      _buildEmptyState(
                        icon: Icons.search_off,
                        title: AppLocalizations.of(context)!
                            .communitiesNoCommunitiesFound,
                        subtitle: AppLocalizations.of(context)!
                            .communitiesAdjustSearch,
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: AppDimensions.paddingS,
                      bottom: 80,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return CommunityCard(
                        community: filtered[index],
                        onTap: () =>
                            _navigateToCommunityDetail(filtered[index]),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// Search field for the "My communities" tab.
  Widget _managedSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _managedSearchController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.communitiesSearchHint,
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.6),
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
          suffixIcon: _managedSearchQuery.isNotEmpty
              ? IconButton(tooltip: AppLocalizations.of(context)!.userFollowSearchClear,
                  icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                  onPressed: () {
                    _managedSearchController.clear();
                    setState(() => _managedSearchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.richGold),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => setState(() => _managedSearchQuery = value),
      ),
    );
  }

  /// Discover Tab - Browse all public communities
  Widget _buildDiscoverTab(CommunitiesState state) {
    if (state is CommunitiesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    var communities = <Community>[];
    var recommended = <Community>[];
    var isLoadingMore = false;
    if (state is CommunitiesLoaded) {
      // Discover shows communities the user can JOIN — exclude the ones they're
      // already a member of.
      final joinedIds = state.userCommunities.map((c) => c.id).toSet();
      communities = state.communities
          .where((c) => !joinedIds.contains(c.id))
          .toList();
      recommended = state.recommended
          .where((c) => !joinedIds.contains(c.id))
          .toList();
      isLoadingMore = state.isLoadingMore;

      // Endless scroll robustness: if the list underfills the viewport (few
      // items after excluding joined) but more pages exist, fetch the next page
      // after this frame so the list keeps growing without needing a scroll.
      if (state.hasMoreCommunities && !state.isLoadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_discoverScrollController.hasClients &&
              _discoverScrollController.position.maxScrollExtent < 200) {
            context.read<CommunitiesBloc>().add(
                  LoadMoreCommunities(
                    type: _selectedFilter,
                    searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                  ),
                );
          }
        });
      }
    }

    return CustomScrollView(
      controller: _discoverScrollController,
      slivers: [
        // Search bar (mirrors the Exchange / Conversations search field)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.communitiesSearchHint,
                hintStyle: TextStyle(
                  color: AppColors.textTertiary.withValues(alpha: 0.6),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textTertiary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(tooltip: AppLocalizations.of(context)!.userFollowSearchClear,
                        icon: const Icon(Icons.clear,
                            color: AppColors.textTertiary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          context.read<CommunitiesBloc>().add(
                                _selectedFilter == null
                                    ? const LoadCommunities()
                                    : LoadCommunities(type: _selectedFilter),
                              );
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.richGold),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
              onSubmitted: (query) {
                context.read<CommunitiesBloc>().add(
                      LoadCommunities(searchQuery: query),
                    );
              },
            ),
          ),
        ),

        // Filter chips — mirrors the Exchange (Conversations) filter row exactly:
        // a ListView.separated of Material FilterChips with "All" as the first
        // data entry (not a hand-inserted leading chip), height 40, and a
        // bottom-8 padding wrapper.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              height: 40,
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  // "All" (null) is entry 0, then one entry per community type.
                  final filters = <(CommunityType?, String)>[
                    (null, l10n.filterAll),
                    for (final t in CommunityType.values) (t, communityTypeLabel(l10n, t)),
                  ];
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final (type, label) = filters[index];
                      final isSelected = _selectedFilter == type;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(label),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.deepBlack
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        backgroundColor: AppColors.backgroundCard,
                        selectedColor: AppColors.richGold,
                        checkmarkColor: AppColors.deepBlack,
                        side: BorderSide(
                          color:
                              isSelected ? AppColors.richGold : AppColors.divider,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedFilter = type);
                          context.read<CommunitiesBloc>().add(
                                type == null
                                    ? const LoadCommunities()
                                    : LoadCommunities(type: type),
                              );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),

        // Recommended section
        if (recommended.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingM,
                AppDimensions.paddingL,
                AppDimensions.paddingM,
                AppDimensions.paddingS,
              ),
              child: Text(
                AppLocalizations.of(context)!.communitiesRecommendedForYou,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return CommunityCard(
                  community: recommended[index],
                  onTap: () => _navigateToCommunityDetail(recommended[index]),
                );
              },
              childCount: recommended.length > 5 ? 5 : recommended.length,
            ),
          ),
        ],

        // All communities section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Text(
              AppLocalizations.of(context)!.communitiesAllCommunities,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        if (communities.isEmpty)
          SliverToBoxAdapter(
            child: _buildEmptyState(
              icon: Icons.search_off,
              title: AppLocalizations.of(context)!.communitiesNoCommunitiesFound,
              subtitle: AppLocalizations.of(context)!.communitiesAdjustSearch,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return CommunityCard(
                  community: communities[index],
                  onTap: () =>
                      _navigateToCommunityDetail(communities[index]),
                );
              },
              childCount: communities.length,
            ),
          ),

        // Endless-scroll trailing spinner while the next page loads.
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.richGold,
                  ),
                ),
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  /// Language Circles Tab - Language-specific communities
  Widget _buildLanguageCirclesTab(CommunitiesState state) {
    if (state is CommunitiesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    var languageCircles = <Community>[];
    if (state is CommunitiesLoaded) {
      languageCircles = state.languageCircles;

      // If no language circles loaded separately, filter from all communities
      if (languageCircles.isEmpty) {
        languageCircles = state.communities
            .where((c) => c.type == CommunityType.languageCircle)
            .toList();
      }
    }

    if (languageCircles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.translate,
        title: AppLocalizations.of(context)!.communitiesNoLanguageCircles,
        subtitle: AppLocalizations.of(context)!.communitiesLanguageCirclesPrompt,
        actionLabel: AppLocalizations.of(context)!.communitiesCreateLanguageCircle,
        onAction: () => _navigateToCreateCommunity(
          preselectedType: CommunityType.languageCircle,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.richGold,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: () async {
        context.read<CommunitiesBloc>().add(
              const LoadCommunities(type: CommunityType.languageCircle),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppDimensions.paddingS,
          bottom: 80,
        ),
        itemCount: languageCircles.length,
        itemBuilder: (context, index) {
          return CommunityCard(
            community: languageCircles[index],
            onTap: () => _navigateToCommunityDetail(languageCircles[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return HelpfulEmptyState(
      icon: icon,
      title: title,
      message: subtitle,
      actions: [
        if (actionLabel != null && onAction != null)
          HelpfulEmptyAction(label: actionLabel, onPressed: onAction),
        if (secondaryLabel != null && onSecondary != null)
          HelpfulEmptyAction(label: secondaryLabel, onPressed: onSecondary),
      ],
    );
  }


  Future<void> _navigateToCommunityDetail(Community community) async {
    // Interaction logging (fire-and-forget, never throws): a community tap feeds
    // the recommendation signal.
    final uid = _currentUserId;
    if (uid != null) {
      di.sl<InteractionLogService>().logCommunityView(uid, community.id);
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        // Forward BOTH blocs: CommunityDetailScreen reads ProfileBloc in its
        // initState, and ProfileBloc lives below the root Navigator (in the
        // main-nav MultiBlocProvider) so pushed routes don't inherit it.
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<CommunitiesBloc>()),
            BlocProvider.value(value: context.read<ProfileBloc>()),
          ],
          child: CommunityDetailScreen(community: community),
        ),
      ),
    );
    // NOTE: we deliberately do NOT reload the lists here. The detail screen
    // leaves the SHARED bloc in CommunityDetailLoaded, but the build() falls back
    // to the cached [_lastLoaded] so the tabs stay populated WITHOUT a visible
    // refresh. A real join/leave inside the detail already triggers a reload via
    // the BlocConsumer's CommunityJoined/CommunityLeft listener — so an
    // unconditional reload here just caused the "weird refresh" on plain views.
  }

  Future<void> _navigateToCreateCommunity({CommunityType? preselectedType}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        // CreateCommunityScreen also reads ProfileBloc.state, so forward it
        // alongside CommunitiesBloc (see _navigateToCommunityDetail).
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<CommunitiesBloc>()),
            BlocProvider.value(value: context.read<ProfileBloc>()),
          ],
          child: CreateCommunityScreen(
            preselectedType: preselectedType,
          ),
        ),
      ),
    );
    // Refresh on return so a just-created community is present even if the
    // terminal-state listener was missed.
    if (mounted) _reloadLists();
  }
}
