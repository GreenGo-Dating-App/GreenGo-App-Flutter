import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/language_learning_repository.dart';

part 'language_learning_event.dart';
part 'language_learning_state.dart';

class LanguageLearningBloc
    extends Bloc<LanguageLearningEvent, LanguageLearningState> {
  final LanguageLearningRepository repository;

  LanguageLearningBloc({required this.repository})
      : super(const LanguageLearningState()) {
    // Initialization
    on<LoadLanguageLearningData>(_onLoadLanguageLearningData);

    // Daily Hint
    on<LoadDailyHint>(_onLoadDailyHint);
    on<MarkHintAsViewed>(_onMarkHintAsViewed);
    on<MarkHintAsLearned>(_onMarkHintAsLearned);

    // Phrases
    on<LoadPhrases>(_onLoadPhrases);
    on<MarkPhraseAsLearned>(_onMarkPhraseAsLearned);
    on<TogglePhrasesFavorite>(_onTogglePhrasesFavorite);
    on<LoadFavoritePhrases>(_onLoadFavoritePhrases);

    // Language Progress
    on<LoadLanguageProgress>(_onLoadLanguageProgress);
    on<LoadAllLanguageProgress>(_onLoadAllLanguageProgress);

    // Learning Streak
    on<LoadLearningStreak>(_onLoadLearningStreak);
    on<ClaimStreakMilestone>(_onClaimStreakMilestone);

    // Supported Languages
    on<LoadSupportedLanguages>(_onLoadSupportedLanguages);
    on<SelectLanguage>(_onSelectLanguage);

    // Challenges
    on<LoadDailyChallenges>(_onLoadDailyChallenges);
    on<LoadWeeklyChallenges>(_onLoadWeeklyChallenges);
    on<ClaimChallengeReward>(_onClaimChallengeReward);

    // Quizzes
    on<LoadAvailableQuizzes>(_onLoadAvailableQuizzes);
    on<StartQuiz>(_onStartQuiz);
    on<SubmitQuizAnswer>(_onSubmitQuizAnswer);
    on<FinishQuiz>(_onFinishQuiz);

    // Flashcards
    on<LoadFlashcardDecks>(_onLoadFlashcardDecks);
    on<StartFlashcardSession>(_onStartFlashcardSession);
    on<AnswerFlashcard>(_onAnswerFlashcard);
    on<PurchaseFlashcardDeck>(_onPurchaseFlashcardDeck);

    // Achievements
    on<LoadLanguageAchievements>(_onLoadLanguageAchievements);
    on<ClaimAchievementReward>(_onClaimAchievementReward);

    // Language Packs
    on<LoadLanguagePacks>(_onLoadLanguagePacks);
    on<PurchaseLanguagePack>(_onPurchaseLanguagePack);

    // Leaderboard
    on<LoadLeaderboard>(_onLoadLeaderboard);

    // Icebreakers
    on<LoadIcebreakers>(_onLoadIcebreakers);
    on<UseIcebreaker>(_onUseIcebreaker);
    on<GetRandomIcebreaker>(_onGetRandomIcebreaker);

    // AI Coach
    on<StartAiCoachSession>(_onStartAiCoachSession);
    on<SendCoachMessage>(_onSendCoachMessage);
    on<EndCoachSession>(_onEndCoachSession);

    // Seasonal Events
    on<LoadSeasonalEvents>(_onLoadSeasonalEvents);
    on<ClaimSeasonalReward>(_onClaimSeasonalReward);

    // Translation Tracking
    on<TrackTranslation>(_onTrackTranslation);

    // Lessons
    on<LoadLessonsForLanguage>(_onLoadLessonsForLanguage);
    on<PurchaseLessonEvent>(_onPurchaseLesson);
    on<LoadPurchasedLessons>(_onLoadPurchasedLessons);
    on<LoadLessonProgress>(_onLoadLessonProgress);

    // User Preferred Languages
    on<SetUserPreferredLanguages>(_onSetUserPreferredLanguages);
    on<AutoSelectPreferredLanguage>(_onAutoSelectPreferredLanguage);
  }

  Future<void> _onLoadLanguageLearningData(
    LoadLanguageLearningData event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(status: LanguageLearningStatus.loading));

    // Load all initial data
    add(const LoadSupportedLanguages());
    add(const LoadDailyHint());
    add(const LoadLearningStreak());
    add(const LoadAllLanguageProgress());
    add(const LoadDailyChallenges());
    add(const LoadLanguageAchievements());
    add(const LoadSeasonalEvents());

    emit(state.copyWith(status: LanguageLearningStatus.loaded));
  }

  // ==================== Daily Hint Handlers ====================

  Future<void> _onLoadDailyHint(
    LoadDailyHint event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isDailyHintLoading: true));

    final result = await repository.getDailyHint();

    result.fold(
      (failure) => emit(state.copyWith(
        isDailyHintLoading: false,
        errorMessage: failure.message,
      )),
      (hint) => emit(state.copyWith(
        isDailyHintLoading: false,
        dailyHint: hint,
      )),
    );
  }

  Future<void> _onMarkHintAsViewed(
    MarkHintAsViewed event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.markHintAsViewed(event.hintId);

    if (state.dailyHint != null) {
      emit(state.copyWith(
        dailyHint: state.dailyHint!.copyWith(isViewed: true),
      ));
    }
  }

  Future<void> _onMarkHintAsLearned(
    MarkHintAsLearned event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.markHintAsLearned(event.hintId);

    if (state.dailyHint != null) {
      emit(state.copyWith(
        dailyHint: state.dailyHint!.copyWith(isViewed: true, isLearned: true),
      ));
    }

    // Refresh streak
    add(const LoadLearningStreak());
  }

  // ==================== Phrases Handlers ====================

  Future<void> _onLoadPhrases(
    LoadPhrases event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isPhrasesLoading: true));

    final result = await repository.getPhrasesForLanguage(
      event.languageCode,
      category: event.category,
      difficulty: event.difficulty,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isPhrasesLoading: false,
        errorMessage: failure.message,
      )),
      (phrases) => emit(state.copyWith(
        isPhrasesLoading: false,
        phrases: phrases,
      )),
    );
  }

  Future<void> _onMarkPhraseAsLearned(
    MarkPhraseAsLearned event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.markPhraseAsLearned(event.phraseId);

    // Refresh progress
    if (state.selectedLanguageCode != null) {
      add(LoadLanguageProgress(languageCode: state.selectedLanguageCode));
    }
    add(const LoadLearningStreak());
  }

  Future<void> _onTogglePhrasesFavorite(
    TogglePhrasesFavorite event,
    Emitter<LanguageLearningState> emit,
  ) async {
    if (event.isFavorite) {
      await repository.addPhraseToFavorites(event.phraseId);
    } else {
      await repository.removePhraseFromFavorites(event.phraseId);
    }

    add(const LoadFavoritePhrases());
  }

  Future<void> _onLoadFavoritePhrases(
    LoadFavoritePhrases event,
    Emitter<LanguageLearningState> emit,
  ) async {
    final result = await repository.getFavoritePhrases();

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (phrases) => emit(state.copyWith(favoritePhrases: phrases)),
    );
  }

  // ==================== Language Progress Handlers ====================

  Future<void> _onLoadLanguageProgress(
    LoadLanguageProgress event,
    Emitter<LanguageLearningState> emit,
  ) async {
    if (event.languageCode == null) return;

    emit(state.copyWith(isProgressLoading: true));

    final result = await repository.getLanguageProgress(event.languageCode!);

    result.fold(
      (failure) => emit(state.copyWith(
        isProgressLoading: false,
        errorMessage: failure.message,
      )),
      (progress) => emit(state.copyWith(
        isProgressLoading: false,
        currentLanguageProgress: progress,
      )),
    );
  }

  Future<void> _onLoadAllLanguageProgress(
    LoadAllLanguageProgress event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isProgressLoading: true));

    final result = await repository.getAllLanguageProgress();

    result.fold(
      (failure) => emit(state.copyWith(
        isProgressLoading: false,
        errorMessage: failure.message,
      )),
      (progressList) => emit(state.copyWith(
        isProgressLoading: false,
        allLanguageProgress: progressList,
      )),
    );
  }

  // ==================== Learning Streak Handlers ====================

  Future<void> _onLoadLearningStreak(
    LoadLearningStreak event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isStreakLoading: true));

    final result = await repository.getLearningStreak();

    result.fold(
      (failure) => emit(state.copyWith(
        isStreakLoading: false,
        errorMessage: failure.message,
      )),
      (streak) => emit(state.copyWith(
        isStreakLoading: false,
        learningStreak: streak,
      )),
    );
  }

  Future<void> _onClaimStreakMilestone(
    ClaimStreakMilestone event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.claimStreakMilestone(event.milestoneDay);
    add(const LoadLearningStreak());
  }

  // ==================== Supported Languages Handlers ====================

  Future<void> _onLoadSupportedLanguages(
    LoadSupportedLanguages event,
    Emitter<LanguageLearningState> emit,
  ) async {
    final result = await repository.getSupportedLanguages();

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (languages) => emit(state.copyWith(supportedLanguages: languages)),
    );
  }

  Future<void> _onSelectLanguage(
    SelectLanguage event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(selectedLanguageCode: event.languageCode));

    // Load data for selected language
    add(LoadPhrases(languageCode: event.languageCode));
    add(LoadLanguageProgress(languageCode: event.languageCode));
    add(LoadFlashcardDecks(languageCode: event.languageCode));
    add(LoadLessonsForLanguage(languageCode: event.languageCode));
    add(LoadAvailableQuizzes(languageCode: event.languageCode));
  }

  // ==================== Challenges Handlers ====================

  Future<void> _onLoadDailyChallenges(
    LoadDailyChallenges event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isChallengesLoading: true));

    final result = await repository.getDailyChallenges();

    result.fold(
      (failure) => emit(state.copyWith(
        isChallengesLoading: false,
        errorMessage: failure.message,
      )),
      (challenges) => emit(state.copyWith(
        isChallengesLoading: false,
        dailyChallenges: challenges,
      )),
    );
  }

  Future<void> _onLoadWeeklyChallenges(
    LoadWeeklyChallenges event,
    Emitter<LanguageLearningState> emit,
  ) async {
    final result = await repository.getWeeklyChallenges();

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (challenges) => emit(state.copyWith(weeklyChallenges: challenges)),
    );
  }

  Future<void> _onClaimChallengeReward(
    ClaimChallengeReward event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.claimChallengeReward(event.challengeId);
    add(const LoadDailyChallenges());
    add(const LoadWeeklyChallenges());
  }

  // ==================== Quiz Handlers ====================

  Future<void> _onLoadAvailableQuizzes(
    LoadAvailableQuizzes event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isQuizLoading: true));

    final result = await repository.getAvailableQuizzes(
      languageCode: event.languageCode,
      difficulty: event.difficulty,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isQuizLoading: false,
        errorMessage: failure.message,
      )),
      (quizzes) => emit(state.copyWith(
        isQuizLoading: false,
        availableQuizzes: quizzes,
      )),
    );
  }

  Future<void> _onStartQuiz(
    StartQuiz event,
    Emitter<LanguageLearningState> emit,
  ) async {
    final result = await repository.getQuizById(event.quizId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (quiz) => emit(state.copyWith(
        currentQuiz: quiz,
        currentQuestionIndex: 0,
        quizAnswers: [],
      )),
    );
  }

  Future<void> _onSubmitQuizAnswer(
    SubmitQuizAnswer event,
    Emitter<LanguageLearningState> emit,
  ) async {
    if (state.currentQuiz == null) return;

    final question = state.currentQuiz!.questions[state.currentQuestionIndex];
    final isCorrect = question.isCorrect(event.selectedOptionIndex);

    final answer = QuestionResult(
      questionId: event.questionId,
      selectedOptionIndex: event.selectedOptionIndex,
      isCorrect: isCorrect,
    );

    final newAnswers = [...state.quizAnswers, answer];
    final newIndex = state.currentQuestionIndex + 1;

    emit(state.copyWith(
      quizAnswers: newAnswers,
      currentQuestionIndex: newIndex,
    ));

    // If quiz is finished, submit result
    if (newIndex >= state.currentQuiz!.questions.length) {
      add(const FinishQuiz());
    }
  }

  Future<void> _onFinishQuiz(
    FinishQuiz event,
    Emitter<LanguageLearningState> emit,
  ) async {
    if (state.currentQuiz == null) return;

    final correctAnswers = state.quizAnswers.where((a) => a.isCorrect).length;
    final isPerfect = correctAnswers == state.currentQuiz!.questions.length;
    final xpEarned = state.currentQuiz!.calculateXpReward(correctAnswers);
    final coinsEarned = isPerfect ? state.currentQuiz!.perfectScoreCoins : 0;

    final result = QuizResult(
      odUserId: '', // Will be filled by repository
      quizId: state.currentQuiz!.id,
      correctAnswers: correctAnswers,
      totalQuestions: state.currentQuiz!.questions.length,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      isPerfect: isPerfect,
      timeTaken: const Duration(minutes: 5), // TODO: Track actual time
      completedAt: DateTime.now(),
      questionResults: state.quizAnswers,
    );

    final submitResult = await repository.submitQuizResult(result);

    submitResult.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (submittedResult) => emit(state.copyWith(
        lastQuizResult: submittedResult,
        currentQuiz: null,
      )),
    );

    // Refresh progress and streak
    add(const LoadAllLanguageProgress());
    add(const LoadLearningStreak());
  }

  // ==================== Flashcard Handlers ====================

  Future<void> _onLoadFlashcardDecks(
    LoadFlashcardDecks event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isFlashcardsLoading: true));

    final result = await repository.getFlashcardDecks(
      languageCode: event.languageCode,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isFlashcardsLoading: false,
        errorMessage: failure.message,
      )),
      (decks) => emit(state.copyWith(
        isFlashcardsLoading: false,
        flashcardDecks: decks,
      )),
    );
  }

  Future<void> _onStartFlashcardSession(
    StartFlashcardSession event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isFlashcardsLoading: true));

    final result = await repository.getDueFlashcards(
      languageCode: event.languageCode,
      limit: 20,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isFlashcardsLoading: false,
        errorMessage: failure.message,
      )),
      (flashcards) => emit(state.copyWith(
        isFlashcardsLoading: false,
        dueFlashcards: flashcards,
        currentFlashcardIndex: 0,
      )),
    );
  }

  Future<void> _onAnswerFlashcard(
    AnswerFlashcard event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.updateFlashcardReview(event.flashcardId, event.answer);

    final newIndex = state.currentFlashcardIndex + 1;
    emit(state.copyWith(currentFlashcardIndex: newIndex));

    // Refresh streak if session is ongoing
    if (newIndex >= state.dueFlashcards.length) {
      add(const LoadLearningStreak());
    }
  }

  Future<void> _onPurchaseFlashcardDeck(
    PurchaseFlashcardDeck event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.purchaseFlashcardDeck(event.deckId);
    add(LoadFlashcardDecks(languageCode: state.selectedLanguageCode));
  }

  // ==================== Achievement Handlers ====================

  Future<void> _onLoadLanguageAchievements(
    LoadLanguageAchievements event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isAchievementsLoading: true));

    final result = await repository.getLanguageAchievements();

    result.fold(
      (failure) => emit(state.copyWith(
        isAchievementsLoading: false,
        errorMessage: failure.message,
      )),
      (achievements) => emit(state.copyWith(
        isAchievementsLoading: false,
        achievements: achievements,
      )),
    );
  }

  Future<void> _onClaimAchievementReward(
    ClaimAchievementReward event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.claimAchievementReward(event.achievementId);
    add(const LoadLanguageAchievements());
  }

  // ==================== Language Pack Handlers ====================

  Future<void> _onLoadLanguagePacks(
    LoadLanguagePacks event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isPacksLoading: true));

    final result = await repository.getLanguagePacks(
      languageCode: event.languageCode,
      category: event.category,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isPacksLoading: false,
        errorMessage: failure.message,
      )),
      (packs) => emit(state.copyWith(
        isPacksLoading: false,
        languagePacks: packs,
      )),
    );
  }

  Future<void> _onPurchaseLanguagePack(
    PurchaseLanguagePack event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.purchaseLanguagePack(event.packId);
    add(LoadLanguagePacks(languageCode: state.selectedLanguageCode));
  }

  // ==================== Leaderboard Handlers ====================

  Future<void> _onLoadLeaderboard(
    LoadLeaderboard event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isLeaderboardLoading: true));

    final result = await repository.getLeaderboard(
      type: event.type,
      period: event.period,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLeaderboardLoading: false,
        errorMessage: failure.message,
      )),
      (leaderboard) => emit(state.copyWith(
        isLeaderboardLoading: false,
        leaderboard: leaderboard,
      )),
    );
  }

  // ==================== Icebreaker Handlers ====================

  Future<void> _onLoadIcebreakers(
    LoadIcebreakers event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isIcebreakersLoading: true));

    final result = await repository.getIcebreakersForCountry(event.countryCode);

    result.fold(
      (failure) => emit(state.copyWith(
        isIcebreakersLoading: false,
        errorMessage: failure.message,
      )),
      (icebreakers) => emit(state.copyWith(
        isIcebreakersLoading: false,
        icebreakers: icebreakers,
      )),
    );
  }

  Future<void> _onUseIcebreaker(
    UseIcebreaker event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.markIcebreakerAsUsed(event.icebreakerId);
  }

  Future<void> _onGetRandomIcebreaker(
    GetRandomIcebreaker event,
    Emitter<LanguageLearningState> emit,
  ) async {
    final result = await repository.getRandomIcebreaker(event.matchCountryCode);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (icebreaker) => emit(state.copyWith(suggestedIcebreaker: icebreaker)),
    );
  }

  // ==================== AI Coach Handlers ====================

  Future<void> _onStartAiCoachSession(
    StartAiCoachSession event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isCoachLoading: true));

    final result = await repository.startCoachSession(
      languageCode: event.languageCode,
      scenario: event.scenario,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isCoachLoading: false,
        errorMessage: failure.message,
      )),
      (session) => emit(state.copyWith(
        isCoachLoading: false,
        currentCoachSession: session,
      )),
    );
  }

  Future<void> _onSendCoachMessage(
    SendCoachMessage event,
    Emitter<LanguageLearningState> emit,
  ) async {
    if (state.currentCoachSession == null) return;

    emit(state.copyWith(isCoachLoading: true));

    final result = await repository.sendCoachMessage(
      state.currentCoachSession!.id,
      event.message,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isCoachLoading: false,
        errorMessage: failure.message,
      )),
      (response) {
        final updatedMessages = [
          ...state.currentCoachSession!.messages,
          CoachMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: event.message,
            isUserMessage: true,
            timestamp: DateTime.now(),
          ),
          response,
        ];

        emit(state.copyWith(
          isCoachLoading: false,
          currentCoachSession: state.currentCoachSession!.copyWith(
            messages: updatedMessages,
          ),
        ));
      },
    );
  }

  Future<void> _onEndCoachSession(
    EndCoachSession event,
    Emitter<LanguageLearningState> emit,
  ) async {
    if (state.currentCoachSession == null) return;

    await repository.endCoachSession(state.currentCoachSession!.id);
    emit(state.copyWith(currentCoachSession: null));

    // Refresh streak
    add(const LoadLearningStreak());
  }

  // ==================== Seasonal Events Handlers ====================

  Future<void> _onLoadSeasonalEvents(
    LoadSeasonalEvents event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isSeasonalLoading: true));

    final result = await repository.getActiveSeasonalEvents();

    result.fold(
      (failure) => emit(state.copyWith(
        isSeasonalLoading: false,
        errorMessage: failure.message,
      )),
      (events) => emit(state.copyWith(
        isSeasonalLoading: false,
        seasonalEvents: events,
      )),
    );
  }

  Future<void> _onClaimSeasonalReward(
    ClaimSeasonalReward event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.claimSeasonalChallengeReward(
      event.eventId,
      event.challengeId,
    );
    add(const LoadSeasonalEvents());
  }

  // ==================== Translation Tracking Handler ====================

  Future<void> _onTrackTranslation(
    TrackTranslation event,
    Emitter<LanguageLearningState> emit,
  ) async {
    await repository.trackTranslation(event.fromLanguage, event.toLanguage);

    final countResult = await repository.getTranslationCount();
    countResult.fold(
      (failure) => null,
      (count) => emit(state.copyWith(translationCount: count)),
    );

    // Refresh achievements
    add(const LoadLanguageAchievements());
  }

  // ==================== Lesson Handlers ====================

  Future<void> _onLoadLessonsForLanguage(
    LoadLessonsForLanguage event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(isLessonsLoading: true, lessonsError: null));

    final result = await repository.getLessonsForLanguage(
      event.languageCode,
      level: event.level,
      category: event.category,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLessonsLoading: false,
        lessonsError: failure.message,
      )),
      (lessons) => emit(state.copyWith(
        isLessonsLoading: false,
        lessons: lessons,
      )),
    );
  }

  Future<void> _onPurchaseLesson(
    PurchaseLessonEvent event,
    Emitter<LanguageLearningState> emit,
  ) async {
    final result = await repository.purchaseLesson(event.lessonId);

    result.fold(
      (failure) => emit(state.copyWith(lessonsError: failure.message)),
      (userLessonAccess) {
        // Add to purchased lessons set
        final newPurchasedIds = {...state.purchasedLessonIds, event.lessonId};
        emit(state.copyWith(purchasedLessonIds: newPurchasedIds));

        // Reload purchased lessons
        add(const LoadPurchasedLessons());
      },
    );
  }

  Future<void> _onLoadPurchasedLessons(
    LoadPurchasedLessons event,
    Emitter<LanguageLearningState> emit,
  ) async {
    final result = await repository.getPurchasedLessons();

    result.fold(
      (failure) => emit(state.copyWith(lessonsError: failure.message)),
      (userLessonAccessList) {
        final purchasedIds = userLessonAccessList.map((l) => l.lessonId).toSet();
        emit(state.copyWith(
          purchasedLessonIds: purchasedIds,
        ));
      },
    );
  }

  Future<void> _onLoadLessonProgress(
    LoadLessonProgress event,
    Emitter<LanguageLearningState> emit,
  ) async {
    // Progress is tracked per lesson in the repository
    // This can be extended to load specific lesson progress
  }

  /// Helper method to check if a lesson is purchased
  bool isPurchased(String lessonId) {
    return state.purchasedLessonIds.contains(lessonId);
  }

  // ==================== User Preferred Languages Handlers ====================

  Future<void> _onSetUserPreferredLanguages(
    SetUserPreferredLanguages event,
    Emitter<LanguageLearningState> emit,
  ) async {
    emit(state.copyWith(userPreferredLanguages: event.preferredLanguages));

    // Auto-select the first preferred language if no language is selected yet
    if (state.selectedLanguageCode == null &&
        event.preferredLanguages.isNotEmpty) {
      add(const AutoSelectPreferredLanguage());
    }
  }

  Future<void> _onAutoSelectPreferredLanguage(
    AutoSelectPreferredLanguage event,
    Emitter<LanguageLearningState> emit,
  ) async {
    // Don't auto-select if a language is already selected
    if (state.selectedLanguageCode != null) return;

    // Wait for supported languages to be loaded
    if (state.supportedLanguages.isEmpty) return;

    // Find the first preferred language that is supported
    String? languageToSelect;
    for (final preferredLang in state.userPreferredLanguages) {
      final supported = state.supportedLanguages.any(
        (lang) =>
            lang.code.toLowerCase() == preferredLang.toLowerCase() ||
            lang.name.toLowerCase() == preferredLang.toLowerCase(),
      );
      if (supported) {
        // Get the language code
        final matchedLang = state.supportedLanguages.firstWhere(
          (lang) =>
              lang.code.toLowerCase() == preferredLang.toLowerCase() ||
              lang.name.toLowerCase() == preferredLang.toLowerCase(),
        );
        languageToSelect = matchedLang.code;
        break;
      }
    }

    // If no preferred language is supported, default to 'es' (Spanish) or first supported
    languageToSelect ??= state.supportedLanguages.isNotEmpty
        ? (state.supportedLanguages.any((l) => l.code == 'es')
            ? 'es'
            : state.supportedLanguages.first.code)
        : null;

    if (languageToSelect != null) {
      add(SelectLanguage(languageToSelect));
    }
  }
}
