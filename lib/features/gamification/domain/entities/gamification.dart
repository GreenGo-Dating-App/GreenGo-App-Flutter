import 'package:equatable/equatable.dart';

/// Challenge Type
enum ChallengeType {
  daily,
  weekly,
  monthly,
  special,
  onboarding,
}

/// Challenge Status
enum ChallengeStatus {
  locked,
  available,
  inProgress,
  completed,
  expired,
}

/// Weekly Challenge Entity
class Challenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final String iconName;
  final int targetCount;
  final int currentCount;
  final int rewardPoints;
  final String? rewardType; // 'super_like', 'boost', 'premium_day', 'coins'
  final int? rewardAmount;
  final DateTime startDate;
  final DateTime endDate;
  final ChallengeStatus status;
  final List<String> requirements;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.iconName,
    required this.targetCount,
    this.currentCount = 0,
    required this.rewardPoints,
    this.rewardType,
    this.rewardAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.requirements = const [],
  });

  double get progress => targetCount > 0 ? currentCount / targetCount : 0;
  bool get isCompleted => currentCount >= targetCount;
  bool get isExpired => DateTime.now().isAfter(endDate);

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        iconName,
        targetCount,
        currentCount,
        rewardPoints,
        rewardType,
        rewardAmount,
        startDate,
        endDate,
        status,
        requirements,
      ];
}

/// Referral Entity
class Referral extends Equatable {
  final String id;
  final String referrerId;
  final String referredUserId;
  final String? referredUserName;
  final String referralCode;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final int referrerReward;
  final int referredReward;
  final String rewardType;

  const Referral({
    required this.id,
    required this.referrerId,
    required this.referredUserId,
    this.referredUserName,
    required this.referralCode,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
    required this.referrerReward,
    required this.referredReward,
    required this.rewardType,
  });

  @override
  List<Object?> get props => [
        id,
        referrerId,
        referredUserId,
        referredUserName,
        referralCode,
        createdAt,
        completedAt,
        isCompleted,
        referrerReward,
        referredReward,
        rewardType,
      ];
}

/// User Referral Stats
class ReferralStats extends Equatable {
  final String userId;
  final String referralCode;
  final int totalReferrals;
  final int completedReferrals;
  final int pendingReferrals;
  final int totalEarnings;
  final String referralLink;

  const ReferralStats({
    required this.userId,
    required this.referralCode,
    this.totalReferrals = 0,
    this.completedReferrals = 0,
    this.pendingReferrals = 0,
    this.totalEarnings = 0,
    required this.referralLink,
  });

  @override
  List<Object?> get props => [
        userId,
        referralCode,
        totalReferrals,
        completedReferrals,
        pendingReferrals,
        totalEarnings,
        referralLink,
      ];
}

/// Dating Coach Tip Entity
class DatingCoachTip extends Equatable {
  final String id;
  final String title;
  final String content;
  final String category; // 'profile', 'messaging', 'first_date', 'safety', 'conversation'
  final String? imageUrl;
  final bool isPremium;
  final int likeCount;
  final DateTime createdAt;
  final List<String> tags;

  const DatingCoachTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl,
    this.isPremium = false,
    this.likeCount = 0,
    required this.createdAt,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        category,
        imageUrl,
        isPremium,
        likeCount,
        createdAt,
        tags,
      ];
}

/// AI Conversation Suggestion Entity
class ConversationSuggestion extends Equatable {
  final String id;
  final String matchId;
  final String suggestion;
  final String context; // 'opening', 'reply', 'ask_out', 'compliment'
  final double confidenceScore;
  final DateTime generatedAt;
  final bool wasUsed;

  const ConversationSuggestion({
    required this.id,
    required this.matchId,
    required this.suggestion,
    required this.context,
    this.confidenceScore = 0.0,
    required this.generatedAt,
    this.wasUsed = false,
  });

  @override
  List<Object?> get props => [
        id,
        matchId,
        suggestion,
        context,
        confidenceScore,
        generatedAt,
        wasUsed,
      ];
}

/// Default Weekly Challenges
class DefaultChallenges {
  static const List<Map<String, dynamic>> weeklyChallenes = [
    {
      'title': 'Complete Your Profile',
      'description': 'Add all required profile information and 3+ photos',
      'iconName': 'person_outline',
      'targetCount': 1,
      'rewardPoints': 100,
      'rewardType': 'super_like',
      'rewardAmount': 3,
    },
    {
      'title': 'Conversation Starter',
      'description': 'Send the first message to 5 new matches',
      'iconName': 'chat_bubble_outline',
      'targetCount': 5,
      'rewardPoints': 50,
      'rewardType': 'coins',
      'rewardAmount': 50,
    },
    {
      'title': 'Active Dater',
      'description': 'Swipe on 50 profiles this week',
      'iconName': 'swipe',
      'targetCount': 50,
      'rewardPoints': 75,
      'rewardType': 'boost',
      'rewardAmount': 1,
    },
    {
      'title': 'Story Teller',
      'description': 'Post 3 stories this week',
      'iconName': 'add_a_photo',
      'targetCount': 3,
      'rewardPoints': 60,
      'rewardType': 'coins',
      'rewardAmount': 30,
    },
    {
      'title': 'Video Star',
      'description': 'Add a video to your profile',
      'iconName': 'videocam',
      'targetCount': 1,
      'rewardPoints': 150,
      'rewardType': 'premium_day',
      'rewardAmount': 1,
    },
    {
      'title': 'Social Butterfly',
      'description': 'RSVP to 2 events',
      'iconName': 'event',
      'targetCount': 2,
      'rewardPoints': 80,
      'rewardType': 'super_like',
      'rewardAmount': 2,
    },
    {
      'title': 'Safety First',
      'description': 'Set up date check-in for your next date',
      'iconName': 'security',
      'targetCount': 1,
      'rewardPoints': 100,
      'rewardType': 'coins',
      'rewardAmount': 100,
    },
    {
      'title': 'Friend Finder',
      'description': 'Invite 3 friends to join GreenGo',
      'iconName': 'group_add',
      'targetCount': 3,
      'rewardPoints': 200,
      'rewardType': 'premium_day',
      'rewardAmount': 7,
    },
  ];
}
