/**
 * Daily Challenges Screen
 * Points 196-199: Display daily and weekly challenges with premium UI
 */

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
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
      backgroundColor: Colors.black,
      body: BlocConsumer<GamificationBloc, GamificationState>(
        listener: (context, state) {
          // Show completion notification
          if (state.recentlyCompleted != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${state.recentlyCompleted!.name} completed!'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.richGold,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.challengesLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.richGold.withOpacity(0.3),
                          AppColors.richGold.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(
                        color: AppColors.richGold,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading challenges...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.challengesError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.challengesError!,
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<GamificationBloc>().add(
                            LoadDailyChallenges(widget.userId),
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.challengesData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'No challenges available',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final data = state.challengesData!;

          return Column(
            children: [
              // Rewards summary header
              _buildRewardsSummary(data),

              // Tab selector
              _buildTabSelector(),

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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.richGold.withOpacity(0.2),
                AppColors.richGold.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: AppColors.richGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Available Rewards Row
              Row(
                children: [
                  Expanded(
                    child: _buildRewardCard(
                      '⭐',
                      '${data.totalXPAvailable}',
                      'XP Available',
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRewardCard(
                      '💰',
                      '${data.totalCoinsAvailable}',
                      'Coins Available',
                      const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress Row
              Row(
                children: [
                  Expanded(
                    child: _buildCompletionProgress(
                      'Daily',
                      data.completedDaily,
                      data.totalDaily,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompletionProgress(
                      'Weekly',
                      data.completedWeekly,
                      data.totalWeekly,
                      const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionProgress(String label, int completed, int total, Color color) {
    final percentage = total > 0 ? (completed / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            Text(
              '$completed/$total',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withOpacity(0.1),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), AppColors.richGold],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.today, size: 18),
                SizedBox(width: 8),
                Text('Daily'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_view_week, size: 18),
                SizedBox(width: 8),
                Text('Weekly'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesList(List<ChallengeWithProgress> challenges, String type) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 40,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type challenges available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challengeWithProgress = challenges[index];
        return _buildChallengeCard(challengeWithProgress, index);
      },
    );
  }

  Widget _buildChallengeCard(ChallengeWithProgress challengeWithProgress, int index) {
    final challenge = challengeWithProgress.challenge;
    final isCompleted = challengeWithProgress.isCompleted;
    final canClaim = challengeWithProgress.canClaim;
    final currentProgress = challengeWithProgress.currentProgress;
    final progressValue = challenge.requiredCount > 0
        ? currentProgress / challenge.requiredCount
        : 0.0;

    final colors = [
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFFFF6B6B),
    ];
    final color = isCompleted ? const Color(0xFF10B981) : colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : _getDifficultyIcon(challenge.difficulty),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Challenge info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  challenge.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              _buildDifficultyBadge(challenge.difficulty),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: progressValue.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      gradient: LinearGradient(
                                        colors: [color, color.withOpacity(0.7)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$currentProgress / ${challenge.requiredCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Rewards
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '+${challenge.rewardXP}',
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (challenge.rewardCoins > 0) ...[
                            const SizedBox(width: 8),
                            const Text('💰', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '+${challenge.rewardCoins}',
                              style: const TextStyle(
                                color: AppColors.richGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Claim button
                if (canClaim) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _claimReward(challenge.challengeId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Claim Reward',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(ChallengeDifficulty difficulty) {
    final colors = {
      ChallengeDifficulty.easy: const Color(0xFF10B981),
      ChallengeDifficulty.medium: const Color(0xFFF59E0B),
      ChallengeDifficulty.hard: const Color(0xFFEF4444),
      ChallengeDifficulty.epic: const Color(0xFF8B5CF6),
    };
    final labels = {
      ChallengeDifficulty.easy: 'Easy',
      ChallengeDifficulty.medium: 'Medium',
      ChallengeDifficulty.hard: 'Hard',
      ChallengeDifficulty.epic: 'Epic',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors[difficulty]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors[difficulty]!.withOpacity(0.4),
        ),
      ),
      child: Text(
        labels[difficulty]!,
        style: TextStyle(
          color: colors[difficulty],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getDifficultyIcon(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return Icons.star_border_rounded;
      case ChallengeDifficulty.medium:
        return Icons.star_half_rounded;
      case ChallengeDifficulty.hard:
        return Icons.star_rounded;
      case ChallengeDifficulty.epic:
        return Icons.auto_awesome_rounded;
    }
  }

  void _claimReward(String challengeId) {
    context.read<GamificationBloc>().add(
          ClaimChallengeRewardEvent(
            userId: widget.userId,
            challengeId: challengeId,
          ),
        );
  }
}
