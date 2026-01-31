import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/user_journey.dart';

/// Journey Screen
/// Shows user's progression path with milestones and rewards
/// Premium glass morphism UI design
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
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerScaleAnimation;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: JourneyCategory.values.length,
      vsync: this,
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _headerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    final overallProgress = widget.journey?.overallProgress ?? 0.0;
    _progressAnimation = Tween<double>(begin: 0.0, end: overallProgress / 100)
        .animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _headerAnimationController.forward();
    _progressAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    _progressAnimationController.dispose();
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
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.richGold.withValues(alpha: 0.15),
              Colors.black,
              Colors.black,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildGlassHeader(overallProgress, completedIds.length),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: _buildGlassTabBar(),
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
      ),
    );
  }

  Widget _buildGlassTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              padding: const EdgeInsets.all(4),
              tabs: JourneyCategory.values.map((category) {
                return Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getCategoryEmoji(category)),
                        const SizedBox(width: 4),
                        Text(category.displayName),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(JourneyCategory category) {
    switch (category) {
      case JourneyCategory.gettingStarted:
        return '🌱';
      case JourneyCategory.socializing:
        return '💬';
      case JourneyCategory.premium:
        return '👑';
      case JourneyCategory.mastery:
        return '🏆';
      case JourneyCategory.special:
        return '⭐';
    }
  }

  Widget _buildGlassHeader(double progress, int completedCount) {
    final totalMilestones = JourneyMilestones.all.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 70),
        child: Column(
          children: [
            // Animated journey icon
            ScaleTransition(
              scale: _headerScaleAnimation,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    const Text(
                      '🗺️',
                      style: TextStyle(fontSize: 40),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Your Journey',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$completedCount of $totalMilestones milestones completed',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Glass progress card
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Overall Progress',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Text(
                                '${(_progressAnimation.value * 100).toInt()}%',
                                style: const TextStyle(
                                  color: AppColors.richGold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Enhanced progress bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.divider.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: _progressAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD700),
                                          Color(0xFFB8860B),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.richGold
                                              .withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.2),
                ),
              ),
              child: const Center(
                child: Text(
                  '🔒',
                  style: TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const Text(
              'No milestones yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete previous categories to unlock',
              style: TextStyle(
                color: AppColors.textTertiary.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: milestones.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildCategoryHeader();
        }

        final milestone = milestones[index - 1];
        final isCompleted = completedIds.contains(milestone.milestoneId);
        final isLocked = milestone.prerequisiteMilestoneId != null &&
            !completedIds.contains(milestone.prerequisiteMilestoneId);

        return _GlassMilestoneCard(
          milestone: milestone,
          isCompleted: isCompleted,
          isLocked: isLocked,
          progress: isCompleted ? milestone.requiredCount : 0,
          index: index - 1,
        );
      },
    );
  }

  Widget _buildCategoryHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingL),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _getCategoryEmoji(),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.description,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.richGold.withValues(alpha: 0.3),
                        AppColors.richGold.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${milestones.length}',
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji() {
    switch (category) {
      case JourneyCategory.gettingStarted:
        return '🌱';
      case JourneyCategory.socializing:
        return '💬';
      case JourneyCategory.premium:
        return '👑';
      case JourneyCategory.mastery:
        return '🏆';
      case JourneyCategory.special:
        return '⭐';
    }
  }
}

class _GlassMilestoneCard extends StatefulWidget {
  final JourneyMilestone milestone;
  final bool isCompleted;
  final bool isLocked;
  final int progress;
  final int index;

  const _GlassMilestoneCard({
    required this.milestone,
    required this.isCompleted,
    required this.isLocked,
    required this.progress,
    required this.index,
  });

  @override
  State<_GlassMilestoneCard> createState() => _GlassMilestoneCardState();
}

class _GlassMilestoneCardState extends State<_GlassMilestoneCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isCompleted
                        ? AppColors.successGreen.withValues(alpha: 0.5)
                        : widget.isLocked
                            ? AppColors.divider.withValues(alpha: 0.3)
                            : AppColors.richGold.withValues(alpha: 0.3),
                    width: widget.isCompleted ? 2 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.isLocked
                        ? null
                        : () => _showMilestoneDetails(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        _buildMainContent(),
                        _buildRewardsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildMilestoneIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.milestone.name,
                        style: TextStyle(
                          color: widget.isLocked
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (widget.isCompleted) _buildCompletedBadge(),
                    if (widget.isLocked) _buildLockedIcon(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.milestone.description,
                  style: TextStyle(
                    color: widget.isLocked
                        ? AppColors.textTertiary.withValues(alpha: 0.6)
                        : AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                if (!widget.isCompleted && !widget.isLocked)
                  _buildProgressBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneIcon() {
    if (widget.isCompleted) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.successGreen.withValues(alpha: 0.3),
              AppColors.successGreen.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.5),
          ),
        ),
        child: const Center(
          child: Text(
            '✅',
            style: TextStyle(fontSize: 28),
          ),
        ),
      );
    }

    if (widget.isLocked) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.3),
          ),
        ),
        child: const Center(
          child: Text(
            '🔒',
            style: TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🎯',
          style: TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successGreen,
            AppColors.successGreen.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check,
            color: Colors.white,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            'DONE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock,
        color: AppColors.textTertiary,
        size: 16,
      ),
    );
  }

  Widget _buildProgressBar() {
    final progressPercent = widget.progress / widget.milestone.requiredCount;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.divider.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progressPercent.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.richGold.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${widget.progress}/${widget.milestone.requiredCount}',
            style: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isLocked
              ? [
                  AppColors.divider.withValues(alpha: 0.1),
                  AppColors.divider.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.richGold.withValues(alpha: 0.15),
                  AppColors.richGold.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...widget.milestone.rewards.take(3).map(
                (reward) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _GlassRewardChip(
                    reward: reward,
                    isLocked: widget.isLocked,
                  ),
                ),
              ),
          if (widget.milestone.rewards.length > 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${widget.milestone.rewards.length - 3}',
                style: TextStyle(
                  color: widget.isLocked
                      ? AppColors.textTertiary
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMilestoneDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GlassMilestoneDetailsSheet(
        milestone: widget.milestone,
        isCompleted: widget.isCompleted,
        progress: widget.progress,
      ),
    );
  }
}

class _GlassRewardChip extends StatelessWidget {
  final JourneyReward reward;
  final bool isLocked;

  const _GlassRewardChip({
    required this.reward,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocked
              ? AppColors.divider.withValues(alpha: 0.2)
              : _getRewardColor().withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getRewardEmoji(),
            style: TextStyle(
              fontSize: 14,
              color: isLocked ? Colors.grey : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _getRewardText(),
            style: TextStyle(
              color: isLocked ? AppColors.textTertiary : _getRewardColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRewardEmoji() {
    switch (reward.type) {
      case 'coins':
        return '🪙';
      case 'xp':
        return '⭐';
      case 'badge':
        return '🏅';
      case 'boost':
        return '🚀';
      case 'feature_unlock':
        return '🔓';
      default:
        return '🎁';
    }
  }

  Color _getRewardColor() {
    switch (reward.type) {
      case 'coins':
        return AppColors.richGold;
      case 'xp':
        return Colors.purple.shade300;
      case 'badge':
        return Colors.orange.shade300;
      case 'boost':
        return Colors.blue.shade300;
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
        return '${reward.amount}x';
      default:
        return '+${reward.amount}';
    }
  }
}

class _GlassMilestoneDetailsSheet extends StatelessWidget {
  final JourneyMilestone milestone;
  final bool isCompleted;
  final int progress;

  const _GlassMilestoneDetailsSheet({
    required this.milestone,
    required this.isCompleted,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.3),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Icon with glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: isCompleted
                          ? LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade700
                              ],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                            ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isCompleted
                                  ? Colors.green
                                  : AppColors.richGold)
                              .withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isCompleted ? '🏆' : '🎯',
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    milestone.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestone.description,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Progress section
                  if (!isCompleted) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.richGold.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Progress',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '$progress / ${milestone.requiredCount}',
                                    style: const TextStyle(
                                      color: AppColors.richGold,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.divider.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Stack(
                                  children: [
                                    FractionallySizedBox(
                                      widthFactor:
                                          (progress / milestone.requiredCount)
                                              .clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD700),
                                              Color(0xFFB8860B),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.richGold
                                                  .withValues(alpha: 0.5),
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
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Rewards section
                  const Text(
                    '🎁 Rewards',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: milestone.rewards.map((reward) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppColors.richGold.withValues(alpha: 0.3),
                              ),
                            ),
                            child: _GlassRewardChip(
                              reward: reward,
                              isLocked: false,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
