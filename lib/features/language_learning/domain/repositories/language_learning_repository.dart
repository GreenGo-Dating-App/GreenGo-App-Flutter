import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/entities.dart';

/// Repository interface for language learning features
abstract class LanguageLearningRepository {
  // ==================== Daily Hints ====================

  /// Get today's daily hint
  Future<Either<Failure, DailyHint>> getDailyHint();

  /// Mark daily hint as viewed
  Future<Either<Failure, void>> markHintAsViewed(String hintId);

  /// Mark daily hint as learned
  Future<Either<Failure, void>> markHintAsLearned(String hintId);

  // ==================== Phrases ====================

  /// Get all phrases for a language
  Future<Either<Failure, List<LanguagePhrase>>> getPhrasesForLanguage(
    String languageCode, {
    PhraseCategory? category,
    PhraseDifficulty? difficulty,
    int? limit,
    int? offset,
  });

  /// Get a specific phrase by ID
  Future<Either<Failure, LanguagePhrase>> getPhraseById(String phraseId);

  /// Mark a phrase as learned
  Future<Either<Failure, void>> markPhraseAsLearned(String phraseId);

  /// Add phrase to favorites
  Future<Either<Failure, void>> addPhraseToFavorites(String phraseId);

  /// Remove phrase from favorites
  Future<Either<Failure, void>> removePhraseFromFavorites(String phraseId);

  /// Get favorite phrases
  Future<Either<Failure, List<LanguagePhrase>>> getFavoritePhrases();

  // ==================== Language Progress ====================

  /// Get user's progress for a specific language
  Future<Either<Failure, LanguageProgress>> getLanguageProgress(String languageCode);

  /// Get user's progress for all languages
  Future<Either<Failure, List<LanguageProgress>>> getAllLanguageProgress();

  /// Update language progress
  Future<Either<Failure, void>> updateLanguageProgress(LanguageProgress progress);

  // ==================== Learning Streak ====================

  /// Get user's learning streak
  Future<Either<Failure, LearningStreak>> getLearningStreak();

  /// Update learning streak (call when user practices)
  Future<Either<Failure, LearningStreak>> updateLearningStreak();

  /// Claim streak milestone reward
  Future<Either<Failure, void>> claimStreakMilestone(int milestoneDay);

  // ==================== Supported Languages ====================

  /// Get all supported languages
  Future<Either<Failure, List<SupportedLanguage>>> getSupportedLanguages();

  /// Get language by code
  Future<Either<Failure, SupportedLanguage>> getLanguageByCode(String code);

  // ==================== Language Challenges ====================

  /// Get daily language challenges
  Future<Either<Failure, List<LanguageChallenge>>> getDailyChallenges();

  /// Get weekly language challenges
  Future<Either<Failure, List<LanguageChallenge>>> getWeeklyChallenges();

  /// Update challenge progress
  Future<Either<Failure, void>> updateChallengeProgress(
    String challengeId,
    int progress,
  );

  /// Claim challenge reward
  Future<Either<Failure, void>> claimChallengeReward(String challengeId);

  // ==================== Cultural Quizzes ====================

  /// Get available quizzes
  Future<Either<Failure, List<CulturalQuiz>>> getAvailableQuizzes({
    String? languageCode,
    QuizDifficulty? difficulty,
  });

  /// Get quiz by ID
  Future<Either<Failure, CulturalQuiz>> getQuizById(String quizId);

  /// Submit quiz result
  Future<Either<Failure, QuizResult>> submitQuizResult(QuizResult result);

  /// Get user's quiz history
  Future<Either<Failure, List<QuizResult>>> getQuizHistory();

  // ==================== Flashcards ====================

  /// Get flashcard decks
  Future<Either<Failure, List<FlashcardDeck>>> getFlashcardDecks({
    String? languageCode,
    bool? includePremium,
  });

  /// Get flashcard deck by ID
  Future<Either<Failure, FlashcardDeck>> getFlashcardDeckById(String deckId);

  /// Get due flashcards for review
  Future<Either<Failure, List<Flashcard>>> getDueFlashcards({
    String? languageCode,
    int? limit,
  });

  /// Update flashcard after review
  Future<Either<Failure, void>> updateFlashcardReview(
    String flashcardId,
    FlashcardAnswer answer,
  );

  /// Purchase flashcard deck
  Future<Either<Failure, void>> purchaseFlashcardDeck(String deckId);

  // ==================== Achievements ====================

  /// Get all language achievements
  Future<Either<Failure, List<LanguageAchievement>>> getLanguageAchievements();

  /// Get unlocked achievements
  Future<Either<Failure, List<LanguageAchievement>>> getUnlockedAchievements();

  /// Update achievement progress
  Future<Either<Failure, void>> updateAchievementProgress(
    String achievementId,
    int progress,
  );

  /// Claim achievement reward
  Future<Either<Failure, void>> claimAchievementReward(String achievementId);

  // ==================== Language Packs ====================

  /// Get available language packs
  Future<Either<Failure, List<LanguagePack>>> getLanguagePacks({
    String? languageCode,
    PhraseCategory? category,
  });

  /// Get purchased language packs
  Future<Either<Failure, List<LanguagePack>>> getPurchasedPacks();

  /// Purchase language pack
  Future<Either<Failure, void>> purchaseLanguagePack(String packId);

  // ==================== Leaderboard ====================

  /// Get language learning leaderboard
  Future<Either<Failure, LanguageLeaderboard>> getLeaderboard({
    LeaderboardType type = LeaderboardType.totalXp,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
  });

  /// Get user's leaderboard rank
  Future<Either<Failure, LeaderboardEntry>> getUserLeaderboardRank();

  // ==================== Icebreakers ====================

  /// Get icebreakers for a specific country
  Future<Either<Failure, List<Icebreaker>>> getIcebreakersForCountry(
    String countryCode,
  );

  /// Mark icebreaker as used
  Future<Either<Failure, void>> markIcebreakerAsUsed(String icebreakerId);

  /// Get random icebreaker for a match
  Future<Either<Failure, Icebreaker>> getRandomIcebreaker(String matchCountryCode);

  // ==================== AI Coach ====================

  /// Start AI coach session
  Future<Either<Failure, AiCoachSession>> startCoachSession({
    required String languageCode,
    required CoachScenario scenario,
  });

  /// Send message to AI coach
  Future<Either<Failure, CoachMessage>> sendCoachMessage(
    String sessionId,
    String message,
  );

  /// End AI coach session
  Future<Either<Failure, AiCoachSession>> endCoachSession(String sessionId);

  /// Get AI coach session history
  Future<Either<Failure, List<AiCoachSession>>> getCoachSessionHistory();

  // ==================== Seasonal Events ====================

  /// Get active seasonal events
  Future<Either<Failure, List<SeasonalLanguageEvent>>> getActiveSeasonalEvents();

  /// Get seasonal event by ID
  Future<Either<Failure, SeasonalLanguageEvent>> getSeasonalEventById(String eventId);

  /// Update seasonal challenge progress
  Future<Either<Failure, void>> updateSeasonalChallengeProgress(
    String eventId,
    String challengeId,
    int progress,
  );

  /// Claim seasonal challenge reward
  Future<Either<Failure, void>> claimSeasonalChallengeReward(
    String eventId,
    String challengeId,
  );

  // ==================== Translation Tracking ====================

  /// Track a translation (for achievement tracking)
  Future<Either<Failure, void>> trackTranslation(String fromLanguage, String toLanguage);

  /// Get translation count
  Future<Either<Failure, int>> getTranslationCount();

  // ==================== Video Call Language Bonus ====================

  /// Track language use in video call
  Future<Either<Failure, void>> trackVideoCallLanguageUse(
    String languageCode,
    Duration duration,
  );

  // ==================== Lessons ====================

  /// Get available lessons for a language
  Future<Either<Failure, List<Lesson>>> getLessonsForLanguage(
    String languageCode, {
    LessonLevel? level,
    LessonCategory? category,
    int? limit,
    int? offset,
  });

  /// Get lesson by ID
  Future<Either<Failure, Lesson>> getLessonById(String lessonId);

  /// Purchase lesson with coins
  Future<Either<Failure, UserLessonAccess>> purchaseLesson(String lessonId);

  /// Get user's purchased lessons
  Future<Either<Failure, List<UserLessonAccess>>> getPurchasedLessons();

  /// Update lesson progress
  Future<Either<Failure, void>> updateLessonProgress(
    String lessonId,
    LessonSectionProgress progress,
  );

  /// Get lesson progress
  Future<Either<Failure, List<LessonSectionProgress>>> getLessonProgress(
    String lessonId,
  );

  /// Rate a lesson
  Future<Either<Failure, void>> rateLesson(
    String lessonId,
    int rating,
    String? review,
  );

  // ==================== Teachers ====================

  /// Submit teacher application
  Future<Either<Failure, TeacherApplication>> submitTeacherApplication(
    TeacherApplication application,
  );

  /// Get teacher profile
  Future<Either<Failure, Teacher>> getTeacherProfile(String teacherId);

  /// Get lessons by teacher
  Future<Either<Failure, List<Lesson>>> getLessonsByTeacher(String teacherId);

  /// Get teacher earnings (for teachers)
  Future<Either<Failure, List<TeacherEarning>>> getTeacherEarnings();

  /// Get teacher stats (for teachers)
  Future<Either<Failure, TeacherStats>> getTeacherStats();

  // ==================== User Learning Progress ====================

  /// Get user learning progress
  Future<Either<Failure, UserLearningProgress>> getUserLearningProgress(
    String languageCode,
  );

  /// Get all user progress across languages
  Future<Either<Failure, List<UserLearningProgress>>> getAllUserProgress();

  /// Set learning goals
  Future<Either<Failure, void>> setLearningGoal(LearningGoal goal);

  /// Get learning goals
  Future<Either<Failure, List<LearningGoal>>> getLearningGoals();

  /// Update goal progress
  Future<Either<Failure, void>> updateGoalProgress(
    String goalId,
    int progress,
  );
}
