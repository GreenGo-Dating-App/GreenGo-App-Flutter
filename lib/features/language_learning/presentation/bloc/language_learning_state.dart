part of 'language_learning_bloc.dart';

enum LanguageLearningStatus {
  initial,
  loading,
  loaded,
  error,
}

class LanguageLearningState extends Equatable {
  final LanguageLearningStatus status;
  final String? errorMessage;

  // Daily Hint
  final DailyHint? dailyHint;
  final bool isDailyHintLoading;

  // Phrases
  final List<LanguagePhrase> phrases;
  final List<LanguagePhrase> favoritePhrases;
  final bool isPhrasesLoading;

  // Language Progress
  final LanguageProgress? currentLanguageProgress;
  final List<LanguageProgress> allLanguageProgress;
  final bool isProgressLoading;

  // Learning Streak
  final LearningStreak? learningStreak;
  final bool isStreakLoading;

  // Supported Languages
  final List<SupportedLanguage> supportedLanguages;
  final String? selectedLanguageCode;

  // Challenges
  final List<LanguageChallenge> dailyChallenges;
  final List<LanguageChallenge> weeklyChallenges;
  final bool isChallengesLoading;

  // Quizzes
  final List<CulturalQuiz> availableQuizzes;
  final CulturalQuiz? currentQuiz;
  final int currentQuestionIndex;
  final List<QuestionResult> quizAnswers;
  final QuizResult? lastQuizResult;
  final bool isQuizLoading;

  // Flashcards
  final List<FlashcardDeck> flashcardDecks;
  final List<Flashcard> dueFlashcards;
  final int currentFlashcardIndex;
  final bool isFlashcardsLoading;

  // Achievements
  final List<LanguageAchievement> achievements;
  final bool isAchievementsLoading;

  // Language Packs
  final List<LanguagePack> languagePacks;
  final bool isPacksLoading;

  // Leaderboard
  final LanguageLeaderboard? leaderboard;
  final bool isLeaderboardLoading;

  // Icebreakers
  final List<Icebreaker> icebreakers;
  final Icebreaker? suggestedIcebreaker;
  final bool isIcebreakersLoading;

  // AI Coach
  final AiCoachSession? currentCoachSession;
  final bool isCoachLoading;

  // Seasonal Events
  final List<SeasonalLanguageEvent> seasonalEvents;
  final bool isSeasonalLoading;

  // Translation Count
  final int translationCount;

  // Lessons
  final List<Lesson> lessons;
  final List<Lesson> purchasedLessons;
  final Set<String> purchasedLessonIds;
  final bool isLessonsLoading;
  final String? lessonsError;

  // User Preferred Languages (from profile)
  final List<String> userPreferredLanguages;

  const LanguageLearningState({
    this.status = LanguageLearningStatus.initial,
    this.errorMessage,
    this.dailyHint,
    this.isDailyHintLoading = false,
    this.phrases = const [],
    this.favoritePhrases = const [],
    this.isPhrasesLoading = false,
    this.currentLanguageProgress,
    this.allLanguageProgress = const [],
    this.isProgressLoading = false,
    this.learningStreak,
    this.isStreakLoading = false,
    this.supportedLanguages = const [],
    this.selectedLanguageCode,
    this.dailyChallenges = const [],
    this.weeklyChallenges = const [],
    this.isChallengesLoading = false,
    this.availableQuizzes = const [],
    this.currentQuiz,
    this.currentQuestionIndex = 0,
    this.quizAnswers = const [],
    this.lastQuizResult,
    this.isQuizLoading = false,
    this.flashcardDecks = const [],
    this.dueFlashcards = const [],
    this.currentFlashcardIndex = 0,
    this.isFlashcardsLoading = false,
    this.achievements = const [],
    this.isAchievementsLoading = false,
    this.languagePacks = const [],
    this.isPacksLoading = false,
    this.leaderboard,
    this.isLeaderboardLoading = false,
    this.icebreakers = const [],
    this.suggestedIcebreaker,
    this.isIcebreakersLoading = false,
    this.currentCoachSession,
    this.isCoachLoading = false,
    this.seasonalEvents = const [],
    this.isSeasonalLoading = false,
    this.translationCount = 0,
    this.lessons = const [],
    this.purchasedLessons = const [],
    this.purchasedLessonIds = const {},
    this.isLessonsLoading = false,
    this.lessonsError,
    this.userPreferredLanguages = const [],
  });

  LanguageLearningState copyWith({
    LanguageLearningStatus? status,
    String? errorMessage,
    DailyHint? dailyHint,
    bool? isDailyHintLoading,
    List<LanguagePhrase>? phrases,
    List<LanguagePhrase>? favoritePhrases,
    bool? isPhrasesLoading,
    LanguageProgress? currentLanguageProgress,
    List<LanguageProgress>? allLanguageProgress,
    bool? isProgressLoading,
    LearningStreak? learningStreak,
    bool? isStreakLoading,
    List<SupportedLanguage>? supportedLanguages,
    String? selectedLanguageCode,
    List<LanguageChallenge>? dailyChallenges,
    List<LanguageChallenge>? weeklyChallenges,
    bool? isChallengesLoading,
    List<CulturalQuiz>? availableQuizzes,
    CulturalQuiz? currentQuiz,
    int? currentQuestionIndex,
    List<QuestionResult>? quizAnswers,
    QuizResult? lastQuizResult,
    bool? isQuizLoading,
    List<FlashcardDeck>? flashcardDecks,
    List<Flashcard>? dueFlashcards,
    int? currentFlashcardIndex,
    bool? isFlashcardsLoading,
    List<LanguageAchievement>? achievements,
    bool? isAchievementsLoading,
    List<LanguagePack>? languagePacks,
    bool? isPacksLoading,
    LanguageLeaderboard? leaderboard,
    bool? isLeaderboardLoading,
    List<Icebreaker>? icebreakers,
    Icebreaker? suggestedIcebreaker,
    bool? isIcebreakersLoading,
    AiCoachSession? currentCoachSession,
    bool? isCoachLoading,
    List<SeasonalLanguageEvent>? seasonalEvents,
    bool? isSeasonalLoading,
    int? translationCount,
    List<Lesson>? lessons,
    List<Lesson>? purchasedLessons,
    Set<String>? purchasedLessonIds,
    bool? isLessonsLoading,
    String? lessonsError,
    List<String>? userPreferredLanguages,
  }) {
    return LanguageLearningState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      dailyHint: dailyHint ?? this.dailyHint,
      isDailyHintLoading: isDailyHintLoading ?? this.isDailyHintLoading,
      phrases: phrases ?? this.phrases,
      favoritePhrases: favoritePhrases ?? this.favoritePhrases,
      isPhrasesLoading: isPhrasesLoading ?? this.isPhrasesLoading,
      currentLanguageProgress:
          currentLanguageProgress ?? this.currentLanguageProgress,
      allLanguageProgress: allLanguageProgress ?? this.allLanguageProgress,
      isProgressLoading: isProgressLoading ?? this.isProgressLoading,
      learningStreak: learningStreak ?? this.learningStreak,
      isStreakLoading: isStreakLoading ?? this.isStreakLoading,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      selectedLanguageCode: selectedLanguageCode ?? this.selectedLanguageCode,
      dailyChallenges: dailyChallenges ?? this.dailyChallenges,
      weeklyChallenges: weeklyChallenges ?? this.weeklyChallenges,
      isChallengesLoading: isChallengesLoading ?? this.isChallengesLoading,
      availableQuizzes: availableQuizzes ?? this.availableQuizzes,
      currentQuiz: currentQuiz ?? this.currentQuiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      quizAnswers: quizAnswers ?? this.quizAnswers,
      lastQuizResult: lastQuizResult ?? this.lastQuizResult,
      isQuizLoading: isQuizLoading ?? this.isQuizLoading,
      flashcardDecks: flashcardDecks ?? this.flashcardDecks,
      dueFlashcards: dueFlashcards ?? this.dueFlashcards,
      currentFlashcardIndex:
          currentFlashcardIndex ?? this.currentFlashcardIndex,
      isFlashcardsLoading: isFlashcardsLoading ?? this.isFlashcardsLoading,
      achievements: achievements ?? this.achievements,
      isAchievementsLoading:
          isAchievementsLoading ?? this.isAchievementsLoading,
      languagePacks: languagePacks ?? this.languagePacks,
      isPacksLoading: isPacksLoading ?? this.isPacksLoading,
      leaderboard: leaderboard ?? this.leaderboard,
      isLeaderboardLoading: isLeaderboardLoading ?? this.isLeaderboardLoading,
      icebreakers: icebreakers ?? this.icebreakers,
      suggestedIcebreaker: suggestedIcebreaker ?? this.suggestedIcebreaker,
      isIcebreakersLoading: isIcebreakersLoading ?? this.isIcebreakersLoading,
      currentCoachSession: currentCoachSession ?? this.currentCoachSession,
      isCoachLoading: isCoachLoading ?? this.isCoachLoading,
      seasonalEvents: seasonalEvents ?? this.seasonalEvents,
      isSeasonalLoading: isSeasonalLoading ?? this.isSeasonalLoading,
      translationCount: translationCount ?? this.translationCount,
      lessons: lessons ?? this.lessons,
      purchasedLessons: purchasedLessons ?? this.purchasedLessons,
      purchasedLessonIds: purchasedLessonIds ?? this.purchasedLessonIds,
      isLessonsLoading: isLessonsLoading ?? this.isLessonsLoading,
      lessonsError: lessonsError ?? this.lessonsError,
      userPreferredLanguages:
          userPreferredLanguages ?? this.userPreferredLanguages,
    );
  }

  // Helper getters
  int get totalWordsLearned =>
      allLanguageProgress.fold(0, (sum, p) => sum + p.wordsLearned);

  int get totalLanguagesLearning => allLanguageProgress.length;

  int get unlockedAchievementsCount =>
      achievements.where((a) => a.isUnlocked).length;

  SupportedLanguage? get selectedLanguage => selectedLanguageCode != null
      ? SupportedLanguage.getByCode(selectedLanguageCode!)
      : null;

  bool get hasActiveStreak =>
      learningStreak != null && learningStreak!.currentStreak > 0;

  bool get hasDailyHintAvailable =>
      dailyHint != null && !dailyHint!.isLearned;

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        dailyHint,
        isDailyHintLoading,
        phrases,
        favoritePhrases,
        isPhrasesLoading,
        currentLanguageProgress,
        allLanguageProgress,
        isProgressLoading,
        learningStreak,
        isStreakLoading,
        supportedLanguages,
        selectedLanguageCode,
        dailyChallenges,
        weeklyChallenges,
        isChallengesLoading,
        availableQuizzes,
        currentQuiz,
        currentQuestionIndex,
        quizAnswers,
        lastQuizResult,
        isQuizLoading,
        flashcardDecks,
        dueFlashcards,
        currentFlashcardIndex,
        isFlashcardsLoading,
        achievements,
        isAchievementsLoading,
        languagePacks,
        isPacksLoading,
        leaderboard,
        isLeaderboardLoading,
        icebreakers,
        suggestedIcebreaker,
        isIcebreakersLoading,
        currentCoachSession,
        isCoachLoading,
        seasonalEvents,
        isSeasonalLoading,
        translationCount,
        lessons,
        purchasedLessons,
        purchasedLessonIds,
        isLessonsLoading,
        lessonsError,
        userPreferredLanguages,
      ];
}
