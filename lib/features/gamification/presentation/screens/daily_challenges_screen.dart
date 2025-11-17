/**
 * Daily Challenges Screen
 * Points 196-199: Display daily and weekly challenges with progress tracking
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/daily_challenge.dart';
import '../../domain/usecases/get_daily_challenges.dart';
import '../bloc/gamification_bloc.dart';
import '../bloc/gamification_event.dart';
import '../bloc/gamification_state.dart';
import '../widgets/challenge_card.dart';

class DailyChallengesScreen extends StatefulWidget {
  final String userId;

  const DailyChallengesScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<DailyChallengesScreen> createState() => _DailyChallengesScreenState();
}

class _DailyChallengesScreenState extends State<DailyChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load challenges
    context.read<GamificationBloc>().add(LoadDailyChallenges(widget.userId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'), // Point 199
          ],
        ),
      ),
      body: BlocConsumer<GamificationBloc, GamificationState>(
        listener: (context, state) {
          // Show completion notification
          if (state.recentlyCompleted != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.recentlyCompleted!.name} completed!',
                ),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Claim',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<GamificationBloc>().add(
                          ClaimChallengeRewardEvent(
                            userId: widget.userId,
                            challengeId: state.recentlyCompleted!.challengeId,
                          ),
                        );
                  },
                ),
              ),
            );
          }

          // Show success message
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.challengesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.challengesError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.challengesError!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GamificationBloc>().add(
                            LoadDailyChallenges(widget.userId),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.challengesData == null) {
            return const Center(child: Text('No challenges found'));
          }

          final data = state.challengesData!;

          return Column(
            children: [
              // Rewards summary header
              _buildRewardsSummary(data),

              // Challenges list
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChallengesList(data.dailyChallenges, 'daily'),
                    _buildChallengesList(data.weeklyChallenges, 'weekly'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardsSummary(DailyChallengesData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'Available',
                '${data.totalXPAvailable} XP',
                Icons.trending_up,
              ),
              _buildStat(
                'Available',
                '${data.totalCoinsAvailable} Coins',
                Icons.monetization_on,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompletionStat(
                'Daily',
                data.completedDaily,
                data.totalDaily,
              ),
              _buildCompletionStat(
                'Weekly',
                data.completedWeekly,
                data.totalWeekly,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionStat(String label, int completed, int total) {
    final percentage = total > 0 ? (completed / total * 100).round() : 0;

    return Column(
      children: [
        Text(
          '$label: $completed/$total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$percentage%',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengesList(
    List<ChallengeWithProgress> challenges,
    String type,
  ) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No $type challenges available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Group challenges by difficulty
    final byDifficulty = <ChallengeDifficulty, List<ChallengeWithProgress>>{};
    for (var challenge in challenges) {
      final difficulty = challenge.challenge.difficulty;
      byDifficulty.putIfAbsent(difficulty, () => []).add(challenge);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: ChallengeDifficulty.values.map((difficulty) {
        final difficultyChallenges = byDifficulty[difficulty] ?? [];
        if (difficultyChallenges.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _getDifficultyIcon(difficulty),
                    color: _getDifficultyColor(difficulty),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getDifficultyName(difficulty),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(difficulty),
                    ),
                  ),
                ],
              ),
            ),
            ...difficultyChallenges.map((challenge) {
              return ChallengeCard(
                challenge: challenge.challenge,
                progress: challenge.progress,
                onClaim: challenge.canClaim
                    ? () => _claimReward(challenge.challenge.challengeId)
                    : null,
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  void _claimReward(String challengeId) {
    context.read<GamificationBloc>().add(
          ClaimChallengeRewardEvent(
            userId: widget.userId,
            challengeId: challengeId,
          ),
        );
  }

  String _getDifficultyName(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
      case ChallengeDifficulty.epic:
        return 'Epic';
    }
  }

  IconData _getDifficultyIcon(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return Icons.star_border;
      case ChallengeDifficulty.medium:
        return Icons.star_half;
      case ChallengeDifficulty.hard:
        return Icons.star;
      case ChallengeDifficulty.epic:
        return Icons.auto_awesome;
    }
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.green;
      case ChallengeDifficulty.medium:
        return Colors.orange;
      case ChallengeDifficulty.hard:
        return Colors.red;
      case ChallengeDifficulty.epic:
        return Colors.purple;
    }
  }
}
