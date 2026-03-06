import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/entities/entities.dart';
import '../bloc/language_learning_bloc.dart';
import '../widgets/widgets.dart';
import '../widgets/xp_hero_section.dart';
import '../widgets/your_languages_section.dart';
import '../widgets/compact_streak_strip.dart';

class LanguageLearningHomeScreen extends StatefulWidget {
  const LanguageLearningHomeScreen({super.key});

  @override
  State<LanguageLearningHomeScreen> createState() =>
      _LanguageLearningHomeScreenState();
}

class _LanguageLearningHomeScreenState
    extends State<LanguageLearningHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    context.read<LanguageLearningBloc>().add(const LoadLanguageLearningData());
    _loadUserPreferredLanguages();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _loadUserPreferredLanguages() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      final languages = profileState.profile.languages;
      if (languages.isNotEmpty) {
        context
            .read<LanguageLearningBloc>()
            .add(SetUserPreferredLanguages(languages));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient starfield particle background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, _) => CustomPaint(
                  painter: _LearningHomeParticlePainter(
                    progress: _particleController.value,
                  ),
                ),
              ),
            ),
            BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
          builder: (context, state) {
            if (state.status == LanguageLearningStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.richGold,
                ),
              );
            }

            final totalXp = state.allLanguageProgress.fold(
              0,
              (sum, p) => sum + p.totalXpEarned,
            );

            return CustomScrollView(
              slivers: [
                // Compact App Bar with leaderboard + achievements icons
                SliverAppBar(
                  expandedHeight: 60,
                  floating: true,
                  pinned: true,
                  backgroundColor: const Color(0xFF0A0A0A),
                  title: Text(
                    l10n.greengoLearn,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.leaderboard,
                          color: AppColors.richGold),
                      onPressed: () => _navigateToLeaderboard(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_events,
                          color: AppColors.richGold),
                      onPressed: () => _navigateToAchievements(context),
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. XP Hero Section (animated)
                      XpHeroSection(
                        totalXp: totalXp,
                        languagesLearning: state.totalLanguagesLearning,
                      ),
                      const SizedBox(height: 16),

                      // 2. Compact Streak Strip
                      CompactStreakStrip(streak: state.learningStreak),
                      const SizedBox(height: 20),

                      // 3. Daily Hint Card (if available)
                      if (state.dailyHint != null) ...[
                        DailyHintCard(
                          hint: state.dailyHint!,
                          onViewed: () => context
                              .read<LanguageLearningBloc>()
                              .add(MarkHintAsViewed(state.dailyHint!.id)),
                          onLearned: () => context
                              .read<LanguageLearningBloc>()
                              .add(MarkHintAsLearned(state.dailyHint!.id)),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 4. "Your Languages" — horizontal scroll
                      _buildSectionHeader(
                          l10n.yourLanguages, Icons.school),
                      const SizedBox(height: 12),
                      YourLanguagesSection(
                        languageProgress: state.allLanguageProgress,
                        onLanguageTap: (code) =>
                            _navigateToLearningPath(context, code),
                      ),
                      const SizedBox(height: 20),

                      // 5. "Explore Languages" — full grid (all languages, 4 cols)
                      _buildSectionHeader(
                          l10n.exploreLanguages, Icons.language),
                      const SizedBox(height: 12),
                      _buildLanguageGrid(state.supportedLanguages),
                      const SizedBox(height: 20),

                      // 6. Daily Challenges (compact, 3 cards)
                      if (state.dailyChallenges.isNotEmpty) ...[
                        _buildSectionHeader(
                            l10n.dailyChallengesTitle, Icons.task_alt),
                        const SizedBox(height: 12),
                        ...state.dailyChallenges.take(3).map(
                              (challenge) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: LanguageChallengeCard(
                                    challenge: challenge),
                              ),
                            ),
                        if (state.dailyChallenges.length > 3)
                          _buildShowMoreButton(
                            l10n.viewAllChallenges,
                            () => _navigateToChallenges(context),
                          ),
                        const SizedBox(height: 20),
                      ],

                      // 7. "Language Packs" button → shop with shimmer
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          final shimmerPos = _shimmerController.value * 2 - 0.5;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _navigateToShop(context);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.richGold.withValues(
                                            alpha: 0.4 + 0.2 * _glowAnimation.value),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.richGold.withValues(
                                              alpha: 0.06 * _glowAnimation.value),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.shopping_bag,
                                            color: AppColors.richGold, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            l10n.languagePacksBtn,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios,
                                            color: AppColors.richGold, size: 18),
                                      ],
                                    ),
                                  ),
                                  // Shimmer sweep
                                  Positioned.fill(
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        begin: Alignment(shimmerPos - 0.3, -1),
                                        end: Alignment(shimmerPos + 0.3, 1),
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withValues(alpha: 0.04),
                                          Colors.transparent,
                                        ],
                                      ).createShader(bounds),
                                      blendMode: BlendMode.srcIn,
                                      child: Container(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) => Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.15 * _glowAnimation.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.richGold, size: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageGrid(List<SupportedLanguage> languages) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: languages.length,
      itemBuilder: (context, index) {
        final language = languages[index];
        return AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            // Stagger the glow across grid items
            final stagger = (index * 0.15) % 1.0;
            final glowVal = ((_glowAnimation.value + stagger) % 1.0);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _navigateToLearningPath(context, language.code);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.2 + 0.15 * glowVal),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.04 + 0.04 * glowVal),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      language.flag,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      language.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShowMoreButton(String text, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: AppColors.richGold,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward,
            color: AppColors.richGold,
            size: 16,
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToLeaderboard(BuildContext context) {
    Navigator.pushNamed(context, '/language-learning/leaderboard');
  }

  void _navigateToAchievements(BuildContext context) {
    Navigator.pushNamed(context, '/language-learning/achievements');
  }

  void _navigateToChallenges(BuildContext context) {
    Navigator.pushNamed(context, '/language-learning/challenges');
  }

  void _navigateToLearningPath(BuildContext context, String languageCode) {
    context.read<LanguageLearningBloc>().add(SelectLanguage(languageCode));
    Navigator.pushNamed(
      context,
      '/language-learning/learning-path',
      arguments: {'languageCode': languageCode},
    );
  }

  void _navigateToShop(BuildContext context) {
    Navigator.pushNamed(context, '/language-learning/shop');
  }
}

/// Subtle starfield particle painter for the learning home background
class _LearningHomeParticlePainter extends CustomPainter {
  final double progress;

  _LearningHomeParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 30;
    const seed = 99;

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 41) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 321) % 1000) / 1000.0 * size.height;
      final speed = 0.2 + (hash % 100) / 100.0 * 0.5;
      final phase = (hash % 628) / 100.0;
      final radius = 0.8 + (hash % 150) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 8;
      final dy = math.cos(progress * math.pi * 2 * speed * 0.5 + phase) * 6;
      final twinkle = (0.03 + 0.04 * math.sin(progress * math.pi * 2 * speed * 1.5 + phase))
          .clamp(0.0, 1.0);

      // Mix of gold and white stars
      final color = i % 3 == 0
          ? AppColors.richGold.withValues(alpha: twinkle)
          : Colors.white.withValues(alpha: twinkle * 0.7);

      canvas.drawCircle(
        Offset(baseX + dx, baseY + dy),
        radius,
        Paint()..color = color,
      );

      // Subtle glow on every 5th star
      if (i % 5 == 0) {
        canvas.drawCircle(
          Offset(baseX + dx, baseY + dy),
          radius * 3,
          Paint()..color = AppColors.richGold.withValues(alpha: twinkle * 0.2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LearningHomeParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
