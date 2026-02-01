import 'package:equatable/equatable.dart';

/// Quest Entity - Multi-step missions with bigger rewards
class Quest extends Equatable {
  final String questId;
  final String name;
  final String description;
  final String iconUrl;
  final QuestType type;
  final QuestDifficulty difficulty;
  final List<QuestStep> steps;
  final List<QuestReward> rewards;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int requiredLevel;

  const Quest({
    required this.questId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.difficulty,
    required this.steps,
    required this.rewards,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.requiredLevel = 1,
  });

  /// Get total steps count
  int get totalSteps => steps.length;

  /// Check if quest is time-limited
  bool get isTimeLimited => startDate != null && endDate != null;

  /// Check if currently available
  bool get isCurrentlyAvailable {
    if (!isActive) return false;
    if (!isTimeLimited) return true;
    final now = DateTime.now();
    return now.isAfter(startDate!) && now.isBefore(endDate!);
  }

  @override
  List<Object?> get props => [
        questId,
        name,
        description,
        iconUrl,
        type,
        difficulty,
        steps,
        rewards,
        startDate,
        endDate,
        isActive,
        requiredLevel,
      ];
}

/// Quest Types
enum QuestType {
  onboarding,    // New user quests
  daily,         // Daily quests (reset daily)
  weekly,        // Weekly quests
  monthly,       // Monthly quests
  story,         // Story-based progression
  seasonal,      // Limited time events
  premium,       // Premium-only quests
}

/// Quest Difficulty
enum QuestDifficulty {
  beginner,
  easy,
  medium,
  hard,
  expert,
  legendary,
}

/// Quest Step - Individual task within a quest
class QuestStep extends Equatable {
  final String stepId;
  final int order;
  final String title;
  final String description;
  final String actionType;
  final int requiredCount;
  final int xpReward;

  const QuestStep({
    required this.stepId,
    required this.order,
    required this.title,
    required this.description,
    required this.actionType,
    required this.requiredCount,
    this.xpReward = 0,
  });

  @override
  List<Object?> get props => [
        stepId,
        order,
        title,
        description,
        actionType,
        requiredCount,
        xpReward,
      ];
}

/// Quest Reward
class QuestReward extends Equatable {
  final String type; // xp, coins, badge, boost, premium_time, exclusive_item
  final int amount;
  final String? itemId;
  final String? description;

  const QuestReward({
    required this.type,
    required this.amount,
    this.itemId,
    this.description,
  });

  @override
  List<Object?> get props => [type, amount, itemId, description];
}

/// User Quest Progress
class UserQuestProgress extends Equatable {
  final String id;
  final String odId;
  final String questId;
  final int currentStep;
  final Map<String, int> stepProgress; // stepId -> progress
  final QuestProgressStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool rewardsClaimed;

  const UserQuestProgress({
    required this.id,
    required this.odId,
    required this.questId,
    required this.currentStep,
    required this.stepProgress,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.rewardsClaimed = false,
  });

  @override
  List<Object?> get props => [
        id,
        odId,
        questId,
        currentStep,
        stepProgress,
        status,
        startedAt,
        completedAt,
        rewardsClaimed,
      ];
}

/// Quest Progress Status
enum QuestProgressStatus {
  notStarted,
  inProgress,
  completed,
  expired,
  abandoned,
}

/// Standard Quests
class Quests {
  /// Onboarding Quest - Profile Setup
  static Quest get profileSetup => Quest(
        questId: 'quest_profile_setup',
        name: 'Perfect Profile',
        description: 'Complete your profile to attract more matches',
        iconUrl: 'assets/quests/profile_setup.png',
        type: QuestType.onboarding,
        difficulty: QuestDifficulty.beginner,
        steps: const [
          QuestStep(
            stepId: 'step_photo',
            order: 1,
            title: 'Add Photos',
            description: 'Add at least 3 photos to your profile',
            actionType: 'photo_added',
            requiredCount: 3,
            xpReward: 25,
          ),
          QuestStep(
            stepId: 'step_bio',
            order: 2,
            title: 'Write Your Bio',
            description: 'Add a bio (at least 50 characters)',
            actionType: 'bio_updated',
            requiredCount: 1,
            xpReward: 25,
          ),
          QuestStep(
            stepId: 'step_interests',
            order: 3,
            title: 'Select Interests',
            description: 'Choose at least 5 interests',
            actionType: 'interests_selected',
            requiredCount: 5,
            xpReward: 25,
          ),
          QuestStep(
            stepId: 'step_verify',
            order: 4,
            title: 'Verify Profile',
            description: 'Complete photo verification',
            actionType: 'profile_verified',
            requiredCount: 1,
            xpReward: 50,
          ),
        ],
        rewards: const [
          QuestReward(type: 'xp', amount: 200),
          QuestReward(type: 'coins', amount: 100),
          QuestReward(type: 'boost', amount: 1, description: 'Free profile boost'),
        ],
      );

  /// First Week Quest
  static Quest get firstWeek => Quest(
        questId: 'quest_first_week',
        name: 'First Week Adventure',
        description: 'Explore GreenGo in your first week',
        iconUrl: 'assets/quests/first_week.png',
        type: QuestType.onboarding,
        difficulty: QuestDifficulty.easy,
        steps: const [
          QuestStep(
            stepId: 'step_swipe',
            order: 1,
            title: 'Start Swiping',
            description: 'Swipe on 20 profiles',
            actionType: 'swipe',
            requiredCount: 20,
            xpReward: 30,
          ),
          QuestStep(
            stepId: 'step_match',
            order: 2,
            title: 'Get Matches',
            description: 'Get your first 5 matches',
            actionType: 'match',
            requiredCount: 5,
            xpReward: 50,
          ),
          QuestStep(
            stepId: 'step_message',
            order: 3,
            title: 'Start Conversations',
            description: 'Send messages to 3 matches',
            actionType: 'first_message',
            requiredCount: 3,
            xpReward: 40,
          ),
          QuestStep(
            stepId: 'step_daily',
            order: 4,
            title: 'Daily Dedication',
            description: 'Login for 5 days',
            actionType: 'daily_login',
            requiredCount: 5,
            xpReward: 50,
          ),
        ],
        rewards: const [
          QuestReward(type: 'xp', amount: 300),
          QuestReward(type: 'coins', amount: 200),
          QuestReward(type: 'super_like', amount: 5),
        ],
      );

  /// Social Butterfly Quest
  static Quest get socialButterfly => Quest(
        questId: 'quest_social_butterfly',
        name: 'Social Butterfly',
        description: 'Become a conversation master',
        iconUrl: 'assets/quests/social_butterfly.png',
        type: QuestType.story,
        difficulty: QuestDifficulty.medium,
        requiredLevel: 5,
        steps: const [
          QuestStep(
            stepId: 'step_matches',
            order: 1,
            title: 'Growing Network',
            description: 'Get 25 total matches',
            actionType: 'match',
            requiredCount: 25,
            xpReward: 75,
          ),
          QuestStep(
            stepId: 'step_conversations',
            order: 2,
            title: 'Conversation Starter',
            description: 'Start 10 conversations',
            actionType: 'first_message',
            requiredCount: 10,
            xpReward: 75,
          ),
          QuestStep(
            stepId: 'step_messages',
            order: 3,
            title: 'Active Chatter',
            description: 'Send 100 messages',
            actionType: 'message_sent',
            requiredCount: 100,
            xpReward: 100,
          ),
          QuestStep(
            stepId: 'step_active',
            order: 4,
            title: 'Maintain Connections',
            description: 'Have 10 active conversations',
            actionType: 'active_conversation',
            requiredCount: 10,
            xpReward: 100,
          ),
        ],
        rewards: const [
          QuestReward(type: 'xp', amount: 500),
          QuestReward(type: 'coins', amount: 300),
          QuestReward(
            type: 'badge',
            amount: 1,
            itemId: 'social_butterfly_badge',
            description: 'Social Butterfly Badge',
          ),
        ],
      );

  /// Video Dating Quest
  static Quest get videoDateMaster => Quest(
        questId: 'quest_video_master',
        name: 'Video Date Master',
        description: 'Become comfortable with video calls',
        iconUrl: 'assets/quests/video_master.png',
        type: QuestType.story,
        difficulty: QuestDifficulty.hard,
        requiredLevel: 10,
        steps: const [
          QuestStep(
            stepId: 'step_video_profile',
            order: 1,
            title: 'Video Introduction',
            description: 'Add a video to your profile',
            actionType: 'video_added',
            requiredCount: 1,
            xpReward: 50,
          ),
          QuestStep(
            stepId: 'step_first_call',
            order: 2,
            title: 'First Video Call',
            description: 'Complete your first video call',
            actionType: 'video_call',
            requiredCount: 1,
            xpReward: 75,
          ),
          QuestStep(
            stepId: 'step_video_regular',
            order: 3,
            title: 'Video Regular',
            description: 'Complete 5 video calls',
            actionType: 'video_call',
            requiredCount: 5,
            xpReward: 100,
          ),
          QuestStep(
            stepId: 'step_video_expert',
            order: 4,
            title: 'Video Expert',
            description: 'Complete 10 video calls',
            actionType: 'video_call',
            requiredCount: 10,
            xpReward: 150,
          ),
        ],
        rewards: const [
          QuestReward(type: 'xp', amount: 750),
          QuestReward(type: 'coins', amount: 500),
          QuestReward(
            type: 'badge',
            amount: 1,
            itemId: 'video_star_badge',
            description: 'Video Star Badge',
          ),
        ],
      );

  /// Globe Trotter Quest
  static Quest get globeTrotter => Quest(
        questId: 'quest_globe_trotter',
        name: 'Globe Trotter',
        description: 'Connect with people around the world',
        iconUrl: 'assets/quests/globe_trotter.png',
        type: QuestType.story,
        difficulty: QuestDifficulty.expert,
        requiredLevel: 15,
        steps: const [
          QuestStep(
            stepId: 'step_countries_3',
            order: 1,
            title: 'International Connections',
            description: 'Match with users from 3 countries',
            actionType: 'unique_country_match',
            requiredCount: 3,
            xpReward: 100,
          ),
          QuestStep(
            stepId: 'step_countries_5',
            order: 2,
            title: 'Expanding Horizons',
            description: 'Match with users from 5 countries',
            actionType: 'unique_country_match',
            requiredCount: 5,
            xpReward: 150,
          ),
          QuestStep(
            stepId: 'step_countries_10',
            order: 3,
            title: 'World Citizen',
            description: 'Match with users from 10 countries',
            actionType: 'unique_country_match',
            requiredCount: 10,
            xpReward: 200,
          ),
          QuestStep(
            stepId: 'step_travel_mode',
            order: 4,
            title: 'Travel Mode Explorer',
            description: 'Use travel mode in 3 cities',
            actionType: 'travel_mode_used',
            requiredCount: 3,
            xpReward: 200,
          ),
        ],
        rewards: const [
          QuestReward(type: 'xp', amount: 1000),
          QuestReward(type: 'coins', amount: 750),
          QuestReward(
            type: 'badge',
            amount: 1,
            itemId: 'globe_trotter_badge',
            description: 'Globe Trotter Badge',
          ),
        ],
      );

  /// Premium Experience Quest
  static Quest get premiumExperience => Quest(
        questId: 'quest_premium',
        name: 'Premium Experience',
        description: 'Unlock the full power of GreenGo',
        iconUrl: 'assets/quests/premium.png',
        type: QuestType.premium,
        difficulty: QuestDifficulty.medium,
        steps: const [
          QuestStep(
            stepId: 'step_subscribe',
            order: 1,
            title: 'Go Premium',
            description: 'Subscribe to a premium tier',
            actionType: 'subscription',
            requiredCount: 1,
            xpReward: 100,
          ),
          QuestStep(
            stepId: 'step_boost',
            order: 2,
            title: 'Boost Yourself',
            description: 'Use 3 profile boosts',
            actionType: 'boost_used',
            requiredCount: 3,
            xpReward: 75,
          ),
          QuestStep(
            stepId: 'step_super_likes',
            order: 3,
            title: 'Super Fan',
            description: 'Send 10 super likes',
            actionType: 'super_like',
            requiredCount: 10,
            xpReward: 75,
          ),
          QuestStep(
            stepId: 'step_gifts',
            order: 4,
            title: 'Generous Heart',
            description: 'Send 5 coin gifts',
            actionType: 'gift_sent',
            requiredCount: 5,
            xpReward: 100,
          ),
        ],
        rewards: const [
          QuestReward(type: 'xp', amount: 600),
          QuestReward(type: 'coins', amount: 500),
          QuestReward(type: 'premium_time', amount: 7, description: '7 days free premium'),
        ],
      );

  /// Get all quests
  static List<Quest> get all => [
        profileSetup,
        firstWeek,
        socialButterfly,
        videoDateMaster,
        globeTrotter,
        premiumExperience,
      ];

  /// Get quests by type
  static List<Quest> getByType(QuestType type) {
    return all.where((q) => q.type == type).toList();
  }

  /// Get onboarding quests
  static List<Quest> get onboarding => getByType(QuestType.onboarding);

  /// Get story quests
  static List<Quest> get story => getByType(QuestType.story);
}

extension QuestTypeExtension on QuestType {
  String get displayName {
    switch (this) {
      case QuestType.onboarding:
        return 'Getting Started';
      case QuestType.daily:
        return 'Daily';
      case QuestType.weekly:
        return 'Weekly';
      case QuestType.monthly:
        return 'Monthly';
      case QuestType.story:
        return 'Story';
      case QuestType.seasonal:
        return 'Seasonal';
      case QuestType.premium:
        return 'Premium';
    }
  }
}

extension QuestDifficultyExtension on QuestDifficulty {
  String get displayName {
    switch (this) {
      case QuestDifficulty.beginner:
        return 'Beginner';
      case QuestDifficulty.easy:
        return 'Easy';
      case QuestDifficulty.medium:
        return 'Medium';
      case QuestDifficulty.hard:
        return 'Hard';
      case QuestDifficulty.expert:
        return 'Expert';
      case QuestDifficulty.legendary:
        return 'Legendary';
    }
  }

  int get colorValue {
    switch (this) {
      case QuestDifficulty.beginner:
        return 0xFF4CAF50; // Green
      case QuestDifficulty.easy:
        return 0xFF8BC34A; // Light Green
      case QuestDifficulty.medium:
        return 0xFFFFC107; // Amber
      case QuestDifficulty.hard:
        return 0xFFFF9800; // Orange
      case QuestDifficulty.expert:
        return 0xFFF44336; // Red
      case QuestDifficulty.legendary:
        return 0xFF9C27B0; // Purple
    }
  }
}
