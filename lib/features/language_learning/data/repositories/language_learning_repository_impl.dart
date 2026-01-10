import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/language_learning_repository.dart';
import '../datasources/language_learning_remote_data_source.dart';
import '../models/models.dart';

class LanguageLearningRepositoryImpl implements LanguageLearningRepository {
  final LanguageLearningRemoteDataSource remoteDataSource;

  LanguageLearningRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DailyHint>> getDailyHint() async {
    try {
      final result = await remoteDataSource.getDailyHint();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markHintAsViewed(String hintId) async {
    try {
      await remoteDataSource.markHintAsViewed(hintId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markHintAsLearned(String hintId) async {
    try {
      await remoteDataSource.markHintAsLearned(hintId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LanguagePhrase>>> getPhrasesForLanguage(
    String languageCode, {
    PhraseCategory? category,
    PhraseDifficulty? difficulty,
    int? limit,
    int? offset,
  }) async {
    try {
      final result = await remoteDataSource.getPhrasesForLanguage(
        languageCode,
        category: category,
        difficulty: difficulty,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, LanguagePhrase>> getPhraseById(String phraseId) async {
    try {
      final result = await remoteDataSource.getPhraseById(phraseId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markPhraseAsLearned(String phraseId) async {
    try {
      await remoteDataSource.markPhraseAsLearned(phraseId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPhraseToFavorites(String phraseId) async {
    try {
      await remoteDataSource.addPhraseToFavorites(phraseId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removePhraseFromFavorites(String phraseId) async {
    try {
      await remoteDataSource.removePhraseFromFavorites(phraseId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LanguagePhrase>>> getFavoritePhrases() async {
    try {
      final result = await remoteDataSource.getFavoritePhrases();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, LanguageProgress>> getLanguageProgress(
      String languageCode) async {
    try {
      final result = await remoteDataSource.getLanguageProgress(languageCode);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LanguageProgress>>> getAllLanguageProgress() async {
    try {
      final result = await remoteDataSource.getAllLanguageProgress();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLanguageProgress(
      LanguageProgress progress) async {
    try {
      await remoteDataSource
          .updateLanguageProgress(LanguageProgressModel.fromEntity(progress));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, LearningStreak>> getLearningStreak() async {
    try {
      final result = await remoteDataSource.getLearningStreak();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, LearningStreak>> updateLearningStreak() async {
    try {
      final result = await remoteDataSource.updateLearningStreak();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimStreakMilestone(int milestoneDay) async {
    try {
      await remoteDataSource.claimStreakMilestone(milestoneDay);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SupportedLanguage>>> getSupportedLanguages() async {
    try {
      return Right(SupportedLanguage.allLanguages);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupportedLanguage>> getLanguageByCode(
      String code) async {
    try {
      final language = SupportedLanguage.getByCode(code);
      if (language == null) {
        return Left(ServerFailure( 'Language not found'));
      }
      return Right(language);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LanguageChallenge>>> getDailyChallenges() async {
    try {
      return Right(LanguageChallenge.dailyChallenges);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LanguageChallenge>>> getWeeklyChallenges() async {
    try {
      return Right(LanguageChallenge.weeklyChallenges);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateChallengeProgress(
    String challengeId,
    int progress,
  ) async {
    try {
      // TODO: Implement challenge progress tracking in Firebase
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimChallengeReward(String challengeId) async {
    try {
      // TODO: Implement challenge reward claiming in Firebase
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CulturalQuiz>>> getAvailableQuizzes({
    String? languageCode,
    QuizDifficulty? difficulty,
  }) async {
    try {
      final result = await remoteDataSource.getAvailableQuizzes(
        languageCode: languageCode,
        difficulty: difficulty,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, CulturalQuiz>> getQuizById(String quizId) async {
    try {
      final result = await remoteDataSource.getQuizById(quizId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizResult>> submitQuizResult(QuizResult result) async {
    try {
      final submitted = await remoteDataSource
          .submitQuizResult(QuizResultModel.fromEntity(result));
      return Right(submitted);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizResult>>> getQuizHistory() async {
    try {
      final result = await remoteDataSource.getQuizHistory();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FlashcardDeck>>> getFlashcardDecks({
    String? languageCode,
    bool? includePremium,
  }) async {
    try {
      final result = await remoteDataSource.getFlashcardDecks(
        languageCode: languageCode,
        includePremium: includePremium,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, FlashcardDeck>> getFlashcardDeckById(
      String deckId) async {
    try {
      final result = await remoteDataSource.getFlashcardDeckById(deckId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getDueFlashcards({
    String? languageCode,
    int? limit,
  }) async {
    try {
      final result = await remoteDataSource.getDueFlashcards(
        languageCode: languageCode,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFlashcardReview(
    String flashcardId,
    FlashcardAnswer answer,
  ) async {
    try {
      await remoteDataSource.updateFlashcardReview(flashcardId, answer);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> purchaseFlashcardDeck(String deckId) async {
    try {
      await remoteDataSource.purchaseFlashcardDeck(deckId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LanguageAchievement>>>
      getLanguageAchievements() async {
    try {
      final result = await remoteDataSource.getLanguageAchievements();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LanguageAchievement>>>
      getUnlockedAchievements() async {
    try {
      final result = await remoteDataSource.getUnlockedAchievements();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAchievementProgress(
    String achievementId,
    int progress,
  ) async {
    try {
      await remoteDataSource.updateAchievementProgress(achievementId, progress);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimAchievementReward(
      String achievementId) async {
    try {
      await remoteDataSource.claimAchievementReward(achievementId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LanguagePack>>> getLanguagePacks({
    String? languageCode,
    PhraseCategory? category,
  }) async {
    try {
      var packs = LanguagePack.availablePacks;
      if (languageCode != null) {
        packs = packs.where((p) => p.languageCode == languageCode).toList();
      }
      if (category != null) {
        packs = packs.where((p) => p.category == category).toList();
      }
      return Right(packs);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LanguagePack>>> getPurchasedPacks() async {
    try {
      // TODO: Get from Firebase
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> purchaseLanguagePack(String packId) async {
    try {
      // TODO: Implement purchase logic
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, LanguageLeaderboard>> getLeaderboard({
    LeaderboardType type = LeaderboardType.totalXp,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
  }) async {
    try {
      // TODO: Implement leaderboard from Firebase
      return Right(LanguageLeaderboard(
        type: type,
        period: period,
        entries: const [],
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeaderboardEntry>> getUserLeaderboardRank() async {
    try {
      // TODO: Implement user rank lookup
      return const Left(ServerFailure( 'Not implemented'));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Icebreaker>>> getIcebreakersForCountry(
      String countryCode) async {
    try {
      final icebreakers = Icebreaker.getIcebreakersForCountry(countryCode);
      return Right(icebreakers);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markIcebreakerAsUsed(
      String icebreakerId) async {
    try {
      // TODO: Track icebreaker usage
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, Icebreaker>> getRandomIcebreaker(
      String matchCountryCode) async {
    try {
      final icebreakers = Icebreaker.getIcebreakersForCountry(matchCountryCode);
      if (icebreakers.isEmpty) {
        return const Left(ServerFailure( 'No icebreakers available'));
      }
      final random = icebreakers[DateTime.now().millisecond % icebreakers.length];
      return Right(random);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, AiCoachSession>> startCoachSession({
    required String languageCode,
    required CoachScenario scenario,
  }) async {
    try {
      // TODO: Implement AI coach session start
      final session = AiCoachSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        odUserId: '',
        targetLanguageCode: languageCode,
        targetLanguageName:
            SupportedLanguage.getByCode(languageCode)?.name ?? languageCode,
        scenario: scenario,
        startedAt: DateTime.now(),
      );
      return Right(session);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, CoachMessage>> sendCoachMessage(
    String sessionId,
    String message,
  ) async {
    try {
      // TODO: Implement AI coach message handling
      return Right(CoachMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'AI response would go here',
        isUserMessage: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, AiCoachSession>> endCoachSession(
      String sessionId) async {
    try {
      // TODO: Implement session ending
      return const Left(ServerFailure( 'Not implemented'));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AiCoachSession>>> getCoachSessionHistory() async {
    try {
      // TODO: Implement session history
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SeasonalLanguageEvent>>>
      getActiveSeasonalEvents() async {
    try {
      final now = DateTime.now();
      final events = SeasonalLanguageEvent.allEvents
          .where((e) => e.isCurrentlyActive)
          .toList();
      return Right(events);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, SeasonalLanguageEvent>> getSeasonalEventById(
      String eventId) async {
    try {
      final event = SeasonalLanguageEvent.allEvents.firstWhere(
        (e) => e.id == eventId,
      );
      return Right(event);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSeasonalChallengeProgress(
    String eventId,
    String challengeId,
    int progress,
  ) async {
    try {
      // TODO: Implement seasonal challenge progress
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimSeasonalChallengeReward(
    String eventId,
    String challengeId,
  ) async {
    try {
      // TODO: Implement seasonal reward claiming
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> trackTranslation(
    String fromLanguage,
    String toLanguage,
  ) async {
    try {
      await remoteDataSource.trackTranslation(fromLanguage, toLanguage);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getTranslationCount() async {
    try {
      final count = await remoteDataSource.getTranslationCount();
      return Right(count);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> trackVideoCallLanguageUse(
    String languageCode,
    Duration duration,
  ) async {
    try {
      // TODO: Implement video call language tracking
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  // ==================== Lessons ====================

  @override
  Future<Either<Failure, List<Lesson>>> getLessonsForLanguage(
    String languageCode, {
    LessonLevel? level,
    LessonCategory? category,
    int? limit,
    int? offset,
  }) async {
    try {
      final result = await remoteDataSource.getLessonsForLanguage(
        languageCode,
        level: level,
        category: category,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lesson>> getLessonById(String lessonId) async {
    try {
      final result = await remoteDataSource.getLessonById(lessonId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLessonAccess>> purchaseLesson(String lessonId) async {
    try {
      final result = await remoteDataSource.purchaseLesson(lessonId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserLessonAccess>>> getPurchasedLessons() async {
    try {
      final result = await remoteDataSource.getPurchasedLessons();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLessonProgress(
    String lessonId,
    LessonSectionProgress progress,
  ) async {
    try {
      await remoteDataSource.updateLessonProgress(lessonId, progress);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LessonSectionProgress>>> getLessonProgress(
    String lessonId,
  ) async {
    try {
      final result = await remoteDataSource.getLessonProgress(lessonId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rateLesson(
    String lessonId,
    int rating,
    String? review,
  ) async {
    try {
      await remoteDataSource.rateLesson(lessonId, rating, review);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ==================== Teachers ====================

  @override
  Future<Either<Failure, TeacherApplication>> submitTeacherApplication(
    TeacherApplication application,
  ) async {
    try {
      final result = await remoteDataSource.submitTeacherApplication(application);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Teacher>> getTeacherProfile(String teacherId) async {
    try {
      final result = await remoteDataSource.getTeacherProfile(teacherId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Lesson>>> getLessonsByTeacher(String teacherId) async {
    try {
      final result = await remoteDataSource.getLessonsByTeacher(teacherId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TeacherEarning>>> getTeacherEarnings() async {
    try {
      final result = await remoteDataSource.getTeacherEarnings();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TeacherStats>> getTeacherStats() async {
    try {
      final result = await remoteDataSource.getTeacherStats();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ==================== User Learning Progress ====================

  @override
  Future<Either<Failure, UserLearningProgress>> getUserLearningProgress(
    String languageCode,
  ) async {
    try {
      final result = await remoteDataSource.getUserLearningProgress(languageCode);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserLearningProgress>>> getAllUserProgress() async {
    try {
      final result = await remoteDataSource.getAllUserProgress();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setLearningGoal(LearningGoal goal) async {
    try {
      await remoteDataSource.setLearningGoal(goal);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LearningGoal>>> getLearningGoals() async {
    try {
      final result = await remoteDataSource.getLearningGoals();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGoalProgress(
    String goalId,
    int progress,
  ) async {
    try {
      await remoteDataSource.updateGoalProgress(goalId, progress);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
