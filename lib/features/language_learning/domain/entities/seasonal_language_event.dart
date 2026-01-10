import 'package:equatable/equatable.dart';

/// Represents a seasonal language learning event
class SeasonalLanguageEvent extends Equatable {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final SeasonalEventType type;
  final List<SeasonalLanguageChallenge> challenges;
  final String themeColor;
  final String accentColor;
  final String icon;
  final String? bannerImageUrl;
  final bool isActive;

  const SeasonalLanguageEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.challenges,
    required this.themeColor,
    required this.accentColor,
    required this.icon,
    this.bannerImageUrl,
    this.isActive = false,
  });

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  int get remainingDays => remainingTime.inDays;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        startDate,
        endDate,
        type,
        challenges,
        themeColor,
        accentColor,
        icon,
        bannerImageUrl,
        isActive,
      ];

  /// Pre-defined seasonal events
  static List<SeasonalLanguageEvent> get allEvents => [
    SeasonalLanguageEvent(
      id: 'valentine_love_languages',
      name: 'Love Languages',
      description: 'Learn romantic phrases in multiple languages this Valentine\'s season!',
      startDate: DateTime(DateTime.now().year, 2, 7),
      endDate: DateTime(DateTime.now().year, 2, 15),
      type: SeasonalEventType.valentines,
      challenges: [
        const SeasonalLanguageChallenge(
          id: 'valentine_5_languages',
          title: 'Love in 5 Languages',
          description: 'Learn romantic phrases in 5 different languages',
          targetCount: 5,
          xpReward: 500,
          coinReward: 300,
          badgeName: 'Cupid Linguist',
        ),
        const SeasonalLanguageChallenge(
          id: 'valentine_50_phrases',
          title: 'Words of Love',
          description: 'Learn 50 romantic phrases',
          targetCount: 50,
          xpReward: 750,
          coinReward: 500,
          badgeName: 'Love Poet',
        ),
        const SeasonalLanguageChallenge(
          id: 'valentine_icebreakers',
          title: 'Romantic Icebreakers',
          description: 'Use 10 romantic icebreakers in conversations',
          targetCount: 10,
          xpReward: 400,
          coinReward: 250,
        ),
      ],
      themeColor: '#FF69B4', // Hot Pink
      accentColor: '#FF1493', // Deep Pink
      icon: '💘',
    ),
    SeasonalLanguageEvent(
      id: 'summer_language_adventure',
      name: 'Summer Language Adventure',
      description: 'Expand your language horizons this summer!',
      startDate: DateTime(DateTime.now().year, 6, 1),
      endDate: DateTime(DateTime.now().year, 8, 31),
      type: SeasonalEventType.summer,
      challenges: [
        const SeasonalLanguageChallenge(
          id: 'summer_beach_vocab',
          title: 'Beach Vocabulary',
          description: 'Learn 30 travel and beach-related phrases',
          targetCount: 30,
          xpReward: 400,
          coinReward: 250,
          badgeName: 'Beach Linguist',
        ),
        const SeasonalLanguageChallenge(
          id: 'summer_world_tour',
          title: 'World Tour',
          description: 'Learn phrases from 10 different countries',
          targetCount: 10,
          xpReward: 1000,
          coinReward: 750,
          badgeName: 'Summer Explorer',
        ),
        const SeasonalLanguageChallenge(
          id: 'summer_quiz_master',
          title: 'Cultural Quiz Master',
          description: 'Complete 20 cultural quizzes',
          targetCount: 20,
          xpReward: 600,
          coinReward: 400,
        ),
      ],
      themeColor: '#FFD700', // Gold
      accentColor: '#FF6347', // Tomato
      icon: '☀️',
    ),
    SeasonalLanguageEvent(
      id: 'holiday_greetings',
      name: 'Holiday Greetings',
      description: 'Learn festive greetings from around the world!',
      startDate: DateTime(DateTime.now().year, 12, 1),
      endDate: DateTime(DateTime.now().year, 12, 31),
      type: SeasonalEventType.holiday,
      challenges: [
        const SeasonalLanguageChallenge(
          id: 'holiday_greetings_10',
          title: 'Festive Greetings',
          description: 'Learn holiday greetings in 10 languages',
          targetCount: 10,
          xpReward: 800,
          coinReward: 600,
          badgeName: 'Holiday Linguist',
        ),
        const SeasonalLanguageChallenge(
          id: 'holiday_gift_messages',
          title: 'Gift of Language',
          description: 'Send greetings using 5 learned phrases',
          targetCount: 5,
          xpReward: 400,
          coinReward: 300,
        ),
        const SeasonalLanguageChallenge(
          id: 'holiday_perfect_week',
          title: 'Holiday Learning Streak',
          description: 'Maintain a 7-day learning streak during holidays',
          targetCount: 7,
          xpReward: 600,
          coinReward: 400,
          badgeName: 'Santa\'s Scholar',
        ),
      ],
      themeColor: '#DC143C', // Crimson
      accentColor: '#228B22', // Forest Green
      icon: '🎄',
    ),
    SeasonalLanguageEvent(
      id: 'new_year_resolutions',
      name: 'New Year Language Goals',
      description: 'Start the year with new language learning goals!',
      startDate: DateTime(DateTime.now().year, 1, 1),
      endDate: DateTime(DateTime.now().year, 1, 31),
      type: SeasonalEventType.newYear,
      challenges: [
        const SeasonalLanguageChallenge(
          id: 'new_year_new_language',
          title: 'New Year, New Language',
          description: 'Start learning a completely new language',
          targetCount: 1,
          xpReward: 300,
          coinReward: 200,
          badgeName: 'Fresh Start',
        ),
        const SeasonalLanguageChallenge(
          id: 'new_year_100_words',
          title: 'Century Challenge',
          description: 'Learn 100 new words in January',
          targetCount: 100,
          xpReward: 1000,
          coinReward: 750,
          badgeName: 'Century Champion',
        ),
        const SeasonalLanguageChallenge(
          id: 'new_year_daily_dedication',
          title: 'Daily Dedication',
          description: 'Practice every day in January (31-day streak)',
          targetCount: 31,
          xpReward: 1500,
          coinReward: 1000,
          badgeName: 'January Master',
        ),
      ],
      themeColor: '#FFD700', // Gold
      accentColor: '#C0C0C0', // Silver
      icon: '🎆',
    ),
  ];
}

class SeasonalLanguageChallenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final int targetCount;
  final int currentProgress;
  final int xpReward;
  final int coinReward;
  final String? badgeName;
  final bool isCompleted;
  final bool isRewardClaimed;

  const SeasonalLanguageChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCount,
    this.currentProgress = 0,
    required this.xpReward,
    required this.coinReward,
    this.badgeName,
    this.isCompleted = false,
    this.isRewardClaimed = false,
  });

  SeasonalLanguageChallenge copyWith({
    String? id,
    String? title,
    String? description,
    int? targetCount,
    int? currentProgress,
    int? xpReward,
    int? coinReward,
    String? badgeName,
    bool? isCompleted,
    bool? isRewardClaimed,
  }) {
    return SeasonalLanguageChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetCount: targetCount ?? this.targetCount,
      currentProgress: currentProgress ?? this.currentProgress,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      badgeName: badgeName ?? this.badgeName,
      isCompleted: isCompleted ?? this.isCompleted,
      isRewardClaimed: isRewardClaimed ?? this.isRewardClaimed,
    );
  }

  double get progressPercentage =>
      targetCount > 0 ? currentProgress / targetCount : 0.0;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        targetCount,
        currentProgress,
        xpReward,
        coinReward,
        badgeName,
        isCompleted,
        isRewardClaimed,
      ];
}

enum SeasonalEventType {
  valentines,
  summer,
  holiday,
  newYear,
  special,
}

extension SeasonalEventTypeExtension on SeasonalEventType {
  String get displayName {
    switch (this) {
      case SeasonalEventType.valentines:
        return 'Valentine\'s Day';
      case SeasonalEventType.summer:
        return 'Summer';
      case SeasonalEventType.holiday:
        return 'Holiday Season';
      case SeasonalEventType.newYear:
        return 'New Year';
      case SeasonalEventType.special:
        return 'Special Event';
    }
  }
}
