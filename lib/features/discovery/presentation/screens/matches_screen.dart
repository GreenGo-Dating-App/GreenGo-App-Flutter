import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/matches_bloc.dart';
import '../bloc/matches_event.dart';
import '../bloc/matches_state.dart';
import '../widgets/match_card_widget.dart';
import 'profile_detail_screen.dart';

/// Matches Screen
///
/// Displays user's matches
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

class _MatchesScreenContent extends StatelessWidget {
  final String userId;

  const _MatchesScreenContent({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Matches',
          style: TextStyle(
            color: AppColors.richGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context
                  .read<MatchesBloc>()
                  .add(MatchesRefreshRequested(userId));
            },
            icon: const Icon(
              Icons.refresh,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
                          .add(MatchesLoadRequested(userId: userId));
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No matches yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
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
            );
          }

          if (state is MatchesLoaded) {
            final newMatches = state.getNewMatches(userId);
            final allMatches = state.matches;

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<MatchesBloc>()
                    .add(MatchesRefreshRequested(userId));
              },
              color: AppColors.richGold,
              child: CustomScrollView(
                slivers: [
                  // New matches section
                  if (newMatches.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: AppColors.richGold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'New Matches (${newMatches.length})',
                              style: const TextStyle(
                                color: AppColors.richGold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final match = newMatches[index];
                            final profile = state.profiles[match.getOtherUserId(userId)];

                            return MatchCardWidget(
                              match: match,
                              profile: profile,
                              currentUserId: userId,
                              onTap: () {
                                // Mark as seen
                                context.read<MatchesBloc>().add(
                                      MatchMarkedAsSeen(
                                        matchId: match.matchId,
                                        userId: userId,
                                      ),
                                    );

                                // Navigate to match profile detail
                                if (profile != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ProfileDetailScreen(
                                        profile: profile,
                                        currentUserId: userId,
                                        match: match,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                          childCount: newMatches.length,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: AppColors.divider),
                      ),
                    ),
                  ],

                  // All matches section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'All Matches (${allMatches.length})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final match = allMatches[index];
                          final profile = state.profiles[match.getOtherUserId(userId)];

                          return MatchCardWidget(
                            match: match,
                            profile: profile,
                            currentUserId: userId,
                            onTap: () {
                              // Mark as seen if not seen
                              if (match.isNewMatch(userId)) {
                                context.read<MatchesBloc>().add(
                                      MatchMarkedAsSeen(
                                        matchId: match.matchId,
                                        userId: userId,
                                      ),
                                    );
                              }

                              // Navigate to match profile detail
                              if (profile != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProfileDetailScreen(
                                      profile: profile,
                                      currentUserId: userId,
                                      match: match,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                        childCount: allMatches.length,
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
}
