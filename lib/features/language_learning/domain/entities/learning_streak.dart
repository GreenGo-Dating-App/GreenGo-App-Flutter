import 'package:equatable/equatable.dart';

/// Tracks user's language learning streak
class LearningStreak extends Equatable {
  final String id;
  final String odUserId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPracticeDate;
  final List<DateTime> practiceHistory;
  final List<StreakMilestone> achievedMilestones;
  final int totalPracticeDays;

  const LearningStreak({
    required this.id,
    required this.odUserId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    this.practiceHistory = const [],
    this.achievedMilestones = const [],
    this.totalPracticeDays = 0,
  });

  LearningStreak copyWith({
    String? id,
    String? odUserId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPracticeDate,
    List<DateTime>? practiceHistory,
    List<StreakMilestone>? achievedMilestones,
    int? totalPracticeDays,
  }) {
    return LearningStreak(
      id: id ?? this.id,
      odUserId: odUserId ?? this.odUserId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      practiceHistory: practiceHistory ?? this.practiceHistory,
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
      totalPracticeDays: totalPracticeDays ?? this.totalPracticeDays,
    );
  }

  bool get isPracticedToday {
    if (lastPracticeDate == null) return false;
    final now = DateTime.now();
    return lastPracticeDate!.year == now.year &&
        lastPracticeDate!.month == now.month &&
        lastPracticeDate!.day == now.day;
  }

  StreakMilestone? get nextMilestone {
    final allMilestones = StreakMilestone.allMilestones;
    for (final milestone in allMilestones) {
      if (currentStreak < milestone.requiredDays) {
        return milestone;
      }
    }
    return null;
  }

  double get progressToNextMilestone {
    final next = nextMilestone;
    if (next == null) return 1.0;

    final previous = StreakMilestone.allMilestones
        .lastWhere((m) => m.requiredDays <= currentStreak,
            orElse: () => StreakMilestone.allMilestones.first);

    final range = next.requiredDays - previous.requiredDays;
    final progress = currentStreak - previous.requiredDays;
    return range > 0 ? progress / range : 0.0;
  }

  @override
  List<Object?> get props => [
        id,
        odUserId,
        currentStreak,
        longestStreak,
        lastPracticeDate,
        practiceHistory,
        achievedMilestones,
        totalPracticeDays,
      ];
}

class StreakMilestone extends Equatable {
  final int requiredDays;
  final String name;
  final String description;
  final int coinReward;
  final int xpReward;
  final String? badgeName;

  const StreakMilestone({
    required this.requiredDays,
    required this.name,
    required this.description,
    required this.coinReward,
    required this.xpReward,
    this.badgeName,
  });

  static const List<StreakMilestone> allMilestones = [
    StreakMilestone(
      requiredDays: 3,
      name: 'Language Curious',
      description: 'Practiced for 3 consecutive days',
      coinReward: 25,
      xpReward: 30,
    ),
    StreakMilestone(
      requiredDays: 7,
      name: 'Week Learner',
      description: 'Practiced for 7 consecutive days',
      coinReward: 50,
      xpReward: 75,
      badgeName: 'Weekly Linguist',
    ),
    StreakMilestone(
      requiredDays: 14,
      name: 'Two Week Scholar',
      description: 'Practiced for 14 consecutive days',
      coinReward: 100,
      xpReward: 150,
    ),
    StreakMilestone(
      requiredDays: 30,
      name: 'Monthly Master',
      description: 'Practiced for 30 consecutive days',
      coinReward: 200,
      xpReward: 300,
      badgeName: 'Monthly Language Master',
    ),
    StreakMilestone(
      requiredDays: 60,
      name: 'Two Month Champion',
      description: 'Practiced for 60 consecutive days',
      coinReward: 400,
      xpReward: 500,
    ),
    StreakMilestone(
      requiredDays: 90,
      name: 'Quarter Year Legend',
      description: 'Practiced for 90 consecutive days',
      coinReward: 600,
      xpReward: 750,
      badgeName: 'Quarterly Language Legend',
    ),
    StreakMilestone(
      requiredDays: 180,
      name: 'Half Year Hero',
      description: 'Practiced for 180 consecutive days',
      coinReward: 1000,
      xpReward: 1200,
      badgeName: 'Half-Year Language Hero',
    ),
    StreakMilestone(
      requiredDays: 365,
      name: 'Year of Languages',
      description: 'Practiced for 365 consecutive days',
      coinReward: 2500,
      xpReward: 3000,
      badgeName: 'Annual Language Champion',
    ),
  ];

  @override
  List<Object?> get props => [
        requiredDays,
        name,
        description,
        coinReward,
        xpReward,
        badgeName,
      ];
}
