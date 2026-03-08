/**
 * Achievements Screen
 * Points 176-185: Display all achievements with progress and premium UI
 */

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
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
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'All',
    ...AchievementCategory.values.map((c) => _getCategoryName(c)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length,
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

  static String _getCategoryName(AchievementCategory category) {
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

  String _getLocalizedCategoryLabel(int index) {
    final l10n = AppLocalizations.of(context)!;
    if (index == 0) return l10n.gamificationAll;
    final category = AchievementCategory.values[index - 1];
    switch (category) {
      case AchievementCategory.social:
        return l10n.gamificationSocial;
      case AchievementCategory.engagement:
        return l10n.gamificationEngagement;
      case AchievementCategory.premium:
        return l10n.gamificationPremium;
      case AchievementCategory.milestones:
        return l10n.gamificationMilestones;
      case AchievementCategory.special:
        return l10n.gamificationSpecial;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.achievementsTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.richGold,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.achievementsLoading) {
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
                    l10n.gamificationLoadingAchievements,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.achievementsError != null) {
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
                    state.achievementsError!,
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<GamificationBloc>().add(
                            LoadUserAchievements(widget.userId),
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

          if (state.achievementsData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.gamificationNoAchievements,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Progress Header
              _buildProgressHeader(state.achievementsData!),

              // Category Filter
              _buildCategoryFilter(),

              // Achievements Grid
              Expanded(
                child: _buildAchievementsGrid(state.achievementsData!),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(UserAchievementsData data) {
    final l10n = AppLocalizations.of(context)!;
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '🏆',
                    '${data.unlockedCount}/${data.totalAchievements}',
                    l10n.gamificationUnlocked,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  _buildStatItem(
                    '📊',
                    '${data.progressPercentage}%',
                    l10n.gamificationProgress,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: data.progressPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), AppColors.richGold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.richGold.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), AppColors.richGold],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Center(
                child: Text(
                  _getLocalizedCategoryLabel(index),
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsGrid(UserAchievementsData data) {
    final l10n = AppLocalizations.of(context)!;
    List<AchievementWithProgress> achievements;

    if (_selectedCategoryIndex == 0) {
      achievements = data.allAchievements;
    } else {
      final category = AchievementCategory.values[_selectedCategoryIndex - 1];
      achievements = data.byCategory[category] ?? [];
    }

    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              l10n.gamificationNoAchievementsInCategory,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievementWithProgress = achievements[index];
        return _buildAchievementCard(achievementWithProgress, index);
      },
    );
  }

  Widget _buildAchievementCard(AchievementWithProgress achievementWithProgress, int index) {
    final achievement = achievementWithProgress.achievement;
    final isUnlocked = achievementWithProgress.isUnlocked;
    final progress = achievementWithProgress.progressPercentage / 100;

    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF3B82F6),
      const Color(0xFFFF6B6B),
    ];
    final color = isUnlocked ? colors[index % colors.length] : Colors.grey;

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievementWithProgress),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(isUnlocked ? 0.2 : 0.1),
                  color.withOpacity(isUnlocked ? 0.05 : 0.02),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(isUnlocked ? 0.4 : 0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnlocked
                        ? LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          )
                        : null,
                    color: isUnlocked ? null : Colors.grey.withOpacity(0.3),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _getAchievementIcon(achievement.achievementId),
                    color: isUnlocked ? Colors.white : Colors.grey,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 6),

                // Name
                Text(
                  achievement.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? Colors.white : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Progress or Unlocked badge
                if (isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          '${achievementWithProgress.currentProgress}/${achievement.requiredCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${achievementWithProgress.currentProgress}/${achievement.requiredCount}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(AchievementWithProgress achievementWithProgress) {
    final l10n = AppLocalizations.of(context)!;
    final achievement = achievementWithProgress.achievement;
    final isUnlocked = achievementWithProgress.isUnlocked;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnlocked
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), AppColors.richGold],
                          )
                        : null,
                    color: isUnlocked ? null : Colors.grey.withOpacity(0.3),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: AppColors.richGold.withOpacity(0.4),
                              blurRadius: 20,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _getAchievementIcon(achievement.achievementId),
                    color: isUnlocked ? Colors.white : Colors.grey,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  achievement.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Progress
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.gamificationProgress,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${achievementWithProgress.currentProgress}/${achievement.requiredCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: (achievementWithProgress.progressPercentage / 100).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), AppColors.richGold],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Reward
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.richGold.withOpacity(0.2),
                        AppColors.richGold.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.richGold.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: AppColors.richGold, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        l10n.gamificationReward(achievement.rewardAmount, achievement.rewardType),
                        style: const TextStyle(
                          color: AppColors.richGold,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.social:
        return Icons.people_rounded;
      case AchievementCategory.engagement:
        return Icons.local_fire_department_rounded;
      case AchievementCategory.premium:
        return Icons.diamond_rounded;
      case AchievementCategory.milestones:
        return Icons.flag_rounded;
      case AchievementCategory.special:
        return Icons.star_rounded;
    }
  }

  /// Get a unique icon for each achievement
  static IconData _getAchievementIcon(String achievementId) {
    switch (achievementId) {
      case 'first_match':
        return Icons.handshake;
      case 'conversation_starter':
        return Icons.chat_bubble;
      case 'video_champion':
        return Icons.videocam;
      case 'profile_master':
        return Icons.person_pin;
      case 'globe_trotter':
        return Icons.public;
      case 'generous_heart':
        return Icons.card_giftcard;
      case 'daily_dedication':
        return Icons.calendar_today;
      case 'super_star':
        return Icons.star;
      case 'social_butterfly':
        return Icons.groups;
      case 'perfect_week':
        return Icons.event_available;
      case 'early_bird':
        return Icons.wb_sunny;
      case 'night_owl':
        return Icons.nightlight_round;
      case 'centurion':
        return Icons.military_tech;
      case 'speed_dater':
        return Icons.bolt;
      case 'photo_collector':
        return Icons.photo_library;
      case 'trend_setter':
        return Icons.trending_up;
      case 'verified':
        return Icons.verified;
      case 'premium_member':
        return Icons.workspace_premium;
      case 'coin_collector':
        return Icons.monetization_on;
      case 'monthly_streak':
        return Icons.local_fire_department;
      case 'vocabulary_beginner':
        return Icons.abc;
      case 'vocabulary_intermediate':
        return Icons.spellcheck;
      case 'vocabulary_advanced':
        return Icons.menu_book;
      case 'vocabulary_master':
        return Icons.auto_stories;
      case 'rare_word_hunter':
        return Icons.search;
      default:
        return Icons.emoji_events;
    }
  }
}
