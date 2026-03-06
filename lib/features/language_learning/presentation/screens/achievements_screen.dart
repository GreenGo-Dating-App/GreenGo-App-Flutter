import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/entities.dart';
import '../bloc/language_learning_bloc.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categories = LanguageAchievementCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    context.read<LanguageLearningBloc>().add(const LoadLanguageAchievements());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _categoryLabel(AppLocalizations l10n, LanguageAchievementCategory cat) {
    switch (cat) {
      case LanguageAchievementCategory.translation:
        return l10n.categoryTranslation;
      case LanguageAchievementCategory.learning:
        return l10n.categoryLearning;
      case LanguageAchievementCategory.multilingual:
        return l10n.categoryMultilingual;
      case LanguageAchievementCategory.quiz:
        return l10n.categoryQuiz;
      case LanguageAchievementCategory.streak:
        return l10n.categoryStreak;
      case LanguageAchievementCategory.flashcard:
        return l10n.categoryFlashcard;
      case LanguageAchievementCategory.social:
        return l10n.categorySocial;
      case LanguageAchievementCategory.seasonal:
        return l10n.categorySeasonal;
    }
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Text(
          l10n.achievementsTitle,
          style: const TextStyle(
            color: AppColors.richGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.richGold),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabAlignment: TabAlignment.start,
          tabs: _categories
              .map((cat) => Tab(text: _categoryLabel(l10n, cat)))
              .toList(),
        ),
      ),
      body: BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
        builder: (context, state) {
          if (state.isAchievementsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          final achievements = state.achievements;

          return TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final filtered = achievements
                  .where((a) => a.category == category)
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.grey,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _categoryLabel(l10n, category),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _AchievementBadgeCard(
                      achievement: filtered[index],
                      l10n: l10n,
                      parseHexColor: _parseHexColor,
                      onClaim: () {
                        context.read<LanguageLearningBloc>().add(
                              ClaimAchievementReward(filtered[index].id),
                            );
                      },
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _AchievementBadgeCard extends StatelessWidget {
  final LanguageAchievement achievement;
  final AppLocalizations l10n;
  final Color Function(String) parseHexColor;
  final VoidCallback onClaim;

  const _AchievementBadgeCard({
    required this.achievement,
    required this.l10n,
    required this.parseHexColor,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = parseHexColor(achievement.rarity.color);
    final isLocked = !achievement.isUnlocked;
    final isSecret = achievement.isSecret && isLocked;
    // Consider reward claimed if it was unlocked and has no coin/xp reward left
    // For now, we show the claim button if unlocked but unlockedAt is not null
    // and the achievement has rewards > 0. We treat "already claimed" as:
    // unlocked achievements that were loaded with coinReward == 0 after claiming.
    // Since the entity doesn't have a `rewardClaimed` field, we show claim
    // for all unlocked achievements with rewards > 0.
    final bool canClaim =
        achievement.isUnlocked && (achievement.coinReward > 0 || achievement.xpReward > 0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked ? rarityColor.withValues(alpha: 0.3) : rarityColor,
          width: isLocked ? 1 : 2,
        ),
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                // Icon or secret "?"
                if (isSecret)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: const Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    achievement.iconEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                const SizedBox(height: 8),
                // Name
                Text(
                  isSecret ? l10n.secretAchievement : achievement.name,
                  style: TextStyle(
                    color: isSecret ? Colors.grey : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                  isSecret ? '???' : achievement.description,
                  style: TextStyle(
                    color: isSecret ? Colors.grey[700] : Colors.grey[400],
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Progress bar or unlocked label
                if (achievement.isUnlocked)
                  Text(
                    l10n.badgeUnlocked,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (!isSecret)
                  _buildProgressBar(rarityColor),
                const SizedBox(height: 6),
                // Claim button
                if (canClaim)
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(l10n.claimRewardBtn),
                    ),
                  ),
              ],
            ),
          ),
          // Unlocked check overlay
          if (achievement.isUnlocked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          // Rarity label
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: rarityColor.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Text(
                achievement.rarity.displayName,
                style: TextStyle(
                  color: rarityColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color rarityColor) {
    final progress = achievement.progress.clamp(0.0, 1.0);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${achievement.currentProgress} / ${achievement.requiredProgress}',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
