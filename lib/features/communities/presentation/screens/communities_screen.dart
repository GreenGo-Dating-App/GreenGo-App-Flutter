import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/entities/community.dart';
import '../bloc/communities_bloc.dart';
import '../bloc/communities_event.dart';
import '../bloc/communities_state.dart';
import '../widgets/community_card.dart';
import '../widgets/community_type_chip.dart';
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
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadInitialData();
  }

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

    // Load recommended based on profile languages
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      context.read<CommunitiesBloc>().add(
            LoadRecommendedCommunities(
              userId: userId,
              languages: profileState.profile.preferredLanguages,
            ),
          );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Communities',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Discover'),
            Tab(text: 'Language Circles'),
          ],
        ),
      ),
      body: BlocBuilder<CommunitiesBloc, CommunitiesState>(
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMyGroupsTab(state),
              _buildDiscoverTab(state),
              _buildLanguageCirclesTab(state),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateCommunity(),
        backgroundColor: AppColors.richGold,
        icon: const Icon(Icons.add, color: AppColors.deepBlack),
        label: const Text(
          'Create',
          style: TextStyle(
            color: AppColors.deepBlack,
            fontWeight: FontWeight.w600,
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

    List<Community> userCommunities = [];
    if (state is CommunitiesLoaded) {
      userCommunities = state.userCommunities;
    }

    if (userCommunities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_outlined,
        title: 'No Communities Yet',
        subtitle:
            'Join communities to connect with people who share your interests and languages.',
        actionLabel: 'Discover Communities',
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

  /// Discover Tab - Browse all public communities
  Widget _buildDiscoverTab(CommunitiesState state) {
    if (state is CommunitiesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    List<Community> communities = [];
    List<Community> recommended = [];
    if (state is CommunitiesLoaded) {
      communities = state.communities;
      recommended = state.recommended;
    }

    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search communities...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.backgroundInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
              ),
              onSubmitted: (query) {
                context.read<CommunitiesBloc>().add(
                      LoadCommunities(searchQuery: query),
                    );
              },
            ),
          ),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              children: [
                CommunityTypeChip(
                  label: 'All',
                  isSelected: _selectedFilter == null,
                  onTap: () {
                    setState(() => _selectedFilter = null);
                    context.read<CommunitiesBloc>().add(
                          const LoadCommunities(),
                        );
                  },
                ),
                const SizedBox(width: 8),
                ...CommunityType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CommunityTypeChip(
                      type: type,
                      label: type.displayName,
                      isSelected: _selectedFilter == type,
                      onTap: () {
                        setState(() => _selectedFilter = type);
                        context.read<CommunitiesBloc>().add(
                              LoadCommunities(type: type),
                            );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Recommended section
        if (recommended.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.paddingM,
                AppDimensions.paddingL,
                AppDimensions.paddingM,
                AppDimensions.paddingS,
              ),
              child: Text(
                'Recommended for You',
                style: TextStyle(
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
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Text(
              'All Communities',
              style: TextStyle(
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
              title: 'No Communities Found',
              subtitle: 'Try adjusting your search or filters.',
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

    List<Community> languageCircles = [];
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
        title: 'No Language Circles',
        subtitle:
            'Language circles will appear here when available. Create one to get started!',
        actionLabel: 'Create Language Circle',
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CommunitiesBloc>(),
          child: CommunityDetailScreen(community: community),
        ),
      ),
    );
  }

  void _navigateToCreateCommunity({CommunityType? preselectedType}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CommunitiesBloc>(),
          child: CreateCommunityScreen(
            preselectedType: preselectedType,
          ),
        ),
      ),
    );
  }
}
