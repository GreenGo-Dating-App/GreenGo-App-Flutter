import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/user_journey.dart';

/// Journey Screen
/// Shows user's progression path with milestones and rewards
class JourneyScreen extends StatefulWidget {
  final String userId;
  final UserJourney? journey;

  const JourneyScreen({
    super.key,
    required this.userId,
    this.journey,
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: JourneyCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedIds = widget.journey?.completedMilestones
            .map((m) => m.milestoneId)
            .toSet() ??
        {};
    final overallProgress = widget.journey?.overallProgress ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.backgroundDark,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(overallProgress, completedIds.length),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.richGold,
              labelColor: AppColors.richGold,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: JourneyCategory.values.map((category) {
                return Tab(text: category.displayName);
              }).toList(),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: JourneyCategory.values.map((category) {
            final milestones = JourneyMilestones.getByCategory(category);
            return _MilestonesListView(
              category: category,
              milestones: milestones,
              completedIds: completedIds,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress, int completedCount) {
    final totalMilestones = JourneyMilestones.all.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.richGold.withValues(alpha: 0.3),
            AppColors.backgroundDark,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Space for app bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.explore,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Journey',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$completedCount / $totalMilestones milestones',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.richGold,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${progress.toInt()}%',
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.bold,
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
}

class _MilestonesListView extends StatelessWidget {
  final JourneyCategory category;
  final List<JourneyMilestone> milestones;
  final Set<String> completedIds;

  const _MilestonesListView({
    required this.category,
    required this.milestones,
    required this.completedIds,
  });

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const Text(
              'No milestones in this category yet',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: milestones.length + 1, // +1 for category header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
            child: Text(
              category.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          );
        }

        final milestone = milestones[index - 1];
        final isCompleted = completedIds.contains(milestone.milestoneId);
        final isLocked = milestone.prerequisiteMilestoneId != null &&
            !completedIds.contains(milestone.prerequisiteMilestoneId);

        return _MilestoneCard(
          milestone: milestone,
          isCompleted: isCompleted,
          isLocked: isLocked,
          progress: isCompleted ? 100 : 0, // TODO: Get actual progress
        );
      },
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final JourneyMilestone milestone;
  final bool isCompleted;
  final bool isLocked;
  final int progress;

  const _MilestoneCard({
    required this.milestone,
    required this.isCompleted,
    required this.isLocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isCompleted
              ? AppColors.successGreen
              : isLocked
                  ? AppColors.divider
                  : AppColors.richGold.withValues(alpha: 0.5),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Main content
          InkWell(
            onTap: isLocked ? null : () => _showMilestoneDetails(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  // Icon/Status
                  _buildIcon(),
                  const SizedBox(width: AppDimensions.paddingM),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                milestone.name,
                                style: TextStyle(
                                  color: isLocked
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DONE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (isLocked)
                              const Icon(
                                Icons.lock,
                                color: AppColors.textTertiary,
                                size: 18,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          milestone.description,
                          style: TextStyle(
                            color: isLocked
                                ? AppColors.textTertiary.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (!isCompleted && !isLocked) ...[
                          const SizedBox(height: 8),
                          // Progress bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                    backgroundColor: AppColors.divider,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColors.richGold,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$progress / ${milestone.requiredCount}',
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Rewards section
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.divider.withValues(alpha: 0.3)
                  : AppColors.richGold.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppDimensions.radiusM),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...milestone.rewards.take(3).map((reward) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _RewardChip(
                        reward: reward,
                        isLocked: isLocked,
                      ),
                    )),
                if (milestone.rewards.length > 3)
                  Text(
                    '+${milestone.rewards.length - 3} more',
                    style: TextStyle(
                      color: isLocked
                          ? AppColors.textTertiary
                          : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (isCompleted) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: const Icon(
          Icons.check_circle,
          color: AppColors.successGreen,
          size: 28,
        ),
      );
    }

    if (isLocked) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: const Icon(
          Icons.lock_outline,
          color: AppColors.textTertiary,
          size: 24,
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: const Icon(
        Icons.flag,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  void _showMilestoneDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MilestoneDetailsSheet(
        milestone: milestone,
        isCompleted: isCompleted,
        progress: progress,
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final JourneyReward reward;
  final bool isLocked;

  const _RewardChip({
    required this.reward,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getRewardIcon(),
          color: isLocked ? AppColors.textTertiary : _getRewardColor(),
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          _getRewardText(),
          style: TextStyle(
            color: isLocked ? AppColors.textTertiary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getRewardIcon() {
    switch (reward.type) {
      case 'coins':
        return Icons.monetization_on;
      case 'xp':
        return Icons.star;
      case 'badge':
        return Icons.military_tech;
      case 'boost':
        return Icons.rocket_launch;
      case 'feature_unlock':
        return Icons.lock_open;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getRewardColor() {
    switch (reward.type) {
      case 'coins':
        return AppColors.richGold;
      case 'xp':
        return Colors.purple;
      case 'badge':
        return Colors.orange;
      case 'boost':
        return Colors.blue;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getRewardText() {
    if (reward.description != null) {
      return reward.description!;
    }
    switch (reward.type) {
      case 'coins':
        return '+${reward.amount}';
      case 'xp':
        return '+${reward.amount} XP';
      case 'badge':
        return 'Badge';
      case 'boost':
        return '${reward.amount}x Boost';
      default:
        return '+${reward.amount}';
    }
  }
}

class _MilestoneDetailsSheet extends StatelessWidget {
  final JourneyMilestone milestone;
  final bool isCompleted;
  final int progress;

  const _MilestoneDetailsSheet({
    required this.milestone,
    required this.isCompleted,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: isCompleted
                  ? LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isCompleted ? Colors.green : AppColors.richGold)
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.flag,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            milestone.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            milestone.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingL),

          // Progress
          if (!isCompleted) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Progress: $progress / ${milestone.requiredCount}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / milestone.requiredCount,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.richGold,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
          ],

          // Rewards
          const Text(
            'Rewards',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: milestone.rewards.map((reward) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundInput,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _RewardChip(reward: reward, isLocked: false),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.paddingL),
        ],
      ),
    );
  }
}
