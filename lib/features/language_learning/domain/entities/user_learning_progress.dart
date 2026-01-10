import 'package:equatable/equatable.dart';
import 'lesson.dart';

/// Comprehensive user learning progress for accountability tracking
/// Tracks all aspects of a user's language learning journey
class UserLearningProgress extends Equatable {
  final String id;
  final String odUserId;
  final String languageCode;
  final String languageName;
  final LessonLevel currentLevel;
  final int totalXp;
  final int xpThisWeek;
  final int xpThisMonth;
  final int totalCoinsSpent;
  final int lessonsCompleted;
  final int lessonsInProgress;
  final int exercisesCompleted;
  final int correctAnswers;
  final int totalAnswers;
  final int currentStreak;
  final int longestStreak;
  final int totalMinutesLearned;
  final int minutesThisWeek;
  final DateTime? lastActivityAt;
  final DateTime startedAt;
  final Map<LessonCategory, CategoryProgress> categoryProgress;
  final List<WeeklyProgress> weeklyHistory;
  final List<String> completedLessonIds;
  final List<String> purchasedLessonIds;
  final Map<String, double> skillScores; // vocabulary, grammar, listening, etc.
  final List<LearningMilestone> milestones;
  final LearningGoal? currentGoal;
  final DateTime? updatedAt;

  const UserLearningProgress({
    required this.id,
    required this.odUserId,
    required this.languageCode,
    required this.languageName,
    this.currentLevel = LessonLevel.absolute_beginner,
    this.totalXp = 0,
    this.xpThisWeek = 0,
    this.xpThisMonth = 0,
    this.totalCoinsSpent = 0,
    this.lessonsCompleted = 0,
    this.lessonsInProgress = 0,
    this.exercisesCompleted = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalMinutesLearned = 0,
    this.minutesThisWeek = 0,
    this.lastActivityAt,
    required this.startedAt,
    this.categoryProgress = const {},
    this.weeklyHistory = const [],
    this.completedLessonIds = const [],
    this.purchasedLessonIds = const [],
    this.skillScores = const {},
    this.milestones = const [],
    this.currentGoal,
    this.updatedAt,
  });

  /// Overall accuracy percentage
  double get accuracy => totalAnswers > 0 ? correctAnswers / totalAnswers : 0.0;

  /// Progress toward next level (0.0 to 1.0)
  double get levelProgress {
    final currentXp = totalXp - currentLevel.requiredXp;
    final nextLevel = LessonLevel.values.indexOf(currentLevel) + 1;
    if (nextLevel >= LessonLevel.values.length) return 1.0;
    final xpForNextLevel =
        LessonLevel.values[nextLevel].requiredXp - currentLevel.requiredXp;
    return (currentXp / xpForNextLevel).clamp(0.0, 1.0);
  }

  /// Average minutes per day this week
  double get avgMinutesPerDay => minutesThisWeek / 7;

  /// Is the user active (learned within last 24 hours)
  bool get isActiveToday {
    if (lastActivityAt == null) return false;
    return DateTime.now().difference(lastActivityAt!).inHours < 24;
  }

  /// Days since last activity
  int get daysSinceLastActivity {
    if (lastActivityAt == null) return -1;
    return DateTime.now().difference(lastActivityAt!).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        odUserId,
        languageCode,
        currentLevel,
        totalXp,
        lessonsCompleted,
        currentStreak,
      ];
}

/// Progress within a specific lesson category
class CategoryProgress extends Equatable {
  final LessonCategory category;
  final int lessonsCompleted;
  final int totalLessons;
  final int xpEarned;
  final double averageScore;
  final bool isMastered;
  final DateTime? lastActivityAt;

  const CategoryProgress({
    required this.category,
    this.lessonsCompleted = 0,
    this.totalLessons = 0,
    this.xpEarned = 0,
    this.averageScore = 0.0,
    this.isMastered = false,
    this.lastActivityAt,
  });

  double get completionPercent =>
      totalLessons > 0 ? lessonsCompleted / totalLessons : 0.0;

  @override
  List<Object?> get props =>
      [category, lessonsCompleted, totalLessons, isMastered];
}

/// Weekly progress snapshot for history tracking
class WeeklyProgress extends Equatable {
  final int weekNumber; // ISO week number
  final int year;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int xpEarned;
  final int lessonsCompleted;
  final int exercisesCompleted;
  final int minutesLearned;
  final int streakDays;
  final double averageAccuracy;
  final List<DailyActivity> dailyActivities;

  const WeeklyProgress({
    required this.weekNumber,
    required this.year,
    required this.weekStart,
    required this.weekEnd,
    this.xpEarned = 0,
    this.lessonsCompleted = 0,
    this.exercisesCompleted = 0,
    this.minutesLearned = 0,
    this.streakDays = 0,
    this.averageAccuracy = 0.0,
    this.dailyActivities = const [],
  });

  @override
  List<Object?> get props => [weekNumber, year, xpEarned, lessonsCompleted];
}

/// Daily activity record
class DailyActivity extends Equatable {
  final DateTime date;
  final int xpEarned;
  final int lessonsCompleted;
  final int exercisesCompleted;
  final int minutesLearned;
  final bool goalMet;

  const DailyActivity({
    required this.date,
    this.xpEarned = 0,
    this.lessonsCompleted = 0,
    this.exercisesCompleted = 0,
    this.minutesLearned = 0,
    this.goalMet = false,
  });

  bool get isActive => xpEarned > 0 || minutesLearned > 0;

  @override
  List<Object?> get props => [date, xpEarned, lessonsCompleted];
}

/// Learning milestone achievement
class LearningMilestone extends Equatable {
  final String id;
  final MilestoneType type;
  final String title;
  final String description;
  final DateTime achievedAt;
  final int xpReward;
  final int coinReward;
  final String? badgeIcon;
  final bool isClaimed;

  const LearningMilestone({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.achievedAt,
    this.xpReward = 0,
    this.coinReward = 0,
    this.badgeIcon,
    this.isClaimed = false,
  });

  @override
  List<Object?> get props => [id, type, achievedAt, isClaimed];
}

enum MilestoneType {
  first_lesson,
  first_perfect_score,
  streak_3_days,
  streak_7_days,
  streak_30_days,
  streak_100_days,
  streak_365_days,
  level_up,
  category_mastered,
  language_beginner,
  language_intermediate,
  language_advanced,
  language_fluent,
  xp_100,
  xp_1000,
  xp_10000,
  xp_50000,
  lessons_10,
  lessons_50,
  lessons_100,
  lessons_500,
  polyglot_2_languages,
  polyglot_5_languages,
  polyglot_10_languages,
  speed_learner,
  night_owl,
  early_bird,
  weekend_warrior,
  consistent_learner;

  String get displayName {
    switch (this) {
      case MilestoneType.first_lesson:
        return 'First Steps';
      case MilestoneType.first_perfect_score:
        return 'Perfect!';
      case MilestoneType.streak_3_days:
        return '3-Day Streak';
      case MilestoneType.streak_7_days:
        return 'Week Warrior';
      case MilestoneType.streak_30_days:
        return 'Monthly Master';
      case MilestoneType.streak_100_days:
        return 'Century Streak';
      case MilestoneType.streak_365_days:
        return 'Year of Learning';
      case MilestoneType.level_up:
        return 'Level Up!';
      case MilestoneType.category_mastered:
        return 'Category Master';
      case MilestoneType.language_beginner:
        return 'Beginner';
      case MilestoneType.language_intermediate:
        return 'Intermediate';
      case MilestoneType.language_advanced:
        return 'Advanced';
      case MilestoneType.language_fluent:
        return 'Fluent Speaker';
      case MilestoneType.xp_100:
        return 'XP Hunter';
      case MilestoneType.xp_1000:
        return 'XP Master';
      case MilestoneType.xp_10000:
        return 'XP Legend';
      case MilestoneType.xp_50000:
        return 'XP God';
      case MilestoneType.lessons_10:
        return 'Lesson Starter';
      case MilestoneType.lessons_50:
        return 'Dedicated Learner';
      case MilestoneType.lessons_100:
        return 'Centurion';
      case MilestoneType.lessons_500:
        return 'Knowledge Seeker';
      case MilestoneType.polyglot_2_languages:
        return 'Bilingual';
      case MilestoneType.polyglot_5_languages:
        return 'Polyglot';
      case MilestoneType.polyglot_10_languages:
        return 'Language Master';
      case MilestoneType.speed_learner:
        return 'Speed Learner';
      case MilestoneType.night_owl:
        return 'Night Owl';
      case MilestoneType.early_bird:
        return 'Early Bird';
      case MilestoneType.weekend_warrior:
        return 'Weekend Warrior';
      case MilestoneType.consistent_learner:
        return 'Consistent Learner';
    }
  }

  String get emoji {
    switch (this) {
      case MilestoneType.first_lesson:
        return '🎉';
      case MilestoneType.first_perfect_score:
        return '💯';
      case MilestoneType.streak_3_days:
        return '🔥';
      case MilestoneType.streak_7_days:
        return '⚡';
      case MilestoneType.streak_30_days:
        return '🌟';
      case MilestoneType.streak_100_days:
        return '💎';
      case MilestoneType.streak_365_days:
        return '👑';
      case MilestoneType.level_up:
        return '⬆️';
      case MilestoneType.category_mastered:
        return '🏆';
      case MilestoneType.language_beginner:
        return '🌱';
      case MilestoneType.language_intermediate:
        return '🌿';
      case MilestoneType.language_advanced:
        return '🌳';
      case MilestoneType.language_fluent:
        return '🎓';
      case MilestoneType.xp_100:
        return '⭐';
      case MilestoneType.xp_1000:
        return '🌟';
      case MilestoneType.xp_10000:
        return '💫';
      case MilestoneType.xp_50000:
        return '✨';
      case MilestoneType.lessons_10:
        return '📚';
      case MilestoneType.lessons_50:
        return '📖';
      case MilestoneType.lessons_100:
        return '🎯';
      case MilestoneType.lessons_500:
        return '🏅';
      case MilestoneType.polyglot_2_languages:
        return '🗣️';
      case MilestoneType.polyglot_5_languages:
        return '🌍';
      case MilestoneType.polyglot_10_languages:
        return '🌐';
      case MilestoneType.speed_learner:
        return '🚀';
      case MilestoneType.night_owl:
        return '🦉';
      case MilestoneType.early_bird:
        return '🐦';
      case MilestoneType.weekend_warrior:
        return '💪';
      case MilestoneType.consistent_learner:
        return '📈';
    }
  }
}

/// User's learning goal
class LearningGoal extends Equatable {
  final String id;
  final LearningGoalType type;
  final int targetValue;
  final int currentValue;
  final GoalPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final int xpReward;
  final int coinReward;

  const LearningGoal({
    required this.id,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.completedAt,
    this.xpReward = 0,
    this.coinReward = 0,
  });

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  bool get isExpired =>
      !isCompleted && DateTime.now().isAfter(endDate);

  @override
  List<Object?> get props => [id, type, targetValue, currentValue, isCompleted];
}

enum LearningGoalType {
  daily_xp,
  daily_minutes,
  daily_lessons,
  weekly_xp,
  weekly_lessons,
  weekly_streak,
  monthly_xp,
  monthly_lessons,
  complete_category,
  reach_level;

  String get displayName {
    switch (this) {
      case LearningGoalType.daily_xp:
        return 'Daily XP';
      case LearningGoalType.daily_minutes:
        return 'Daily Minutes';
      case LearningGoalType.daily_lessons:
        return 'Daily Lessons';
      case LearningGoalType.weekly_xp:
        return 'Weekly XP';
      case LearningGoalType.weekly_lessons:
        return 'Weekly Lessons';
      case LearningGoalType.weekly_streak:
        return 'Weekly Streak';
      case LearningGoalType.monthly_xp:
        return 'Monthly XP';
      case LearningGoalType.monthly_lessons:
        return 'Monthly Lessons';
      case LearningGoalType.complete_category:
        return 'Complete Category';
      case LearningGoalType.reach_level:
        return 'Reach Level';
    }
  }
}

enum GoalPeriod {
  daily,
  weekly,
  monthly,
  custom;
}

/// Aggregated learning analytics for admin dashboard
class LearningAnalytics extends Equatable {
  final DateTime generatedAt;
  final DateRange dateRange;
  final int totalActiveUsers;
  final int newUsersThisPeriod;
  final int totalLessonsCompleted;
  final int totalXpAwarded;
  final int totalCoinsSpent;
  final double averageSessionMinutes;
  final double averageAccuracy;
  final Map<String, int> usersByLanguage;
  final Map<LessonLevel, int> usersByLevel;
  final Map<String, int> completionsByCategory;
  final List<TopLearner> topLearners;
  final List<PopularLesson> popularLessons;
  final Map<int, int> activityByHour; // Hour -> count
  final Map<int, int> activityByDayOfWeek; // 1-7 -> count
  final double retentionRate; // 7-day retention
  final double churnRate;

  const LearningAnalytics({
    required this.generatedAt,
    required this.dateRange,
    this.totalActiveUsers = 0,
    this.newUsersThisPeriod = 0,
    this.totalLessonsCompleted = 0,
    this.totalXpAwarded = 0,
    this.totalCoinsSpent = 0,
    this.averageSessionMinutes = 0.0,
    this.averageAccuracy = 0.0,
    this.usersByLanguage = const {},
    this.usersByLevel = const {},
    this.completionsByCategory = const {},
    this.topLearners = const [],
    this.popularLessons = const [],
    this.activityByHour = const {},
    this.activityByDayOfWeek = const {},
    this.retentionRate = 0.0,
    this.churnRate = 0.0,
  });

  @override
  List<Object?> get props => [generatedAt, dateRange, totalActiveUsers];
}

class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

class TopLearner extends Equatable {
  final String odUserId;
  final String displayName;
  final String? photoUrl;
  final int xpThisPeriod;
  final int lessonsCompleted;
  final int currentStreak;
  final int rank;

  const TopLearner({
    required this.odUserId,
    required this.displayName,
    this.photoUrl,
    required this.xpThisPeriod,
    required this.lessonsCompleted,
    required this.currentStreak,
    required this.rank,
  });

  @override
  List<Object?> get props => [odUserId, rank, xpThisPeriod];
}

class PopularLesson extends Equatable {
  final String lessonId;
  final String title;
  final String languageCode;
  final int completionCount;
  final double averageRating;
  final int purchaseCount;

  const PopularLesson({
    required this.lessonId,
    required this.title,
    required this.languageCode,
    required this.completionCount,
    required this.averageRating,
    required this.purchaseCount,
  });

  @override
  List<Object?> get props => [lessonId, completionCount, averageRating];
}
