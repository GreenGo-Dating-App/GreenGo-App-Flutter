import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/interaction_log_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../app_tour/presentation/tour_controller.dart';
import '../../../app_tour/presentation/tour_keys.dart';
import '../../../app_tour/presentation/widgets/gesture_glyphs.dart';
import '../../../app_tour/presentation/widgets/tour_showcase.dart';
import '../../../app_tour/presentation/widgets/tour_trigger.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../data/datasources/community_favorites_service.dart';
import '../../domain/entities/community.dart';
import '../bloc/communities_bloc.dart';
import '../bloc/communities_event.dart';
import '../bloc/communities_state.dart';
import '../widgets/community_card.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';

/// Communities Screen
///
/// Main screen for the communities feature with three tabs:
/// My Groups, Discover, and Language Circles
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

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
  // toggled optimistically, persisted via [CommunityFavoritesService].
  final CommunityFavoritesService _favoritesService = CommunityFavoritesService();
  Set<String> _favoriteIds = <String>{};
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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _discoverScrollController.addListener(_onDiscoverScroll);
    _loadInitialData();
    _loadFavorites();
  }

  /// One cheap read of the user's starred communities (single-doc id array).
  Future<void> _loadFavorites() async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      final ids = await _favoritesService.getAll(uid);
      if (mounted) setState(() => _favoriteIds = ids);
    } catch (_) {
      // Non-fatal: the star just starts un-filled.
    }
  }

  /// Optimistically toggle a favorite, then persist (revert on failure).
  Future<void> _toggleFavorite(Community community) async {
    final uid = _currentUserId;
    if (uid == null) return;
    final id = community.id;
    final wasFavorite = _favoriteIds.contains(id);
    setState(() {
      final next = Set<String>.from(_favoriteIds);
      wasFavorite ? next.remove(id) : next.add(id);
      _favoriteIds = next;
    });
    try {
      await _favoritesService.setFavorite(uid, id, !wasFavorite);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final revert = Set<String>.from(_favoriteIds);
        wasFavorite ? revert.add(id) : revert.remove(id);
        _favoriteIds = revert;
      });
    }
  }

  bool _managedLoaded = false;

  /// Load "My communities" (created) the first time its tab is opened. Loading
  /// it lazily (instead of at init) keeps it out of the concurrent init-load
  /// race that was resetting managedCommunities back to empty.
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final userId = _currentUserId;
    if (userId == null) return;
    // Discover (1): guarantee the public list is loaded when the tab is opened
    // (it's also prefetched at init so it's usually already there).
    if (_tabController.index == 1) {
      final s = context.read<CommunitiesBloc>().state;
      final hasDiscover = s is CommunitiesLoaded && s.communities.isNotEmpty;
      if (!hasDiscover) {
        context.read<CommunitiesBloc>().add(const LoadCommunities());
      }
    }
    // My communities (2): lazy-load the created list on first open.
    if (_tabController.index == 2 && !_managedLoaded) {
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

    // Load all communities for discover tab
    context.read<CommunitiesBloc>().add(
          const LoadCommunities(),
        );

    // Load recommended based on profile languages. Always dispatch (don't gate
    // on ProfileBloc being loaded yet, which caused recommended to never load on
    // a cold start) — fall back to empty languages if the profile isn't ready.
    final profileState = context.read<ProfileBloc>().state;
    final langs = profileState is ProfileLoaded
        ? profileState.profile.preferredLanguages
        : const <String>[];
    context.read<CommunitiesBloc>().add(
          LoadRecommendedCommunities(userId: userId, languages: langs),
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
        // First-time Communities tour: highlights the tabs and the create button.
        onVisible: (tourContext) {
          if (tourUserId == null) return;
          TourController.instance.maybeStartMiniTour(
            tourContext,
            tourId: TourController.communitiesTourId,
            userId: tourUserId,
            keys: [TourKeys.communitiesTabs, TourKeys.communitiesCreate],
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: TourShowcase(
            showcaseKey: TourKeys.communitiesTabs,
            title: l10n.tourCommunitiesTabsTitle,
            description: l10n.tourCommunitiesTabsDesc,
            gesture: TourGesture.tap,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.richGold,
              labelColor: AppColors.richGold,
              unselectedLabelColor: AppColors.textTertiary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.communitiesTabJoined),
                Tab(text: AppLocalizations.of(context)!.communitiesTabDiscover),
                Tab(text: AppLocalizations.of(context)!.communitiesTabManaged),
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
            curr is CommunityLeft,
        listener: (context, state) => _reloadLists(),
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
        onAction: () => _tabController.animateTo(1),
      );
    }

    // Search filter over the joined communities.
    final q = _joinedSearchQuery.trim().toLowerCase();
    final matched = q.isEmpty
        ? userCommunities
        : userCommunities
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q))
            .toList();

    // Pin FAVORITES to the top (starred first, preserving relative order), the
    // rest below.
    final favorites =
        matched.where((c) => _favoriteIds.contains(c.id)).toList();
    final others =
        matched.where((c) => !_favoriteIds.contains(c.id)).toList();
    final ordered = [...favorites, ...others];

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
            child: ordered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      _buildEmptyState(
                        icon: Icons.search_off,
                        title: AppLocalizations.of(context)!
                            .communitiesNoCommunitiesFound,
                        subtitle:
                            AppLocalizations.of(context)!.communitiesAdjustSearch,
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: AppDimensions.paddingS,
                      bottom: 80,
                    ),
                    // +1 for the "Favorites" section header when any exist and
                    // no search is narrowing the list.
                    itemCount: ordered.length + (favorites.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (favorites.isNotEmpty) {
                        if (index == 0) {
                          return _sectionHeader(AppLocalizations.of(context)!
                              .communitiesFavoritesSection);
                        }
                        final c = ordered[index - 1];
                        return CommunityCard(
                          community: c,
                          showFavorite: true,
                          isFavorite: _favoriteIds.contains(c.id),
                          onToggleFavorite: () => _toggleFavorite(c),
                          onTap: () => _navigateToCommunityDetail(c),
                        );
                      }
                      final c = ordered[index];
                      return CommunityCard(
                        community: c,
                        showFavorite: true,
                        isFavorite: _favoriteIds.contains(c.id),
                        onToggleFavorite: () => _toggleFavorite(c),
                        onTap: () => _navigateToCommunityDetail(c),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// A small section header (e.g. "Favorites") above a group of cards.
  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.star, size: 16, color: AppColors.richGold),
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
    return Padding(
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
              ? IconButton(
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
        onChanged: (value) => setState(() => _joinedSearchQuery = value),
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
              ? IconButton(
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
                    ? IconButton(
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
                    for (final t in CommunityType.values) (t, t.displayName),
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
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.paddingL),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                    vertical: AppDimensions.paddingM,
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
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
