import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/entities/entities.dart';
import '../bloc/language_learning_bloc.dart';
import '../widgets/widgets.dart';

class LanguageLearningHomeScreen extends StatefulWidget {
  const LanguageLearningHomeScreen({super.key});

  @override
  State<LanguageLearningHomeScreen> createState() =>
      _LanguageLearningHomeScreenState();
}

class _LanguageLearningHomeScreenState
    extends State<LanguageLearningHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LanguageLearningBloc>().add(const LoadLanguageLearningData());
    _loadUserPreferredLanguages();
  }

  void _loadUserPreferredLanguages() {
    // Try to get user's preferred languages from profile
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
          builder: (context, state) {
            if (state.status == LanguageLearningStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD4AF37),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF0A0A0A),
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Learn Languages',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A1A2E),
                            Color(0xFF0A0A0A),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.leaderboard, color: Color(0xFFD4AF37)),
                      onPressed: () => _navigateToLeaderboard(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_events, color: Color(0xFFD4AF37)),
                      onPressed: () => _navigateToAchievements(context),
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Stats Overview
                      _buildStatsOverview(state),
                      const SizedBox(height: 20),

                      // Daily Hint Card
                      if (state.dailyHint != null)
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

                      // Learning Streak
                      if (state.learningStreak != null)
                        LearningStreakCard(streak: state.learningStreak!),
                      const SizedBox(height: 20),

                      // Quick Actions
                      _buildQuickActions(context),
                      const SizedBox(height: 20),

                      // Daily Challenges Section
                      _buildSectionHeader('Daily Challenges', Icons.task_alt),
                      const SizedBox(height: 12),
                      ...state.dailyChallenges.take(3).map(
                            (challenge) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: LanguageChallengeCard(challenge: challenge),
                            ),
                          ),
                      if (state.dailyChallenges.length > 3)
                        _buildShowMoreButton(
                          'View All Challenges',
                          () => _navigateToChallenges(context),
                        ),
                      const SizedBox(height: 20),

                      // Languages Section
                      _buildSectionHeader('Choose a Language', Icons.language),
                      const SizedBox(height: 12),
                      _buildLanguageGrid(state.supportedLanguages),
                      const SizedBox(height: 20),

                      // Seasonal Events
                      if (state.seasonalEvents.isNotEmpty) ...[
                        _buildSectionHeader('Special Events', Icons.celebration),
                        const SizedBox(height: 12),
                        ...state.seasonalEvents.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SeasonalEventBanner(event: event),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Language Packs Shop
                      _buildSectionHeader('Language Packs', Icons.shopping_bag),
                      const SizedBox(height: 12),
                      _buildLanguagePacksPreview(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsOverview(LanguageLearningState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${state.totalWordsLearned}',
            'Words Learned',
            Icons.menu_book,
          ),
          _buildStatItem(
            '${state.totalLanguagesLearning}',
            'Languages',
            Icons.language,
          ),
          _buildStatItem(
            '${state.learningStreak?.currentStreak ?? 0}',
            'Day Streak',
            Icons.local_fire_department,
          ),
          _buildStatItem(
            '${state.unlockedAchievementsCount}',
            'Badges',
            Icons.emoji_events,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 24),
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
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            'Flashcards',
            Icons.style,
            const Color(0xFF4CAF50),
            () => _navigateToFlashcards(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            'Quizzes',
            Icons.quiz,
            const Color(0xFF2196F3),
            () => _navigateToQuizzes(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            'AI Coach',
            Icons.smart_toy,
            const Color(0xFF9C27B0),
            () => _navigateToAiCoach(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
      itemCount: languages.take(8).length,
      itemBuilder: (context, index) {
        final language = languages[index];
        return GestureDetector(
          onTap: () => _navigateToLanguageDetail(context, language.code),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
              ),
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
  }

  Widget _buildLanguagePacksPreview() {
    final packs = LanguagePack.availablePacks.take(3).toList();

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: packs.length + 1,
        itemBuilder: (context, index) {
          if (index == packs.length) {
            return _buildShowMorePackCard(context);
          }

          final pack = packs[index];
          return Container(
            width: 140,
            margin: EdgeInsets.only(right: index == packs.length ? 0 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pack.tier == PackTier.premium
                    ? const Color(0xFFD4AF37)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pack.iconEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const Spacer(),
                      if (pack.tier == PackTier.premium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pack.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFD4AF37),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pack.coinPrice}',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShowMorePackCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToShop(context),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_forward,
              color: Color(0xFFD4AF37),
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'View All',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward,
            color: Color(0xFFD4AF37),
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

  void _navigateToFlashcards(BuildContext context) {
    Navigator.pushNamed(context, '/language-learning/flashcards');
  }

  void _navigateToQuizzes(BuildContext context) {
    Navigator.pushNamed(context, '/language-learning/quizzes');
  }

  void _navigateToAiCoach(BuildContext context) {
    Navigator.pushNamed(context, '/language-learning/ai-coach');
  }

  void _navigateToChallenges(BuildContext context) {
    Navigator.pushNamed(context, '/language-learning/challenges');
  }

  void _navigateToLanguageDetail(BuildContext context, String languageCode) {
    context.read<LanguageLearningBloc>().add(SelectLanguage(languageCode));
    Navigator.pushNamed(
      context,
      '/language-learning/language-detail',
      arguments: languageCode,
    );
  }

  void _navigateToShop(BuildContext context) {
    Navigator.pushNamed(context, '/language-learning/shop');
  }
}
