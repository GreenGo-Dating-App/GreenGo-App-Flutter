import 'package:equatable/equatable.dart';

/// Represents a language learning challenge
class LanguageChallenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final LanguageChallengeType type;
  final ChallengeDifficulty difficulty;
  final int targetCount;
  final int currentProgress;
  final int xpReward;
  final int coinReward;
  final String? badgeReward;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCompleted;
  final bool isRewardClaimed;

  const LanguageChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.targetCount,
    this.currentProgress = 0,
    required this.xpReward,
    required this.coinReward,
    this.badgeReward,
    this.startDate,
    this.endDate,
    this.isCompleted = false,
    this.isRewardClaimed = false,
  });

  LanguageChallenge copyWith({
    String? id,
    String? title,
    String? description,
    LanguageChallengeType? type,
    ChallengeDifficulty? difficulty,
    int? targetCount,
    int? currentProgress,
    int? xpReward,
    int? coinReward,
    String? badgeReward,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    bool? isRewardClaimed,
  }) {
    return LanguageChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      targetCount: targetCount ?? this.targetCount,
      currentProgress: currentProgress ?? this.currentProgress,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      badgeReward: badgeReward ?? this.badgeReward,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isRewardClaimed: isRewardClaimed ?? this.isRewardClaimed,
    );
  }

  double get progressPercentage => targetCount > 0 ? currentProgress / targetCount : 0.0;

  bool get isActive {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        difficulty,
        targetCount,
        currentProgress,
        xpReward,
        coinReward,
        badgeReward,
        startDate,
        endDate,
        isCompleted,
        isRewardClaimed,
      ];

  /// Pre-defined daily language challenges
  static List<LanguageChallenge> get dailyChallenges => [
    const LanguageChallenge(
      id: 'daily_polyglot_chat',
      title: 'Polyglot Chat',
      description: 'Send 3 messages in a foreign language',
      type: LanguageChallengeType.polyglotChat,
      difficulty: ChallengeDifficulty.medium,
      targetCount: 3,
      xpReward: 50,
      coinReward: 30,
    ),
    const LanguageChallenge(
      id: 'daily_cultural_connector',
      title: 'Cultural Connector',
      description: 'Match with someone from a new country',
      type: LanguageChallengeType.culturalConnector,
      difficulty: ChallengeDifficulty.easy,
      targetCount: 1,
      xpReward: 40,
      coinReward: 20,
    ),
    const LanguageChallenge(
      id: 'daily_phrase_master',
      title: 'Phrase Master',
      description: 'Learn 5 new phrases today',
      type: LanguageChallengeType.phraseMaster,
      difficulty: ChallengeDifficulty.medium,
      targetCount: 5,
      xpReward: 35,
      coinReward: 25,
    ),
    const LanguageChallenge(
      id: 'daily_flashcard_streak',
      title: 'Flashcard Streak',
      description: 'Complete 10 flashcard reviews',
      type: LanguageChallengeType.flashcardStreak,
      difficulty: ChallengeDifficulty.easy,
      targetCount: 10,
      xpReward: 30,
      coinReward: 15,
    ),
    const LanguageChallenge(
      id: 'daily_translation_helper',
      title: 'Translation Helper',
      description: 'Translate 5 messages in chat',
      type: LanguageChallengeType.translationHelper,
      difficulty: ChallengeDifficulty.easy,
      targetCount: 5,
      xpReward: 25,
      coinReward: 15,
    ),
  ];

  /// Pre-defined weekly language challenges
  static List<LanguageChallenge> get weeklyChallenges => [
    const LanguageChallenge(
      id: 'weekly_language_explorer',
      title: 'Language Explorer',
      description: 'Learn phrases from 3 different languages',
      type: LanguageChallengeType.languageExplorer,
      difficulty: ChallengeDifficulty.hard,
      targetCount: 3,
      xpReward: 200,
      coinReward: 100,
      badgeReward: 'Language Explorer Badge',
    ),
    const LanguageChallenge(
      id: 'weekly_quiz_champion',
      title: 'Quiz Champion',
      description: 'Complete 5 cultural quizzes',
      type: LanguageChallengeType.quizChampion,
      difficulty: ChallengeDifficulty.medium,
      targetCount: 5,
      xpReward: 150,
      coinReward: 75,
    ),
    const LanguageChallenge(
      id: 'weekly_conversation_master',
      title: 'Conversation Master',
      description: 'Use 10 learned phrases in real chats',
      type: LanguageChallengeType.conversationMaster,
      difficulty: ChallengeDifficulty.hard,
      targetCount: 10,
      xpReward: 250,
      coinReward: 125,
      badgeReward: 'Conversation Master Badge',
    ),
  ];
}

enum LanguageChallengeType {
  polyglotChat,
  culturalConnector,
  phraseMaster,
  flashcardStreak,
  translationHelper,
  languageExplorer,
  quizChampion,
  conversationMaster,
  dailyHint,
  perfectQuiz,
}

extension LanguageChallengeTypeExtension on LanguageChallengeType {
  String get displayName {
    switch (this) {
      case LanguageChallengeType.polyglotChat:
        return 'Polyglot Chat';
      case LanguageChallengeType.culturalConnector:
        return 'Cultural Connector';
      case LanguageChallengeType.phraseMaster:
        return 'Phrase Master';
      case LanguageChallengeType.flashcardStreak:
        return 'Flashcard Streak';
      case LanguageChallengeType.translationHelper:
        return 'Translation Helper';
      case LanguageChallengeType.languageExplorer:
        return 'Language Explorer';
      case LanguageChallengeType.quizChampion:
        return 'Quiz Champion';
      case LanguageChallengeType.conversationMaster:
        return 'Conversation Master';
      case LanguageChallengeType.dailyHint:
        return 'Daily Hint';
      case LanguageChallengeType.perfectQuiz:
        return 'Perfect Quiz';
    }
  }

  String get icon {
    switch (this) {
      case LanguageChallengeType.polyglotChat:
        return '🗣️';
      case LanguageChallengeType.culturalConnector:
        return '🌍';
      case LanguageChallengeType.phraseMaster:
        return '📚';
      case LanguageChallengeType.flashcardStreak:
        return '🃏';
      case LanguageChallengeType.translationHelper:
        return '🔄';
      case LanguageChallengeType.languageExplorer:
        return '🧭';
      case LanguageChallengeType.quizChampion:
        return '🏆';
      case LanguageChallengeType.conversationMaster:
        return '💬';
      case LanguageChallengeType.dailyHint:
        return '💡';
      case LanguageChallengeType.perfectQuiz:
        return '⭐';
    }
  }
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  epic,
}

extension ChallengeDifficultyExtension on ChallengeDifficulty {
  String get displayName {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
      case ChallengeDifficulty.epic:
        return 'Epic';
    }
  }

  String get color {
    switch (this) {
      case ChallengeDifficulty.easy:
        return '#4CAF50'; // Green
      case ChallengeDifficulty.medium:
        return '#FFC107'; // Amber
      case ChallengeDifficulty.hard:
        return '#FF9800'; // Orange
      case ChallengeDifficulty.epic:
        return '#9C27B0'; // Purple
    }
  }
}
