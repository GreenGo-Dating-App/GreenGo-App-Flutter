import 'package:equatable/equatable.dart';

/// Represents a language learning achievement/badge
class LanguageAchievement extends Equatable {
  final String id;
  final String name;
  final String description;
  final LanguageAchievementCategory category;
  final AchievementRarity rarity;
  final int requiredProgress;
  final int currentProgress;
  final int xpReward;
  final int coinReward;
  final String iconEmoji;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isSecret;

  const LanguageAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.requiredProgress,
    this.currentProgress = 0,
    this.xpReward = 0,
    this.coinReward = 0,
    required this.iconEmoji,
    this.isUnlocked = false,
    this.unlockedAt,
    this.isSecret = false,
  });

  LanguageAchievement copyWith({
    String? id,
    String? name,
    String? description,
    LanguageAchievementCategory? category,
    AchievementRarity? rarity,
    int? requiredProgress,
    int? currentProgress,
    int? xpReward,
    int? coinReward,
    String? iconEmoji,
    bool? isUnlocked,
    DateTime? unlockedAt,
    bool? isSecret,
  }) {
    return LanguageAchievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      requiredProgress: requiredProgress ?? this.requiredProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  double get progress =>
      requiredProgress > 0 ? currentProgress / requiredProgress : 0.0;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        rarity,
        requiredProgress,
        currentProgress,
        xpReward,
        coinReward,
        iconEmoji,
        isUnlocked,
        unlockedAt,
        isSecret,
      ];

  /// All pre-defined language achievements
  static const List<LanguageAchievement> allAchievements = [
    // Translation Badges
    LanguageAchievement(
      id: 'curious_linguist',
      name: 'Curious Linguist',
      description: 'Translate 10 messages in conversations',
      category: LanguageAchievementCategory.translation,
      rarity: AchievementRarity.common,
      requiredProgress: 10,
      xpReward: 50,
      coinReward: 25,
      iconEmoji: '🔤',
    ),
    LanguageAchievement(
      id: 'language_explorer',
      name: 'Language Explorer',
      description: 'Translate 50 messages in conversations',
      category: LanguageAchievementCategory.translation,
      rarity: AchievementRarity.rare,
      requiredProgress: 50,
      xpReward: 150,
      coinReward: 75,
      iconEmoji: '🧭',
    ),
    LanguageAchievement(
      id: 'polyglot_master',
      name: 'Polyglot Master',
      description: 'Translate 200 messages in conversations',
      category: LanguageAchievementCategory.translation,
      rarity: AchievementRarity.legendary,
      requiredProgress: 200,
      xpReward: 500,
      coinReward: 250,
      iconEmoji: '🌍',
    ),

    // Learning Progress Badges
    LanguageAchievement(
      id: 'first_words',
      name: 'First Words',
      description: 'Learn your first 10 phrases',
      category: LanguageAchievementCategory.learning,
      rarity: AchievementRarity.common,
      requiredProgress: 10,
      xpReward: 30,
      coinReward: 15,
      iconEmoji: '📚',
    ),
    LanguageAchievement(
      id: 'vocabulary_builder',
      name: 'Vocabulary Builder',
      description: 'Learn 50 phrases',
      category: LanguageAchievementCategory.learning,
      rarity: AchievementRarity.uncommon,
      requiredProgress: 50,
      xpReward: 100,
      coinReward: 50,
      iconEmoji: '📖',
    ),
    LanguageAchievement(
      id: 'word_collector',
      name: 'Word Collector',
      description: 'Learn 100 phrases',
      category: LanguageAchievementCategory.learning,
      rarity: AchievementRarity.rare,
      requiredProgress: 100,
      xpReward: 200,
      coinReward: 100,
      iconEmoji: '📕',
    ),
    LanguageAchievement(
      id: 'linguistic_scholar',
      name: 'Linguistic Scholar',
      description: 'Learn 500 phrases',
      category: LanguageAchievementCategory.learning,
      rarity: AchievementRarity.epic,
      requiredProgress: 500,
      xpReward: 400,
      coinReward: 200,
      iconEmoji: '🎓',
    ),
    LanguageAchievement(
      id: 'language_master',
      name: 'Language Master',
      description: 'Learn 1000 phrases',
      category: LanguageAchievementCategory.learning,
      rarity: AchievementRarity.legendary,
      requiredProgress: 1000,
      xpReward: 1000,
      coinReward: 500,
      iconEmoji: '👑',
    ),

    // Multi-language Badges
    LanguageAchievement(
      id: 'bilingual',
      name: 'Bilingual',
      description: 'Learn phrases in 2 different languages',
      category: LanguageAchievementCategory.multilingual,
      rarity: AchievementRarity.common,
      requiredProgress: 2,
      xpReward: 75,
      coinReward: 40,
      iconEmoji: '✌️',
    ),
    LanguageAchievement(
      id: 'trilingual',
      name: 'Trilingual',
      description: 'Learn phrases in 3 different languages',
      category: LanguageAchievementCategory.multilingual,
      rarity: AchievementRarity.uncommon,
      requiredProgress: 3,
      xpReward: 150,
      coinReward: 75,
      iconEmoji: '🔱',
    ),
    LanguageAchievement(
      id: 'polyglot',
      name: 'Polyglot',
      description: 'Learn phrases in 5 different languages',
      category: LanguageAchievementCategory.multilingual,
      rarity: AchievementRarity.rare,
      requiredProgress: 5,
      xpReward: 300,
      coinReward: 150,
      iconEmoji: '🌐',
    ),
    LanguageAchievement(
      id: 'hyperpolyglot',
      name: 'Hyperpolyglot',
      description: 'Learn phrases in 10 different languages',
      category: LanguageAchievementCategory.multilingual,
      rarity: AchievementRarity.legendary,
      requiredProgress: 10,
      xpReward: 750,
      coinReward: 400,
      iconEmoji: '🌟',
    ),

    // Quiz Badges
    LanguageAchievement(
      id: 'quiz_starter',
      name: 'Quiz Starter',
      description: 'Complete your first cultural quiz',
      category: LanguageAchievementCategory.quiz,
      rarity: AchievementRarity.common,
      requiredProgress: 1,
      xpReward: 25,
      coinReward: 10,
      iconEmoji: '❓',
    ),
    LanguageAchievement(
      id: 'quiz_enthusiast',
      name: 'Quiz Enthusiast',
      description: 'Complete 10 cultural quizzes',
      category: LanguageAchievementCategory.quiz,
      rarity: AchievementRarity.uncommon,
      requiredProgress: 10,
      xpReward: 100,
      coinReward: 50,
      iconEmoji: '🎯',
    ),
    LanguageAchievement(
      id: 'culture_expert',
      name: 'Culture Expert',
      description: 'Get a perfect score on 5 quizzes',
      category: LanguageAchievementCategory.quiz,
      rarity: AchievementRarity.rare,
      requiredProgress: 5,
      xpReward: 200,
      coinReward: 100,
      iconEmoji: '🏆',
    ),

    // Streak Badges
    LanguageAchievement(
      id: 'weekly_learner',
      name: 'Weekly Learner',
      description: 'Maintain a 7-day learning streak',
      category: LanguageAchievementCategory.streak,
      rarity: AchievementRarity.common,
      requiredProgress: 7,
      xpReward: 75,
      coinReward: 50,
      iconEmoji: '🔥',
    ),
    LanguageAchievement(
      id: 'monthly_dedication',
      name: 'Monthly Dedication',
      description: 'Maintain a 30-day learning streak',
      category: LanguageAchievementCategory.streak,
      rarity: AchievementRarity.rare,
      requiredProgress: 30,
      xpReward: 300,
      coinReward: 200,
      iconEmoji: '💪',
    ),
    LanguageAchievement(
      id: 'yearly_commitment',
      name: 'Yearly Commitment',
      description: 'Maintain a 365-day learning streak',
      category: LanguageAchievementCategory.streak,
      rarity: AchievementRarity.legendary,
      requiredProgress: 365,
      xpReward: 3000,
      coinReward: 2500,
      iconEmoji: '⭐',
    ),

    // Flashcard Badges
    LanguageAchievement(
      id: 'flashcard_beginner',
      name: 'Flashcard Beginner',
      description: 'Review 50 flashcards',
      category: LanguageAchievementCategory.flashcard,
      rarity: AchievementRarity.common,
      requiredProgress: 50,
      xpReward: 40,
      coinReward: 20,
      iconEmoji: '🃏',
    ),
    LanguageAchievement(
      id: 'flashcard_pro',
      name: 'Flashcard Pro',
      description: 'Review 500 flashcards',
      category: LanguageAchievementCategory.flashcard,
      rarity: AchievementRarity.rare,
      requiredProgress: 500,
      xpReward: 200,
      coinReward: 100,
      iconEmoji: '🎴',
    ),
    LanguageAchievement(
      id: 'mastery_achieved',
      name: 'Mastery Achieved',
      description: 'Master 100 flashcards',
      category: LanguageAchievementCategory.flashcard,
      rarity: AchievementRarity.epic,
      requiredProgress: 100,
      xpReward: 350,
      coinReward: 175,
      iconEmoji: '🎖️',
    ),

    // Social/Cultural Badges
    LanguageAchievement(
      id: 'cultural_ambassador',
      name: 'Cultural Ambassador',
      description: 'Use icebreakers in 10 conversations',
      category: LanguageAchievementCategory.social,
      rarity: AchievementRarity.uncommon,
      requiredProgress: 10,
      xpReward: 100,
      coinReward: 50,
      iconEmoji: '🤝',
    ),
    LanguageAchievement(
      id: 'world_connector',
      name: 'World Connector',
      description: 'Match with people from 10 different countries',
      category: LanguageAchievementCategory.social,
      rarity: AchievementRarity.rare,
      requiredProgress: 10,
      xpReward: 250,
      coinReward: 125,
      iconEmoji: '🌎',
    ),
  ];
}

enum LanguageAchievementCategory {
  translation,
  learning,
  multilingual,
  quiz,
  streak,
  flashcard,
  social,
  seasonal,
}

extension LanguageAchievementCategoryExtension on LanguageAchievementCategory {
  String get displayName {
    switch (this) {
      case LanguageAchievementCategory.translation:
        return 'Translation';
      case LanguageAchievementCategory.learning:
        return 'Learning';
      case LanguageAchievementCategory.multilingual:
        return 'Multilingual';
      case LanguageAchievementCategory.quiz:
        return 'Quiz';
      case LanguageAchievementCategory.streak:
        return 'Streak';
      case LanguageAchievementCategory.flashcard:
        return 'Flashcard';
      case LanguageAchievementCategory.social:
        return 'Social';
      case LanguageAchievementCategory.seasonal:
        return 'Seasonal';
    }
  }
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

extension AchievementRarityExtension on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  String get color {
    switch (this) {
      case AchievementRarity.common:
        return '#9E9E9E'; // Gray
      case AchievementRarity.uncommon:
        return '#4CAF50'; // Green
      case AchievementRarity.rare:
        return '#2196F3'; // Blue
      case AchievementRarity.epic:
        return '#9C27B0'; // Purple
      case AchievementRarity.legendary:
        return '#FFD700'; // Gold
    }
  }
}
