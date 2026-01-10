import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import '../bloc/language_learning_bloc.dart';
import '../widgets/widgets.dart';
import 'lesson_detail_screen.dart';

class LanguageDetailScreen extends StatefulWidget {
  final String languageCode;

  const LanguageDetailScreen({
    super.key,
    required this.languageCode,
  });

  @override
  State<LanguageDetailScreen> createState() => _LanguageDetailScreenState();
}

class _LanguageDetailScreenState extends State<LanguageDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Load data for this language
    context.read<LanguageLearningBloc>().add(SelectLanguage(widget.languageCode));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
      builder: (context, state) {
        final language = SupportedLanguage.getByCode(widget.languageCode);

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            title: Row(
              children: [
                Text(
                  language?.flag ?? '',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  language?.name ?? widget.languageCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFD4AF37),
              labelColor: const Color(0xFFD4AF37),
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              isScrollable: true,
              tabs: const [
                Tab(text: 'Lessons'),
                Tab(text: 'Phrases'),
                Tab(text: 'Flashcards'),
                Tab(text: 'Quizzes'),
                Tab(text: 'Progress'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildLessonsTab(state),
              _buildPhrasesTab(state),
              _buildFlashcardsTab(state),
              _buildQuizzesTab(state),
              _buildProgressTab(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLessonsTab(LanguageLearningState state) {
    if (state.isLessonsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    // Filter lessons for this language
    final languageLessons = state.lessons
        .where((l) => l.languageCode == widget.languageCode)
        .toList();

    if (languageLessons.isEmpty) {
      return _buildEmptyState(
        'No lessons available yet',
        'Check back soon for new content!',
        Icons.school,
      );
    }

    // Group lessons by week
    final lessonsByWeek = <int, List<Lesson>>{};
    for (final lesson in languageLessons) {
      lessonsByWeek.putIfAbsent(lesson.weekNumber, () => []).add(lesson);
    }

    // Sort weeks
    final sortedWeeks = lessonsByWeek.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedWeeks.length,
      itemBuilder: (context, index) {
        final weekNumber = sortedWeeks[index];
        final weekLessons = lessonsByWeek[weekNumber]!
          ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Week $weekNumber',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${weekLessons.length} lessons',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Week lessons
            ...weekLessons.map((lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LessonCard(
                    lesson: lesson,
                    isPurchased: state.purchasedLessonIds.contains(lesson.id),
                    onTap: () => _openLesson(lesson),
                    onPurchase: () => _purchaseLesson(lesson),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildPhrasesTab(LanguageLearningState state) {
    if (state.isPhrasesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    if (state.phrases.isEmpty) {
      return _buildEmptyState(
        'No phrases available yet',
        'Check back soon for new content!',
        Icons.menu_book,
      );
    }

    // Group phrases by category
    final phrasesByCategory = <PhraseCategory, List<LanguagePhrase>>{};
    for (final phrase in state.phrases) {
      phrasesByCategory.putIfAbsent(phrase.category, () => []).add(phrase);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: phrasesByCategory.length,
      itemBuilder: (context, index) {
        final category = phrasesByCategory.keys.elementAt(index);
        final phrases = phrasesByCategory[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${phrases.length} phrases',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...phrases.map((phrase) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PhraseCard(
                    phrase: phrase,
                    onLearn: () => context
                        .read<LanguageLearningBloc>()
                        .add(MarkPhraseAsLearned(phrase.id)),
                    onFavorite: (isFavorite) => context
                        .read<LanguageLearningBloc>()
                        .add(TogglePhrasesFavorite(phrase.id, isFavorite)),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildFlashcardsTab(LanguageLearningState state) {
    if (state.isFlashcardsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    final languageDecks = state.flashcardDecks
        .where((d) => d.languageCode == widget.languageCode)
        .toList();

    if (languageDecks.isEmpty) {
      return _buildEmptyState(
        'No flashcard decks available',
        'Purchase decks from the shop!',
        Icons.style,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: languageDecks.length,
      itemBuilder: (context, index) {
        final deck = languageDecks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FlashcardDeckCard(
            deck: deck,
            onStart: () => _startFlashcardSession(deck.id),
            onPurchase: () => context
                .read<LanguageLearningBloc>()
                .add(PurchaseFlashcardDeck(deck.id)),
          ),
        );
      },
    );
  }

  Widget _buildQuizzesTab(LanguageLearningState state) {
    if (state.isQuizLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    final languageQuizzes = state.availableQuizzes
        .where((q) => q.languageCode == widget.languageCode)
        .toList();

    if (languageQuizzes.isEmpty) {
      return _buildEmptyState(
        'No quizzes available',
        'Check back soon for cultural quizzes!',
        Icons.quiz,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: languageQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = languageQuizzes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CulturalQuizCard(
            quiz: quiz,
            onStart: () => _startQuiz(quiz.id),
          ),
        );
      },
    );
  }

  Widget _buildProgressTab(LanguageLearningState state) {
    final progress = state.currentLanguageProgress;

    if (progress == null) {
      return _buildEmptyState(
        'No progress yet',
        'Start learning to track your progress!',
        Icons.trending_up,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proficiency Badge
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF2D2D44),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 3,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    progress.proficiency.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress.proficiency.displayName,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress Stats
          _buildProgressCard('Words Learned', '${progress.wordsLearned}', Icons.menu_book),
          _buildProgressCard('Phrases Mastered', '${progress.phrasesLearned}', Icons.check_circle),
          _buildProgressCard('Total XP', '${progress.totalXpEarned}', Icons.star),
          _buildProgressCard('Translations', '${progress.translationsCount}', Icons.translate),
          _buildProgressCard('Quizzes Taken', '${progress.quizzesTaken}', Icons.quiz),
          _buildProgressCard('Perfect Quizzes', '${progress.quizzesPerfect}', Icons.emoji_events),

          const SizedBox(height: 24),

          // Next Level Progress
          _buildNextLevelProgress(progress),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 24),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextLevelProgress(LanguageProgress progress) {
    final currentProficiency = progress.proficiency;
    final nextProficiency = currentProficiency.index < LanguageProficiency.values.length - 1
        ? LanguageProficiency.values[currentProficiency.index + 1]
        : null;

    if (nextProficiency == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, color: Colors.black, size: 24),
            SizedBox(width: 8),
            Text(
              'You\'ve reached the highest level!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final requiredWords = nextProficiency.requiredWords;
    final progressPercent = progress.wordsLearned / requiredWords;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Next: ${nextProficiency.emoji} ${nextProficiency.displayName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${progress.wordsLearned}/$requiredWords words',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );
  }

  void _purchaseLesson(Lesson lesson) {
    context.read<LanguageLearningBloc>().add(PurchaseLessonEvent(lessonId: lesson.id));
  }

  void _startFlashcardSession(String deckId) {
    context.read<LanguageLearningBloc>().add(
          StartFlashcardSession(
            deckId: deckId,
            languageCode: widget.languageCode,
          ),
        );
    Navigator.pushNamed(context, '/language-learning/flashcard-session');
  }

  void _startQuiz(String quizId) {
    context.read<LanguageLearningBloc>().add(StartQuiz(quizId));
    Navigator.pushNamed(context, '/language-learning/quiz-session');
  }
}
