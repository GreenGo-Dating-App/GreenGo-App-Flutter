/**
 * Achievements Screen
 * Points 176-185: Display all achievements with progress
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/usecases/get_user_achievements.dart';
import '../bloc/gamification_bloc.dart';
import '../bloc/gamification_event.dart';
import '../bloc/gamification_state.dart';
import '../widgets/achievement_card.dart';
import '../widgets/achievement_unlock_dialog.dart';

class AchievementsScreen extends StatefulWidget {
  final String userId;

  const AchievementsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AchievementCategory.values.length + 1, // +1 for "All"
      vsync: this,
    );

    // Load achievements
    context.read<GamificationBloc>().add(LoadUserAchievements(widget.userId));
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
        title: const Text('Achievements'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'All'),
            ...AchievementCategory.values.map((category) {
              return Tab(text: _getCategoryName(category));
            }),
          ],
        ),
      ),
      body: BlocConsumer<GamificationBloc, GamificationState>(
        listener: (context, state) {
          // Show unlock dialog
          if (state.recentlyUnlocked != null) {
            showDialog(
              context: context,
              builder: (context) => AchievementUnlockDialog(
                achievement: state.recentlyUnlocked!,
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
          if (state.achievementsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.achievementsError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.achievementsError!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GamificationBloc>().add(
                            LoadUserAchievements(widget.userId),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.achievementsData == null) {
            return const Center(child: Text('No achievements found'));
          }

          return Column(
            children: [
              _buildProgressHeader(state.achievementsData!),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAchievementsList(
                      state.achievementsData!.allAchievements,
                    ),
                    ...AchievementCategory.values.map((category) {
                      final achievements =
                          state.achievementsData!.byCategory[category] ?? [];
                      return _buildAchievementsList(achievements);
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(UserAchievementsData data) {
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
              _buildStatCard(
                'Total',
                data.totalAchievements.toString(),
                Icons.emoji_events,
              ),
              _buildStatCard(
                'Unlocked',
                data.unlockedCount.toString(),
                Icons.lock_open,
              ),
              _buildStatCard(
                'Progress',
                '${data.progressPercentage}%',
                Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: data.progressPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
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

  Widget _buildAchievementsList(List<AchievementWithProgress> achievements) {
    if (achievements.isEmpty) {
      return const Center(
        child: Text('No achievements in this category'),
      );
    }

    // Group by rarity
    final byRarity = <AchievementRarity, List<AchievementWithProgress>>{};
    for (var achievement in achievements) {
      final rarity = achievement.achievement.rarity;
      byRarity.putIfAbsent(rarity, () => []).add(achievement);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: AchievementRarity.values.map((rarity) {
        final rarityAchievements = byRarity[rarity] ?? [];
        if (rarityAchievements.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _getRarityIcon(rarity),
                    color: _getRarityColor(rarity),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getRarityName(rarity),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getRarityColor(rarity),
                    ),
                  ),
                ],
              ),
            ),
            ...rarityAchievements.map((achievement) {
              return AchievementCard(
                achievement: achievement.achievement,
                progress: achievement.progress,
                onTap: () => _onAchievementTap(achievement),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  void _onAchievementTap(AchievementWithProgress achievement) {
    // Show achievement details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.achievement.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.achievement.description),
            const SizedBox(height: 16),
            Text(
              'Progress: ${achievement.currentProgress}/${achievement.achievement.requiredCount}',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: achievement.progressPercentage / 100,
            ),
            const SizedBox(height: 16),
            Text(
              'Reward: ${achievement.achievement.rewardAmount} ${achievement.achievement.rewardType}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (achievement.isUnlocked)
            const Chip(
              label: Text('Unlocked!'),
              backgroundColor: Colors.green,
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.engagement:
        return 'Engagement';
      case AchievementCategory.premium:
        return 'Premium';
      case AchievementCategory.milestones:
        return 'Milestones';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  IconData _getRarityIcon(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Icons.star_border;
      case AchievementRarity.uncommon:
        return Icons.star_half;
      case AchievementRarity.rare:
        return Icons.star;
      case AchievementRarity.epic:
        return Icons.stars;
      case AchievementRarity.legendary:
        return Icons.auto_awesome;
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }
}
