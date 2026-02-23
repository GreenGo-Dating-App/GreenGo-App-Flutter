import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/base_membership_gate.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../matching/domain/usecases/compatibility_scorer.dart';
import '../../domain/entities/match.dart';
import '../bloc/matches_bloc.dart';
import '../bloc/matches_event.dart';
import '../bloc/matches_state.dart';
import '../widgets/match_card_widget.dart';
import 'match_detail_screen.dart';

/// Matches Screen
///
/// Displays user's matches with search, filter, and sort capabilities
class MatchesScreen extends StatelessWidget {
  final String userId;

  const MatchesScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<MatchesBloc>()
        ..add(MatchesLoadRequested(userId: userId)),
      child: _MatchesScreenContent(userId: userId),
    );
  }
}

class _MatchesScreenContent extends StatefulWidget {
  final String userId;

  const _MatchesScreenContent({required this.userId});

  @override
  State<_MatchesScreenContent> createState() => _MatchesScreenContentState();
}

class _MatchesScreenContentState extends State<_MatchesScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  final CompatibilityScorer _scorer = CompatibilityScorer();
  String _searchQuery = '';
  String _filterType = 'all'; // all, new, messaged
  String _sortOrder = 'none'; // none, desc, asc
  Profile? _currentUserProfile;

  // Cache computed scores to avoid recalculating on every rebuild
  final Map<String, double> _scoreCache = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    final result = await di.sl<ProfileRepository>().getProfile(widget.userId);
    result.fold((_) {}, (profile) {
      if (mounted) setState(() => _currentUserProfile = profile);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Compute compatibility score between current user and matched user
  double _getCompatibilityScore(
    Profile? currentUserProfile,
    Profile? otherProfile,
    String matchId,
  ) {
    if (currentUserProfile == null || otherProfile == null) return 0;

    if (_scoreCache.containsKey(matchId)) {
      return _scoreCache[matchId]!;
    }

    try {
      final score = _scorer.calculateScore(
        profile1: currentUserProfile,
        profile2: otherProfile,
      );
      _scoreCache[matchId] = score.overallScore;
      return score.overallScore;
    } catch (_) {
      return 0;
    }
  }

  /// Filter matches based on search query and filter type
  List<Match> _filterAndSortMatches(
    List<Match> matches,
    Map<String, Profile> profiles,
    String userId,
  ) {
    var filtered = matches.where((match) {
      final profile = profiles[match.getOtherUserId(userId)];

      // Apply search filter
      if (_searchQuery.isNotEmpty && profile != null) {
        final query = _searchQuery.toLowerCase();
        final nameMatches =
            profile.displayName.toLowerCase().contains(query);
        final nicknameMatches =
            profile.nickname?.toLowerCase().contains(query) ?? false;
        if (!nameMatches && !nicknameMatches) {
          return false;
        }
      }

      // Apply type filter
      switch (_filterType) {
        case 'new':
          return match.isNewMatch(userId);
        case 'messaged':
          return match.lastMessage != null;
        default:
          return true;
      }
    }).toList();

    // Sort by compatibility if requested
    if (_sortOrder != 'none') {
      final currentUserProfile = profiles[userId];
      filtered.sort((a, b) {
        final profileA = profiles[a.getOtherUserId(userId)];
        final profileB = profiles[b.getOtherUserId(userId)];
        final scoreA = _getCompatibilityScore(currentUserProfile, profileA, a.matchId);
        final scoreB = _getCompatibilityScore(currentUserProfile, profileB, b.matchId);
        return _sortOrder == 'desc'
            ? scoreB.compareTo(scoreA)
            : scoreA.compareTo(scoreB);
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: BlocBuilder<MatchesBloc, MatchesState>(
        builder: (context, state) {
          if (state is MatchesLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.richGold,
              ),
            );
          }

          if (state is MatchesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.errorRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<MatchesBloc>()
                          .add(MatchesLoadRequested(userId: widget.userId));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is MatchesEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<MatchesBloc>();
                bloc.add(MatchesRefreshRequested(widget.userId));
                try {
                  await bloc.stream.first.timeout(const Duration(seconds: 15));
                } catch (_) {}
              },
              color: AppColors.richGold,
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No matches yet',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Start swiping to find your matches!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is MatchesLoaded) {
            final allMatches = state.matches;
            final currentUserProfile = state.profiles[widget.userId];
            final filteredMatches = _filterAndSortMatches(
              allMatches,
              state.profiles,
              widget.userId,
            );

            return RefreshIndicator(
              onRefresh: () async {
                _scoreCache.clear();
                final bloc = context.read<MatchesBloc>();
                bloc.add(MatchesRefreshRequested(widget.userId));
                // Wait for the next state emission (the refresh result)
                try {
                  await bloc.stream.first.timeout(const Duration(seconds: 15));
                } catch (_) {
                  // Timeout — stop the refresh indicator anyway
                }
              },
              color: AppColors.richGold,
              child: CustomScrollView(
                slivers: [
                  // Search and Filter Bar
                  SliverToBoxAdapter(
                    child: _buildSearchAndFilterBar(allMatches.length),
                  ),

                  // Results count + sort button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _searchQuery.isNotEmpty || _filterType != 'all'
                                  ? '${filteredMatches.length} of ${allMatches.length} matches'
                                  : '${allMatches.length} matches',
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // Sort by compatibility button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_sortOrder == 'none') {
                                  _sortOrder = 'desc';
                                } else if (_sortOrder == 'desc') {
                                  _sortOrder = 'asc';
                                } else {
                                  _sortOrder = 'none';
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _sortOrder != 'none'
                                    ? AppColors.richGold.withOpacity(0.15)
                                    : AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _sortOrder != 'none'
                                      ? AppColors.richGold
                                      : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _sortOrder == 'asc'
                                        ? Icons.arrow_upward
                                        : _sortOrder == 'desc'
                                            ? Icons.arrow_downward
                                            : Icons.sort,
                                    color: _sortOrder != 'none'
                                        ? AppColors.richGold
                                        : AppColors.textTertiary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Compatibility',
                                    style: TextStyle(
                                      color: _sortOrder != 'none'
                                          ? AppColors.richGold
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: _sortOrder != 'none'
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Empty filter results
                  if (filteredMatches.isEmpty && allMatches.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No matches found',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search or filter',
                              style: TextStyle(
                                color: AppColors.textTertiary.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                  _filterType = 'all';
                                  _sortOrder = 'none';
                                });
                              },
                              child: const Text(
                                'Clear Filters',
                                style: TextStyle(color: AppColors.richGold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Matches list
                  if (filteredMatches.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final match = filteredMatches[index];
                            final otherUserId = match.getOtherUserId(widget.userId);
                            final profile = state.profiles[otherUserId];
                            final score = _getCompatibilityScore(
                              currentUserProfile,
                              profile,
                              match.matchId,
                            );

                            return MatchCardWidget(
                              match: match,
                              profile: profile,
                              currentUserId: widget.userId,
                              compatibilityPercent: score > 0 ? score : null,
                              onTap: () async {
                                // Base membership gate
                                final wasMember = _currentUserProfile?.isBaseMembershipActive ?? false;
                                final allowed = await BaseMembershipGate.checkAndGate(
                                  context: context,
                                  profile: _currentUserProfile,
                                  userId: widget.userId,
                                );
                                if (!allowed) return;
                                if (!wasMember) await _loadCurrentUserProfile();

                                // Mark as seen if not seen
                                if (match.isNewMatch(widget.userId)) {
                                  context.read<MatchesBloc>().add(
                                        MatchMarkedAsSeen(
                                          matchId: match.matchId,
                                          userId: widget.userId,
                                        ),
                                      );
                                }

                                // Navigate to match detail screen
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MatchDetailScreen(
                                      match: match,
                                      profile: profile,
                                      currentUserId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: filteredMatches.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchAndFilterBar(int totalMatches) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name or @nickname',
              hintStyle: TextStyle(
                color: AppColors.textTertiary.withOpacity(0.6),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textTertiary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.backgroundCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.richGold),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12),

          // Filter chips
          Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('New', 'new'),
              const SizedBox(width: 8),
              _buildFilterChip('Messaged', 'messaged'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.richGold : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.richGold : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
