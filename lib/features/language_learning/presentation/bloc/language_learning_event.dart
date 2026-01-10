part of 'language_learning_bloc.dart';

abstract class LanguageLearningEvent extends Equatable {
  const LanguageLearningEvent();

  @override
  List<Object?> get props => [];
}

// ==================== Initialization ====================

class LoadLanguageLearningData extends LanguageLearningEvent {
  const LoadLanguageLearningData();
}

// ==================== Daily Hint Events ====================

class LoadDailyHint extends LanguageLearningEvent {
  const LoadDailyHint();
}

class MarkHintAsViewed extends LanguageLearningEvent {
  final String hintId;
  const MarkHintAsViewed(this.hintId);

  @override
  List<Object?> get props => [hintId];
}

class MarkHintAsLearned extends LanguageLearningEvent {
  final String hintId;
  const MarkHintAsLearned(this.hintId);

  @override
  List<Object?> get props => [hintId];
}

// ==================== Phrases Events ====================

class LoadPhrases extends LanguageLearningEvent {
  final String languageCode;
  final PhraseCategory? category;
  final PhraseDifficulty? difficulty;
  final int? limit;

  const LoadPhrases({
    required this.languageCode,
    this.category,
    this.difficulty,
    this.limit,
  });

  @override
  List<Object?> get props => [languageCode, category, difficulty, limit];
}

class MarkPhraseAsLearned extends LanguageLearningEvent {
  final String phraseId;
  const MarkPhraseAsLearned(this.phraseId);

  @override
  List<Object?> get props => [phraseId];
}

class TogglePhrasesFavorite extends LanguageLearningEvent {
  final String phraseId;
  final bool isFavorite;

  const TogglePhrasesFavorite(this.phraseId, this.isFavorite);

  @override
  List<Object?> get props => [phraseId, isFavorite];
}

class LoadFavoritePhrases extends LanguageLearningEvent {
  const LoadFavoritePhrases();
}

// ==================== Language Progress Events ====================

class LoadLanguageProgress extends LanguageLearningEvent {
  final String? languageCode;
  const LoadLanguageProgress({this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}

class LoadAllLanguageProgress extends LanguageLearningEvent {
  const LoadAllLanguageProgress();
}

// ==================== Learning Streak Events ====================

class LoadLearningStreak extends LanguageLearningEvent {
  const LoadLearningStreak();
}

class ClaimStreakMilestone extends LanguageLearningEvent {
  final int milestoneDay;
  const ClaimStreakMilestone(this.milestoneDay);

  @override
  List<Object?> get props => [milestoneDay];
}

// ==================== Supported Languages Events ====================

class LoadSupportedLanguages extends LanguageLearningEvent {
  const LoadSupportedLanguages();
}

class SelectLanguage extends LanguageLearningEvent {
  final String languageCode;
  const SelectLanguage(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

// ==================== Challenges Events ====================

class LoadDailyChallenges extends LanguageLearningEvent {
  const LoadDailyChallenges();
}

class LoadWeeklyChallenges extends LanguageLearningEvent {
  const LoadWeeklyChallenges();
}

class ClaimChallengeReward extends LanguageLearningEvent {
  final String challengeId;
  const ClaimChallengeReward(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

// ==================== Quiz Events ====================

class LoadAvailableQuizzes extends LanguageLearningEvent {
  final String? languageCode;
  final QuizDifficulty? difficulty;

  const LoadAvailableQuizzes({this.languageCode, this.difficulty});

  @override
  List<Object?> get props => [languageCode, difficulty];
}

class StartQuiz extends LanguageLearningEvent {
  final String quizId;
  const StartQuiz(this.quizId);

  @override
  List<Object?> get props => [quizId];
}

class SubmitQuizAnswer extends LanguageLearningEvent {
  final String questionId;
  final int selectedOptionIndex;

  const SubmitQuizAnswer({
    required this.questionId,
    required this.selectedOptionIndex,
  });

  @override
  List<Object?> get props => [questionId, selectedOptionIndex];
}

class FinishQuiz extends LanguageLearningEvent {
  const FinishQuiz();
}

// ==================== Flashcard Events ====================

class LoadFlashcardDecks extends LanguageLearningEvent {
  final String? languageCode;
  const LoadFlashcardDecks({this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}

class StartFlashcardSession extends LanguageLearningEvent {
  final String? deckId;
  final String? languageCode;

  const StartFlashcardSession({this.deckId, this.languageCode});

  @override
  List<Object?> get props => [deckId, languageCode];
}

class AnswerFlashcard extends LanguageLearningEvent {
  final String flashcardId;
  final FlashcardAnswer answer;

  const AnswerFlashcard({
    required this.flashcardId,
    required this.answer,
  });

  @override
  List<Object?> get props => [flashcardId, answer];
}

class PurchaseFlashcardDeck extends LanguageLearningEvent {
  final String deckId;
  const PurchaseFlashcardDeck(this.deckId);

  @override
  List<Object?> get props => [deckId];
}

// ==================== Achievement Events ====================

class LoadLanguageAchievements extends LanguageLearningEvent {
  const LoadLanguageAchievements();
}

class ClaimAchievementReward extends LanguageLearningEvent {
  final String achievementId;
  const ClaimAchievementReward(this.achievementId);

  @override
  List<Object?> get props => [achievementId];
}

// ==================== Language Pack Events ====================

class LoadLanguagePacks extends LanguageLearningEvent {
  final String? languageCode;
  final PhraseCategory? category;

  const LoadLanguagePacks({this.languageCode, this.category});

  @override
  List<Object?> get props => [languageCode, category];
}

class PurchaseLanguagePack extends LanguageLearningEvent {
  final String packId;
  const PurchaseLanguagePack(this.packId);

  @override
  List<Object?> get props => [packId];
}

// ==================== Leaderboard Events ====================

class LoadLeaderboard extends LanguageLearningEvent {
  final LeaderboardType type;
  final LeaderboardPeriod period;

  const LoadLeaderboard({
    this.type = LeaderboardType.totalXp,
    this.period = LeaderboardPeriod.weekly,
  });

  @override
  List<Object?> get props => [type, period];
}

// ==================== Icebreaker Events ====================

class LoadIcebreakers extends LanguageLearningEvent {
  final String countryCode;
  const LoadIcebreakers(this.countryCode);

  @override
  List<Object?> get props => [countryCode];
}

class UseIcebreaker extends LanguageLearningEvent {
  final String icebreakerId;
  const UseIcebreaker(this.icebreakerId);

  @override
  List<Object?> get props => [icebreakerId];
}

class GetRandomIcebreaker extends LanguageLearningEvent {
  final String matchCountryCode;
  const GetRandomIcebreaker(this.matchCountryCode);

  @override
  List<Object?> get props => [matchCountryCode];
}

// ==================== AI Coach Events ====================

class StartAiCoachSession extends LanguageLearningEvent {
  final String languageCode;
  final CoachScenario scenario;

  const StartAiCoachSession({
    required this.languageCode,
    required this.scenario,
  });

  @override
  List<Object?> get props => [languageCode, scenario];
}

class SendCoachMessage extends LanguageLearningEvent {
  final String message;
  const SendCoachMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class EndCoachSession extends LanguageLearningEvent {
  const EndCoachSession();
}

// ==================== Seasonal Events ====================

class LoadSeasonalEvents extends LanguageLearningEvent {
  const LoadSeasonalEvents();
}

class ClaimSeasonalReward extends LanguageLearningEvent {
  final String eventId;
  final String challengeId;

  const ClaimSeasonalReward({
    required this.eventId,
    required this.challengeId,
  });

  @override
  List<Object?> get props => [eventId, challengeId];
}

// ==================== Translation Tracking ====================

class TrackTranslation extends LanguageLearningEvent {
  final String fromLanguage;
  final String toLanguage;

  const TrackTranslation({
    required this.fromLanguage,
    required this.toLanguage,
  });

  @override
  List<Object?> get props => [fromLanguage, toLanguage];
}

// ==================== Lesson Events ====================

class LoadLessonsForLanguage extends LanguageLearningEvent {
  final String languageCode;
  final LessonLevel? level;
  final LessonCategory? category;
  final int? limit;

  const LoadLessonsForLanguage({
    required this.languageCode,
    this.level,
    this.category,
    this.limit,
  });

  @override
  List<Object?> get props => [languageCode, level, category, limit];
}

class PurchaseLessonEvent extends LanguageLearningEvent {
  final String lessonId;

  const PurchaseLessonEvent({required this.lessonId});

  @override
  List<Object?> get props => [lessonId];
}

class LoadPurchasedLessons extends LanguageLearningEvent {
  const LoadPurchasedLessons();
}

class LoadLessonProgress extends LanguageLearningEvent {
  final String lessonId;

  const LoadLessonProgress({required this.lessonId});

  @override
  List<Object?> get props => [lessonId];
}

// ==================== User Preferred Language Events ====================

class SetUserPreferredLanguages extends LanguageLearningEvent {
  final List<String> preferredLanguages;

  const SetUserPreferredLanguages(this.preferredLanguages);

  @override
  List<Object?> get props => [preferredLanguages];
}

class AutoSelectPreferredLanguage extends LanguageLearningEvent {
  const AutoSelectPreferredLanguage();
}
