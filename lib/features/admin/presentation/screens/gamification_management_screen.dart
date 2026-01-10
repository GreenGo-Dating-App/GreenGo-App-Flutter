import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../gamification/domain/entities/achievement.dart';
import '../../../gamification/domain/entities/daily_challenge.dart';
import '../../../gamification/domain/entities/login_streak.dart';

/// Gamification Management Screen
/// Admin interface for managing achievements, challenges, and streaks
class GamificationManagementScreen extends StatefulWidget {
  final String adminId;
  final String? initialTab;

  const GamificationManagementScreen({
    super.key,
    required this.adminId,
    this.initialTab,
  });

  @override
  State<GamificationManagementScreen> createState() =>
      _GamificationManagementScreenState();
}

class _GamificationManagementScreenState
    extends State<GamificationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Set initial tab if provided
    if (widget.initialTab != null) {
      switch (widget.initialTab) {
        case 'achievements':
          _tabController.index = 0;
          break;
        case 'challenges':
          _tabController.index = 1;
          break;
        case 'streaks':
          _tabController.index = 2;
          break;
        case 'events':
          _tabController.index = 3;
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          'Gamification',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
            Tab(icon: Icon(Icons.today), text: 'Challenges'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'Streaks'),
            Tab(icon: Icon(Icons.celebration), text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AchievementsTab(adminId: widget.adminId),
          _ChallengesTab(adminId: widget.adminId),
          _StreaksTab(adminId: widget.adminId),
          _EventsTab(adminId: widget.adminId),
        ],
      ),
    );
  }
}

/// Achievements Tab
class _AchievementsTab extends StatelessWidget {
  final String adminId;

  const _AchievementsTab({required this.adminId});

  @override
  Widget build(BuildContext context) {
    final categories = AchievementCategory.values;

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final achievements = Achievements.getByCategory(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingS,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${achievements.length} achievements',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ...achievements.map((achievement) => _AchievementCard(
                  achievement: achievement,
                  onEdit: () => _showEditAchievementDialog(context, achievement),
                )),
            const SizedBox(height: AppDimensions.paddingM),
          ],
        );
      },
    );
  }

  void _showEditAchievementDialog(
    BuildContext context,
    Achievement achievement,
  ) {
    final nameController = TextEditingController(text: achievement.name);
    final descController = TextEditingController(text: achievement.description);
    final countController =
        TextEditingController(text: achievement.requiredCount.toString());
    final rewardController =
        TextEditingController(text: achievement.rewardAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Edit Achievement',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: nameController,
                label: 'Name',
                icon: Icons.title,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildTextField(
                controller: descController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildTextField(
                controller: countController,
                label: 'Required Count',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: rewardController,
                      label: 'Reward Amount',
                      icon: Icons.card_giftcard,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundInput,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      achievement.rewardType.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Achievement updated'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.richGold),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onEdit;

  const _AchievementCard({
    required this.achievement,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(achievement.rarity.colorValue).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.emoji_events,
            color: Color(achievement.rarity.colorValue),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                achievement.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(achievement.rarity.colorValue).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                achievement.rarity.displayName,
                style: TextStyle(
                  color: Color(achievement.rarity.colorValue),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  achievement.rewardType == 'coins'
                      ? Icons.monetization_on
                      : Icons.star,
                  color: achievement.rewardType == 'coins'
                      ? AppColors.richGold
                      : Colors.purple,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${achievement.rewardAmount} ${achievement.rewardType}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.flag, color: AppColors.textTertiary, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Requires: ${achievement.requiredCount}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textSecondary),
          onPressed: onEdit,
        ),
        isThreeLine: true,
      ),
    );
  }
}

/// Challenges Tab
class _ChallengesTab extends StatelessWidget {
  final String adminId;

  const _ChallengesTab({required this.adminId});

  @override
  Widget build(BuildContext context) {
    final dailyChallenges = DailyChallenges.getRotatingChallenges();
    final weeklyChallenges = WeeklyChallenges.getWeeklyChallenges();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add new challenge button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddChallengeDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create New Challenge'),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),

          // Daily Challenges
          const Text(
            'Daily Challenges',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          ...dailyChallenges.map((c) => _ChallengeCard(challenge: c)),
          const SizedBox(height: AppDimensions.paddingL),

          // Weekly Challenges
          const Text(
            'Weekly Challenges',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          ...weeklyChallenges.map((c) => _ChallengeCard(challenge: c)),
        ],
      ),
    );
  }

  void _showAddChallengeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Create Challenge',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Challenge creation interface coming soon.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(challenge.difficulty.colorValue).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.flag,
            color: Color(challenge.difficulty.colorValue),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                challenge.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(challenge.difficulty.colorValue).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                challenge.difficulty.displayName,
                style: TextStyle(
                  color: Color(challenge.difficulty.colorValue),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.description,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                ...challenge.rewards.take(2).map((reward) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            reward.type == 'coins'
                                ? Icons.monetization_on
                                : reward.type == 'xp'
                                    ? Icons.star
                                    : Icons.rocket_launch,
                            color: reward.type == 'coins'
                                ? AppColors.richGold
                                : reward.type == 'xp'
                                    ? Colors.purple
                                    : Colors.orange,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '+${reward.amount}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textSecondary),
          onPressed: () {
            // TODO: Edit challenge
          },
        ),
        isThreeLine: true,
      ),
    );
  }
}

/// Streaks Tab
class _StreaksTab extends StatelessWidget {
  final String adminId;

  const _StreaksTab({required this.adminId});

  @override
  Widget build(BuildContext context) {
    final milestones = StreakMilestones.all;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.2),
                  AppColors.backgroundCard,
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login Streak System',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Configure milestone rewards for consecutive logins',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),

          // Daily Login Rewards
          const Text(
            'Daily Login Rewards',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          _DailyRewardConfigCard(),
          const SizedBox(height: AppDimensions.paddingL),

          // Milestone Rewards
          const Text(
            'Streak Milestones',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          ...milestones.map((m) => _MilestoneCard(milestone: m)),
        ],
      ),
    );
  }
}

class _DailyRewardConfigCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _ConfigRow(
            label: 'Base Coins',
            value: '5',
            icon: Icons.monetization_on,
            iconColor: AppColors.richGold,
          ),
          const Divider(color: AppColors.divider),
          _ConfigRow(
            label: 'Base XP',
            value: '5',
            icon: Icons.star,
            iconColor: Colors.purple,
          ),
          const Divider(color: AppColors.divider),
          _ConfigRow(
            label: 'Streak Multiplier',
            value: '1.5x per day',
            icon: Icons.trending_up,
            iconColor: AppColors.successGreen,
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _ConfigRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            color: AppColors.textTertiary,
            onPressed: () {
              // TODO: Edit config
            },
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final StreakMilestone milestone;

  const _MilestoneCard({required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.red.shade400],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Center(
            child: Text(
              '${milestone.daysRequired}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          milestone.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              milestone.description,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: AppColors.richGold,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${milestone.coinReward}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.star, color: Colors.purple, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+${milestone.xpReward}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (milestone.badgeId != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.military_tech, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Badge',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textSecondary),
          onPressed: () => _showEditMilestoneDialog(context, milestone),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showEditMilestoneDialog(BuildContext context, StreakMilestone milestone) {
    final coinsController =
        TextEditingController(text: milestone.coinReward.toString());
    final xpController =
        TextEditingController(text: milestone.xpReward.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          'Edit ${milestone.name}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: coinsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Coin Reward',
                labelStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(
                  Icons.monetization_on,
                  color: AppColors.richGold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextField(
              controller: xpController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'XP Reward',
                labelStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.star, color: Colors.purple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Milestone updated'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Events Tab
class _EventsTab extends StatelessWidget {
  final String adminId;

  const _EventsTab({required this.adminId});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final events = SeasonalEvents.getAllEvents(currentYear);
    final activeEvent = SeasonalEvents.getActiveEvent();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create event button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateEventDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Seasonal Event'),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),

          // Active event highlight
          if (activeEvent != null) ...[
            const Text(
              'Active Event',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            _EventCard(event: activeEvent, isActive: true),
            const SizedBox(height: AppDimensions.paddingL),
          ],

          // All events
          const Text(
            'Scheduled Events',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          ...events.map((e) => _EventCard(
                event: e,
                isActive: e.eventId == activeEvent?.eventId,
              )),
        ],
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Create Event',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Event creation interface coming soon.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SeasonalEvent event;
  final bool isActive;

  const _EventCard({
    required this.event,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(event.themeConfig['primaryColor'] as int? ?? 0xFFD4AF37);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isActive ? primaryColor : AppColors.divider,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.3),
                  AppColors.backgroundCard,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusM),
                topRight: Radius.circular(AppDimensions.radiusM),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.celebration, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
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
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        event.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.textTertiary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(event.startDate)} - ${_formatDate(event.endDate)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.flag,
                        color: AppColors.textTertiary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${event.challenges.length} challenges',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
