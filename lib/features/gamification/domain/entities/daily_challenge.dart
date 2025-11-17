import 'package:equatable/equatable.dart';

/// Daily Challenge Entity
/// Points 196-200: Daily Challenges & Events
class DailyChallenge extends Equatable {
  final String challengeId;
  final String name;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int requiredCount;
  final String actionType;
  final List<ChallengeReward> rewards;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const DailyChallenge({
    required this.challengeId,
    required this.name,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.requiredCount,
    required this.actionType,
    required this.rewards,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  /// Check if challenge is currently active
  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get time remaining
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  @override
  List<Object?> get props => [
        challengeId,
        name,
        description,
        type,
        difficulty,
        requiredCount,
        actionType,
        rewards,
        startDate,
        endDate,
        isActive,
      ];
}

/// Challenge Types
enum ChallengeType {
  daily,   // Resets daily
  weekly,  // Resets weekly
  monthly, // Resets monthly
  seasonal, // Special events
}

/// Challenge Difficulty
enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  epic,
}

/// Challenge Reward
class ChallengeReward {
  final String type; // xp, coins, boost, badge
  final int amount;
  final String? itemId;

  const ChallengeReward({
    required this.type,
    required this.amount,
    this.itemId,
  });
}

/// User Challenge Progress
class UserChallengeProgress extends Equatable {
  final String userId;
  final String challengeId;
  final int progress;
  final int requiredCount;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  const UserChallengeProgress({
    required this.userId,
    required this.challengeId,
    required this.progress,
    required this.requiredCount,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  /// Get progress percentage
  double get progressPercentage {
    if (requiredCount == 0) return 100.0;
    return (progress / requiredCount * 100).clamp(0.0, 100.0);
  }

  /// Check if ready to claim
  bool get canClaim {
    return progress >= requiredCount && !isCompleted;
  }

  @override
  List<Object?> get props => [
        userId,
        challengeId,
        progress,
        requiredCount,
        isCompleted,
        completedAt,
        createdAt,
      ];
}

/// Standard Daily Challenges (Point 196)
class DailyChallenges {
  /// Send 5 messages
  static DailyChallenge get sendMessages {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return DailyChallenge(
      challengeId: 'daily_send_messages_${now.millisecondsSinceEpoch}',
      name: 'Message Master',
      description: 'Send 5 messages to your matches',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.easy,
      requiredCount: 5,
      actionType: 'message_sent',
      rewards: const [
        ChallengeReward(type: 'xp', amount: 50),
        ChallengeReward(type: 'coins', amount: 20),
      ],
      startDate: DateTime(now.year, now.month, now.day),
      endDate: tomorrow,
    );
  }

  /// Complete 1 video call
  static DailyChallenge get videoCall {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return DailyChallenge(
      challengeId: 'daily_video_call_${now.millisecondsSinceEpoch}',
      name: 'Video Enthusiast',
      description: 'Complete 1 video call with a match',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.medium,
      requiredCount: 1,
      actionType: 'video_call',
      rewards: const [
        ChallengeReward(type: 'xp', amount: 75),
        ChallengeReward(type: 'coins', amount: 50),
      ],
      startDate: DateTime(now.year, now.month, now.day),
      endDate: tomorrow,
    );
  }

  /// Update profile photo
  static DailyChallenge get updatePhoto {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return DailyChallenge(
      challengeId: 'daily_update_photo_${now.millisecondsSinceEpoch}',
      name: 'Photo Refresh',
      description: 'Update or add a new profile photo',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.easy,
      requiredCount: 1,
      actionType: 'photo_added',
      rewards: const [
        ChallengeReward(type: 'xp', amount: 40),
        ChallengeReward(type: 'coins', amount: 15),
      ],
      startDate: DateTime(now.year, now.month, now.day),
      endDate: tomorrow,
    );
  }

  /// Get 3 matches
  static DailyChallenge get getMatches {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return DailyChallenge(
      challengeId: 'daily_get_matches_${now.millisecondsSinceEpoch}',
      name: 'Match Maker',
      description: 'Get 3 new matches today',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.medium,
      requiredCount: 3,
      actionType: 'match',
      rewards: const [
        ChallengeReward(type: 'xp', amount: 60),
        ChallengeReward(type: 'boost', amount: 1),
      ],
      startDate: DateTime(now.year, now.month, now.day),
      endDate: tomorrow,
    );
  }

  /// Send super likes
  static DailyChallenge get superLikes {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return DailyChallenge(
      challengeId: 'daily_super_likes_${now.millisecondsSinceEpoch}',
      name: 'Super Liker',
      description: 'Send 3 super likes',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.easy,
      requiredCount: 3,
      actionType: 'super_like',
      rewards: const [
        ChallengeReward(type: 'xp', amount: 45),
        ChallengeReward(type: 'coins', amount: 25),
      ],
      startDate: DateTime(now.year, now.month, now.day),
      endDate: tomorrow,
    );
  }

  /// Get all daily challenges
  static List<DailyChallenge> getRotatingChallenges() {
    // Rotate challenges based on day of week
    final dayOfWeek = DateTime.now().weekday;

    switch (dayOfWeek) {
      case DateTime.monday:
        return [sendMessages, getMatches, updatePhoto];
      case DateTime.tuesday:
        return [videoCall, superLikes, sendMessages];
      case DateTime.wednesday:
        return [getMatches, updatePhoto, videoCall];
      case DateTime.thursday:
        return [sendMessages, superLikes, getMatches];
      case DateTime.friday:
        return [videoCall, sendMessages, updatePhoto];
      case DateTime.saturday:
        return [getMatches, videoCall, superLikes];
      case DateTime.sunday:
        return [sendMessages, updatePhoto, superLikes];
      default:
        return [sendMessages, getMatches, videoCall];
    }
  }
}

/// Weekly Mega-Challenges (Point 199)
class WeeklyChallenges {
  /// Complete all daily challenges for 7 days
  static DailyChallenge get perfectWeek {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return DailyChallenge(
      challengeId: 'weekly_perfect_${now.millisecondsSinceEpoch}',
      name: 'Perfect Week',
      description: 'Complete all daily challenges for 7 consecutive days',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.epic,
      requiredCount: 7,
      actionType: 'daily_challenges_completed',
      rewards: const [
        ChallengeReward(type: 'xp', amount: 500),
        ChallengeReward(type: 'coins', amount: 250),
        ChallengeReward(type: 'badge', amount: 1, itemId: 'perfect_week_badge'),
      ],
      startDate: now,
      endDate: nextWeek,
    );
  }

  /// Get 20 matches in a week
  static DailyChallenge get weeklyMatcher {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return DailyChallenge(
      challengeId: 'weekly_matches_${now.millisecondsSinceEpoch}',
      name: 'Weekly Match Champion',
      description: 'Get 20 matches this week',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.hard,
      requiredCount: 20,
      actionType: 'match',
      rewards: const [
        ChallengeReward(type: 'xp', amount: 400),
        ChallengeReward(type: 'coins', amount: 200),
      ],
      startDate: now,
      endDate: nextWeek,
    );
  }

  /// Send 50 messages
  static DailyChallenge get weeklyMessenger {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return DailyChallenge(
      challengeId: 'weekly_messages_${now.millisecondsSinceEpoch}',
      name: 'Chat Master',
      description: 'Send 50 messages this week',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.medium,
      requiredCount: 50,
      actionType: 'message_sent',
      rewards: const [
        ChallengeReward(type: 'xp', amount: 300),
        ChallengeReward(type: 'coins', amount: 150),
      ],
      startDate: now,
      endDate: nextWeek,
    );
  }

  /// Get all weekly challenges
  static List<DailyChallenge> getWeeklyChallenges() {
    return [
      perfectWeek,
      weeklyMatcher,
      weeklyMessenger,
    ];
  }
}

/// Seasonal Events (Point 200)
class SeasonalEvent extends Equatable {
  final String eventId;
  final String name;
  final String description;
  final String theme; // valentine, summer, holiday
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyChallenge> challenges;
  final Map<String, dynamic> themeConfig; // UI customization

  const SeasonalEvent({
    required this.eventId,
    required this.name,
    required this.description,
    required this.theme,
    required this.startDate,
    required this.endDate,
    required this.challenges,
    this.themeConfig = const {},
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  @override
  List<Object?> get props => [
        eventId,
        name,
        description,
        theme,
        startDate,
        endDate,
        challenges,
        themeConfig,
      ];
}

/// Seasonal Events
class SeasonalEvents {
  /// Valentine's Day Event
  static SeasonalEvent valentinesDay(int year) {
    return SeasonalEvent(
      eventId: 'valentines_$year',
      name: 'Valentine\'s Week',
      description: 'Spread the love this Valentine\'s Week!',
      theme: 'valentine',
      startDate: DateTime(year, 2, 7), // Week before Valentine's
      endDate: DateTime(year, 2, 15),  // Day after Valentine's
      challenges: [
        DailyChallenge(
          challengeId: 'valentine_matches_$year',
          name: 'Love Connections',
          description: 'Get 14 matches during Valentine\'s Week (1 per day)',
          type: ChallengeType.seasonal,
          difficulty: ChallengeDifficulty.hard,
          requiredCount: 14,
          actionType: 'match',
          rewards: const [
            ChallengeReward(type: 'xp', amount: 750),
            ChallengeReward(type: 'coins', amount: 500),
            ChallengeReward(type: 'badge', amount: 1, itemId: 'cupid_badge'),
          ],
          startDate: DateTime(year, 2, 7),
          endDate: DateTime(year, 2, 15),
        ),
        DailyChallenge(
          challengeId: 'valentine_video_$year',
          name: 'Virtual Date Night',
          description: 'Complete 3 video calls',
          type: ChallengeType.seasonal,
          difficulty: ChallengeDifficulty.medium,
          requiredCount: 3,
          actionType: 'video_call',
          rewards: const [
            ChallengeReward(type: 'xp', amount: 500),
            ChallengeReward(type: 'coins', amount: 300),
          ],
          startDate: DateTime(year, 2, 7),
          endDate: DateTime(year, 2, 15),
        ),
      ],
      themeConfig: const {
        'primaryColor': 0xFFFF69B4, // Pink
        'accentColor': 0xFFFF1493,  // Deep pink
        'iconSet': 'hearts',
        'backgroundPattern': 'hearts_pattern',
      },
    );
  }

  /// Summer Love Event
  static SeasonalEvent summerLove(int year) {
    return SeasonalEvent(
      eventId: 'summer_$year',
      name: 'Summer Love',
      description: 'Find your summer romance!',
      theme: 'summer',
      startDate: DateTime(year, 6, 1),
      endDate: DateTime(year, 8, 31),
      challenges: [
        DailyChallenge(
          challengeId: 'summer_matches_$year',
          name: 'Beach Vibes',
          description: 'Get 30 matches this summer',
          type: ChallengeType.seasonal,
          difficulty: ChallengeDifficulty.epic,
          requiredCount: 30,
          actionType: 'match',
          rewards: const [
            ChallengeReward(type: 'xp', amount: 1000),
            ChallengeReward(type: 'coins', amount: 750),
            ChallengeReward(type: 'badge', amount: 1, itemId: 'summer_love_badge'),
          ],
          startDate: DateTime(year, 6, 1),
          endDate: DateTime(year, 8, 31),
        ),
      ],
      themeConfig: const {
        'primaryColor': 0xFFFFD700, // Gold
        'accentColor': 0xFFFF6347,  // Tomato
        'iconSet': 'sun',
        'backgroundPattern': 'beach_pattern',
      },
    );
  }

  /// Holiday Season Event
  static SeasonalEvent holidaySeason(int year) {
    return SeasonalEvent(
      eventId: 'holiday_$year',
      name: 'Holiday Season',
      description: 'Find love this holiday season!',
      theme: 'holiday',
      startDate: DateTime(year, 12, 1),
      endDate: DateTime(year, 12, 31),
      challenges: [
        DailyChallenge(
          challengeId: 'holiday_gifts_$year',
          name: 'Gift Giver',
          description: 'Send 10 coin gifts to matches',
          type: ChallengeType.seasonal,
          difficulty: ChallengeDifficulty.hard,
          requiredCount: 10,
          actionType: 'gift_sent',
          rewards: const [
            ChallengeReward(type: 'xp', amount: 800),
            ChallengeReward(type: 'coins', amount: 600),
            ChallengeReward(type: 'badge', amount: 1, itemId: 'santa_badge'),
          ],
          startDate: DateTime(year, 12, 1),
          endDate: DateTime(year, 12, 31),
        ),
        DailyChallenge(
          challengeId: 'holiday_messages_$year',
          name: 'Holiday Cheer',
          description: 'Send 100 messages',
          type: ChallengeType.seasonal,
          difficulty: ChallengeDifficulty.epic,
          requiredCount: 100,
          actionType: 'message_sent',
          rewards: const [
            ChallengeReward(type: 'xp', amount: 600),
            ChallengeReward(type: 'coins', amount: 400),
          ],
          startDate: DateTime(year, 12, 1),
          endDate: DateTime(year, 12, 31),
        ),
      ],
      themeConfig: const {
        'primaryColor': 0xFFDC143C, // Crimson
        'accentColor': 0xFF228B22,  // Forest green
        'iconSet': 'snowflakes',
        'backgroundPattern': 'snowflakes_pattern',
      },
    );
  }

  /// Get active seasonal event
  static SeasonalEvent? getActiveEvent() {
    final now = DateTime.now();
    final year = now.year;

    final events = [
      valentinesDay(year),
      summerLove(year),
      holidaySeason(year),
    ];

    for (final event in events) {
      if (event.isActive) return event;
    }

    return null;
  }

  /// Get all events for year
  static List<SeasonalEvent> getAllEvents(int year) {
    return [
      valentinesDay(year),
      summerLove(year),
      holidaySeason(year),
    ];
  }
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

  int get colorValue {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 0xFF4CAF50; // Green
      case ChallengeDifficulty.medium:
        return 0xFF2196F3; // Blue
      case ChallengeDifficulty.hard:
        return 0xFF9C27B0; // Purple
      case ChallengeDifficulty.epic:
        return 0xFFFF9800; // Orange
    }
  }
}
