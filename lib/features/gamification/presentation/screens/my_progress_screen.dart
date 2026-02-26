/**
 * My Progress Screen
 * Comprehensive view of user's badges, level, XP, and achievements
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/user_level.dart';
import '../../domain/entities/achievement.dart';
import '../../../../core/utils/safe_navigation.dart';

class MyProgressScreen extends StatefulWidget {
  final String userId;

  const MyProgressScreen({
    super.key,
    required this.userId,
  });

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  // Data
  List<UserBadgeWithDetails> _userBadges = [];
  int _level = 1;
  int _currentXP = 0;
  int _totalXP = 0;
  String _levelTitle = 'Newcomer';
  int _achievementCount = 0;
  int _completedChallenges = 0;

  // Loading states
  bool _loadingBadges = true;
  bool _loadingLevel = true;
  bool _loadingAchievements = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserBadges(),
      _loadUserLevel(),
      _loadAchievements(),
    ]);
  }

  Future<void> _loadUserBadges() async {
    try {
      // Try simple query first (without ordering to avoid index requirement)
      final badgesSnapshot = await FirebaseFirestore.instance
          .collection('userBadges')
          .where('userId', isEqualTo: widget.userId)
          .get();

      final List<UserBadgeWithDetails> badges = [];
      for (final doc in badgesSnapshot.docs) {
        final data = doc.data();
        final badgeId = data['badgeId'] as String?;
        if (badgeId != null) {
          final badge = Badges.getById(badgeId);
          if (badge != null) {
            badges.add(UserBadgeWithDetails(
              userBadge: UserBadge(
                id: doc.id,
                odId: widget.userId,
                badgeId: badgeId,
                earnedAt: (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                isDisplayed: data['isDisplayed'] as bool? ?? false,
                displayPosition: data['displayPosition'] as int? ?? 0,
                source: data['source'] as String?,
              ),
              badge: badge,
            ));
          }
        }
      }

      // Sort locally
      badges.sort((a, b) => b.userBadge.earnedAt.compareTo(a.userBadge.earnedAt));

      if (mounted) {
        setState(() {
          _userBadges = badges;
          _loadingBadges = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading badges: $e');
      if (mounted) {
        setState(() {
          _loadingBadges = false;
        });
      }
    }
  }

  Future<void> _loadUserLevel() async {
    try {
      final levelDoc = await FirebaseFirestore.instance
          .collection('userLevels')
          .doc(widget.userId)
          .get();

      if (levelDoc.exists && mounted) {
        final data = levelDoc.data()!;
        setState(() {
          _level = data['level'] as int? ?? 1;
          _currentXP = data['currentXP'] as int? ?? 0;
          _totalXP = data['totalXP'] as int? ?? 0;
          _levelTitle = _getLevelTitle(_level);
          _loadingLevel = false;
        });
      } else if (mounted) {
        // Use defaults
        setState(() {
          _level = 1;
          _currentXP = 0;
          _totalXP = 0;
          _levelTitle = 'Newcomer';
          _loadingLevel = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading level: $e');
      if (mounted) {
        setState(() {
          _level = 1;
          _currentXP = 0;
          _totalXP = 0;
          _levelTitle = 'Newcomer';
          _loadingLevel = false;
        });
      }
    }
  }

  String _getLevelTitle(int level) {
    if (level >= 100) return 'Legend';
    if (level >= 75) return 'Master';
    if (level >= 50) return 'Expert';
    if (level >= 25) return 'Veteran';
    if (level >= 10) return 'Explorer';
    if (level >= 5) return 'Enthusiast';
    return 'Newcomer';
  }

  Future<void> _loadAchievements() async {
    try {
      final achievementsSnapshot = await FirebaseFirestore.instance
          .collection('userAchievements')
          .where('userId', isEqualTo: widget.userId)
          .where('isUnlocked', isEqualTo: true)
          .get();

      final challengesSnapshot = await FirebaseFirestore.instance
          .collection('userChallenges')
          .where('userId', isEqualTo: widget.userId)
          .where('isCompleted', isEqualTo: true)
          .get();

      if (mounted) {
        setState(() {
          _achievementCount = achievementsSnapshot.docs.length;
          _completedChallenges = challengesSnapshot.docs.length;
          _loadingAchievements = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      if (mounted) {
        setState(() {
          _loadingAchievements = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Progress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => SafeNavigation.pop(context, userId: widget.userId),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadingBadges = true;
            _loadingLevel = true;
            _loadingAchievements = true;
          });
          await _loadAllData();
        },
        color: AppColors.richGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level & XP Card
              _buildLevelCard(),
              const SizedBox(height: 20),

              // Quick Stats Row
              _buildQuickStatsRow(),
              const SizedBox(height: 24),

              // My Badges Section
              _buildSectionHeader('My Badges', Icons.military_tech),
              const SizedBox(height: 12),
              _buildBadgesGrid(),
              const SizedBox(height: 24),

              // All Achievements Section
              _buildSectionHeader('Achievements', Icons.emoji_events),
              const SizedBox(height: 12),
              _buildAchievementsList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    if (_loadingLevel) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.richGold.withValues(alpha: 0.2),
              AppColors.richGold.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.richGold),
        ),
      );
    }

    final xpForNextLevel = LevelSystem.xpRequiredForLevel(_level + 1);
    final progress = xpForNextLevel > 0 ? (_currentXP / xpForNextLevel).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0.3),
            AppColors.richGold.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level Badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.richGold,
                      AppColors.richGold.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'LVL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Level Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _levelTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_currentXP / $xpForNextLevel XP',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // XP Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toInt()}% to Level ${_level + 1}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events,
            iconColor: Colors.amber,
            value: _loadingAchievements ? '-' : '$_achievementCount',
            label: 'Achievements',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.military_tech,
            iconColor: Colors.purple,
            value: _loadingBadges ? '-' : '${_userBadges.length}',
            label: 'Badges',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            value: _loadingAchievements ? '-' : '$_completedChallenges',
            label: 'Challenges',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.richGold, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesGrid() {
    if (_loadingBadges) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.richGold),
        ),
      );
    }

    if (_userBadges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(
              Icons.military_tech_outlined,
              size: 48,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No badges earned yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Complete achievements to earn badges!',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _userBadges.length,
        itemBuilder: (context, index) {
          final badgeWithDetails = _userBadges[index];
          return _buildBadgeItem(badgeWithDetails);
        },
      ),
    );
  }

  Widget _buildBadgeItem(UserBadgeWithDetails badgeWithDetails) {
    final badge = badgeWithDetails.badge;

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _getBadgeColors(badge.rarity),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getBadgeColors(badge.rarity).first.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              _getBadgeIcon(badge.category),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Color> _getBadgeColors(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return [Colors.grey, Colors.grey.shade600];
      case BadgeRarity.uncommon:
        return [Colors.green, Colors.green.shade700];
      case BadgeRarity.rare:
        return [Colors.blue, Colors.blue.shade700];
      case BadgeRarity.epic:
        return [Colors.purple, Colors.purple.shade700];
      case BadgeRarity.legendary:
        return [AppColors.richGold, Colors.orange.shade700];
      case BadgeRarity.mythic:
        return [Colors.deepOrange, Colors.red.shade700];
    }
  }

  IconData _getBadgeIcon(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.level:
        return Icons.crop_square;
      case BadgeCategory.verified:
        return Icons.verified;
      case BadgeCategory.premium:
        return Icons.star;
      case BadgeCategory.achievement:
        return Icons.emoji_events;
      case BadgeCategory.special:
        return Icons.auto_awesome;
      case BadgeCategory.seasonal:
        return Icons.celebration;
    }
  }

  Widget _buildAchievementsList() {
    // Show predefined achievements with unlock status
    final allAchievements = Achievements.getAllAchievements();
    final displayedAchievements = allAchievements.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          ...displayedAchievements.map((achievement) => _buildAchievementItem(achievement)),
          if (allAchievements.length > 5) ...[
            const SizedBox(height: 12),
            Text(
              '+${allAchievements.length - 5} more achievements',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.divider,
            ),
            child: Icon(
              Icons.emoji_events,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '+${achievement.rewardAmount} ${achievement.rewardType}',
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
