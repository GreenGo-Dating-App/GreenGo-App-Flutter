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
  final bool rewardsClaimed;

  UserChallengeProgress({
    required this.userId,
    required this.challengeId,
    required this.progress,
    required this.requiredCount,
    this.isCompleted = false,
    this.completedAt,
    DateTime? createdAt,
    this.rewardsClaimed = false,
  }) : createdAt = createdAt ?? DateTime.now();

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
        rewardsClaimed,
      ];
}

/// Year-Round Daily Challenge Dataset (Point 196)
/// Provides 3 unique challenges per day, rotating through a pool of 21 challenge
/// templates based on day-of-year so every day feels different.
class DailyChallenges {
  static String get _dailyKey {
    final now = DateTime.now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
  }

  /// Full pool of daily challenge templates (21 unique challenges)
  static final List<_ChallengeTemplate> _pool = [
    // Messaging challenges
    _ChallengeTemplate('send_3_messages', 'Quick Chat', 'Send 3 messages', 'message_sent', 3, ChallengeDifficulty.easy, 30, 10),
    _ChallengeTemplate('send_5_messages', 'Message Master', 'Send 5 messages to your matches', 'message_sent', 5, ChallengeDifficulty.easy, 50, 20),
    _ChallengeTemplate('send_10_messages', 'Conversation King', 'Send 10 messages today', 'message_sent', 10, ChallengeDifficulty.medium, 80, 35),
    _ChallengeTemplate('send_15_messages', 'Chat Marathon', 'Send 15 messages today', 'message_sent', 15, ChallengeDifficulty.hard, 120, 50),
    // Match challenges
    _ChallengeTemplate('get_1_match', 'First Spark', 'Get 1 new match today', 'match', 1, ChallengeDifficulty.easy, 40, 15),
    _ChallengeTemplate('get_3_matches', 'Match Maker', 'Get 3 new matches today', 'match', 3, ChallengeDifficulty.medium, 60, 25),
    _ChallengeTemplate('get_5_matches', 'Love Magnet', 'Get 5 new matches today', 'match', 5, ChallengeDifficulty.hard, 100, 40),
    // Super Like challenges
    _ChallengeTemplate('send_1_superlike', 'Priority Pick', 'Send 1 super like', 'super_like', 1, ChallengeDifficulty.easy, 35, 15),
    _ChallengeTemplate('send_3_superlikes', 'Super Liker', 'Send 3 super likes', 'super_like', 3, ChallengeDifficulty.medium, 55, 25),
    _ChallengeTemplate('send_5_superlikes', 'Super Star', 'Send 5 super likes', 'super_like', 5, ChallengeDifficulty.hard, 90, 40),
    // Video call challenges
    _ChallengeTemplate('video_call_1', 'Video Enthusiast', 'Complete 1 video call', 'video_call', 1, ChallengeDifficulty.medium, 75, 50),
    _ChallengeTemplate('video_call_2', 'Video Pro', 'Complete 2 video calls', 'video_call', 2, ChallengeDifficulty.hard, 120, 80),
    // Photo challenges
    _ChallengeTemplate('add_photo', 'Photo Refresh', 'Add or update a profile photo', 'photo_added', 1, ChallengeDifficulty.easy, 40, 15),
    _ChallengeTemplate('add_2_photos', 'Photo Gallery', 'Add 2 new profile photos', 'photo_added', 2, ChallengeDifficulty.medium, 70, 30),
    // Gift challenges
    _ChallengeTemplate('send_1_gift', 'Gift Giver', 'Send 1 gift to a match', 'gift_sent', 1, ChallengeDifficulty.easy, 45, 20),
    _ChallengeTemplate('send_3_gifts', 'Generous Heart', 'Send 3 gifts today', 'gift_sent', 3, ChallengeDifficulty.medium, 80, 35),
    _ChallengeTemplate('send_5_gifts', 'Gift Master', 'Send 5 gifts today', 'gift_sent', 5, ChallengeDifficulty.hard, 130, 55),
    // Mixed difficulty combos
    _ChallengeTemplate('chat_starter', 'Ice Breaker', 'Send 7 messages to different matches', 'message_sent', 7, ChallengeDifficulty.medium, 65, 30),
    _ChallengeTemplate('social_butterfly', 'Social Butterfly', 'Send 20 messages today', 'message_sent', 20, ChallengeDifficulty.epic, 150, 70),
    _ChallengeTemplate('match_rush', 'Match Rush', 'Get 7 matches today', 'match', 7, ChallengeDifficulty.epic, 140, 60),
    _ChallengeTemplate('video_marathon', 'Video Marathon', 'Complete 3 video calls', 'video_call', 3, ChallengeDifficulty.epic, 180, 100),
  ];

  /// Get 3 challenges for today based on day-of-year rotation.
  /// Each day picks a unique combination from the pool.
  static List<DailyChallenge> getRotatingChallenges() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Use day-of-year to pick 3 non-overlapping challenges from the pool
    // Rotate through groups of 3, cycling the full pool over 7 days
    final startIndex = (dayOfYear * 3) % _pool.length;
    final indices = [
      startIndex % _pool.length,
      (startIndex + 1) % _pool.length,
      (startIndex + 2) % _pool.length,
    ];

    return indices.map((i) {
      final t = _pool[i];
      return DailyChallenge(
        challengeId: 'daily_${t.id}_$_dailyKey',
        name: t.name,
        description: t.description,
        type: ChallengeType.daily,
        difficulty: t.difficulty,
        requiredCount: t.requiredCount,
        actionType: t.actionType,
        rewards: [
          ChallengeReward(type: 'xp', amount: t.xp),
          ChallengeReward(type: 'coins', amount: t.coins),
        ],
        startDate: DateTime(now.year, now.month, now.day),
        endDate: tomorrow,
      );
    }).toList();
  }
}

/// Year-Round Weekly Challenge Dataset (Point 199)
/// Provides 3 weekly challenges that rotate each week through a pool of 15 templates.
class WeeklyChallenges {
  static String get _weekKey {
    final now = DateTime.now();
    final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).ceil();
    return '${now.year}_w${weekNumber.toString().padLeft(2, '0')}';
  }

  static int get _weekNumber {
    final now = DateTime.now();
    return ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).ceil();
  }

  /// Full pool of weekly challenge templates (15 unique challenges)
  static final List<_ChallengeTemplate> _pool = [
    // Messaging
    _ChallengeTemplate('weekly_messages_30', 'Chat Enthusiast', 'Send 30 messages this week', 'message_sent', 30, ChallengeDifficulty.easy, 200, 100),
    _ChallengeTemplate('weekly_messages_50', 'Chat Master', 'Send 50 messages this week', 'message_sent', 50, ChallengeDifficulty.medium, 300, 150),
    _ChallengeTemplate('weekly_messages_100', 'Chat Legend', 'Send 100 messages this week', 'message_sent', 100, ChallengeDifficulty.hard, 500, 250),
    // Matches
    _ChallengeTemplate('weekly_matches_10', 'Weekly Connector', 'Get 10 matches this week', 'match', 10, ChallengeDifficulty.easy, 250, 120),
    _ChallengeTemplate('weekly_matches_20', 'Weekly Match Champion', 'Get 20 matches this week', 'match', 20, ChallengeDifficulty.hard, 400, 200),
    _ChallengeTemplate('weekly_matches_30', 'Match Machine', 'Get 30 matches this week', 'match', 30, ChallengeDifficulty.epic, 600, 300),
    // Super Likes
    _ChallengeTemplate('weekly_superlikes_5', 'Weekly Super Liker', 'Send 5 super likes this week', 'super_like', 5, ChallengeDifficulty.easy, 180, 90),
    _ChallengeTemplate('weekly_superlikes_10', 'Super Fan', 'Send 10 super likes this week', 'super_like', 10, ChallengeDifficulty.medium, 300, 150),
    _ChallengeTemplate('weekly_superlikes_15', 'Priority King', 'Send 15 super likes this week', 'super_like', 15, ChallengeDifficulty.hard, 450, 220),
    // Video Calls
    _ChallengeTemplate('weekly_video_3', 'Video Socialite', 'Complete 3 video calls this week', 'video_call', 3, ChallengeDifficulty.medium, 350, 180),
    _ChallengeTemplate('weekly_video_5', 'Video Star', 'Complete 5 video calls this week', 'video_call', 5, ChallengeDifficulty.hard, 500, 250),
    // Gifts
    _ChallengeTemplate('weekly_gifts_5', 'Weekly Gift Giver', 'Send 5 gifts this week', 'gift_sent', 5, ChallengeDifficulty.easy, 200, 100),
    _ChallengeTemplate('weekly_gifts_10', 'Generous Soul', 'Send 10 gifts this week', 'gift_sent', 10, ChallengeDifficulty.medium, 350, 175),
    // Photos
    _ChallengeTemplate('weekly_photos_3', 'Photo Week', 'Add 3 photos this week', 'photo_added', 3, ChallengeDifficulty.easy, 180, 90),
    // Epic combos
    _ChallengeTemplate('weekly_perfect', 'Perfect Week', 'Complete all daily challenges 7 days in a row', 'daily_challenges_completed', 7, ChallengeDifficulty.epic, 700, 350),
  ];

  /// Get 3 weekly challenges based on week-of-year rotation.
  static List<DailyChallenge> getWeeklyChallenges() {
    final now = DateTime.now();
    // Start of this week (Monday)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final startIndex = (_weekNumber * 3) % _pool.length;
    final indices = [
      startIndex % _pool.length,
      (startIndex + 1) % _pool.length,
      (startIndex + 2) % _pool.length,
    ];

    return indices.map((i) {
      final t = _pool[i];
      return DailyChallenge(
        challengeId: 'weekly_${t.id}_$_weekKey',
        name: t.name,
        description: t.description,
        type: ChallengeType.weekly,
        difficulty: t.difficulty,
        requiredCount: t.requiredCount,
        actionType: t.actionType,
        rewards: [
          ChallengeReward(type: 'xp', amount: t.xp),
          ChallengeReward(type: 'coins', amount: t.coins),
        ],
        startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
        endDate: DateTime(weekEnd.year, weekEnd.month, weekEnd.day),
      );
    }).toList();
  }

  /// Alias for datasource compatibility
  static List<DailyChallenge> getAllWeeklyChallenges() => getWeeklyChallenges();
}

/// Internal challenge template used by DailyChallenges and WeeklyChallenges pools
class _ChallengeTemplate {
  final String id;
  final String name;
  final String description;
  final String actionType;
  final int requiredCount;
  final ChallengeDifficulty difficulty;
  final int xp;
  final int coins;

  const _ChallengeTemplate(
    this.id, this.name, this.description, this.actionType,
    this.requiredCount, this.difficulty, this.xp, this.coins,
  );
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
