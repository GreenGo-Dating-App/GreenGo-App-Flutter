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
  final ScrollController _discoverScrollController = ScrollController();
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _discoverScrollController.addListener(_onDiscoverScroll);
    _loadInitialData();
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
    _tabController.dispose();
    _searchController.dispose();
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
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMyGroupsTab(state),
              _buildDiscoverTab(state),
              _buildManagedTab(state),
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

    return RefreshIndicator(
      color: AppColors.richGold,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: () async {
        if (_currentUserId != null) {
          context.read<CommunitiesBloc>().add(
                LoadUserCommunities(userId: _currentUserId!),
              );
        }
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: AppDimensions.paddingS,
          bottom: 80,
        ),
        itemCount: userCommunities.length,
        itemBuilder: (context, index) {
          return CommunityCard(
            community: userCommunities[index],
            onTap: () => _navigateToCommunityDetail(userCommunities[index]),
          );
        },
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
      managed = state.userCommunities
          .where((c) => c.createdByUserId == _currentUserId)
          .toList();
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

    return RefreshIndicator(
      color: AppColors.richGold,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: () async {
        if (_currentUserId != null) {
          context.read<CommunitiesBloc>().add(
                LoadUserCommunities(userId: _currentUserId!),
              );
        }
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: AppDimensions.paddingS,
          bottom: 80,
        ),
        itemCount: managed.length,
        itemBuilder: (context, index) {
          return CommunityCard(
            community: managed[index],
            onTap: () => _navigateToCommunityDetail(managed[index]),
          );
        },
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
      communities = state.communities;
      recommended = state.recommended;
      isLoadingMore = state.isLoadingMore;
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

  void _navigateToCommunityDetail(Community community) {
    // Interaction logging (fire-and-forget, never throws): a community tap feeds
    // the recommendation signal.
    final uid = _currentUserId;
    if (uid != null) {
      di.sl<InteractionLogService>().logCommunityView(uid, community.id);
    }
    Navigator.of(context).push(
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
