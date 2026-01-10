import 'package:equatable/equatable.dart';
import 'language_progress.dart';

/// Represents the language learning leaderboard
class LanguageLeaderboard extends Equatable {
  final LeaderboardType type;
  final LeaderboardPeriod period;
  final List<LeaderboardEntry> entries;
  final DateTime lastUpdated;
  final String? currentUserRank;

  const LanguageLeaderboard({
    required this.type,
    required this.period,
    required this.entries,
    required this.lastUpdated,
    this.currentUserRank,
  });

  @override
  List<Object?> get props => [
        type,
        period,
        entries,
        lastUpdated,
        currentUserRank,
      ];
}

class LeaderboardEntry extends Equatable {
  final String odUserId;
  final String username;
  final String? photoUrl;
  final int rank;
  final int wordsLearned;
  final int languagesCount;
  final int quizzesCompleted;
  final int totalXp;
  final int currentStreak;
  final LanguageProficiency highestProficiency;
  final bool isCurrentUser;
  final String? primaryLanguage;
  final String? countryFlag;

  const LeaderboardEntry({
    required this.odUserId,
    required this.username,
    this.photoUrl,
    required this.rank,
    required this.wordsLearned,
    required this.languagesCount,
    required this.quizzesCompleted,
    required this.totalXp,
    this.currentStreak = 0,
    this.highestProficiency = LanguageProficiency.beginner,
    this.isCurrentUser = false,
    this.primaryLanguage,
    this.countryFlag,
  });

  @override
  List<Object?> get props => [
        odUserId,
        username,
        photoUrl,
        rank,
        wordsLearned,
        languagesCount,
        quizzesCompleted,
        totalXp,
        currentStreak,
        highestProficiency,
        isCurrentUser,
        primaryLanguage,
        countryFlag,
      ];
}

enum LeaderboardType {
  wordsLearned,
  languagesMastered,
  quizzes,
  streak,
  totalXp,
}

extension LeaderboardTypeExtension on LeaderboardType {
  String get displayName {
    switch (this) {
      case LeaderboardType.wordsLearned:
        return 'Words Learned';
      case LeaderboardType.languagesMastered:
        return 'Languages';
      case LeaderboardType.quizzes:
        return 'Quiz Champions';
      case LeaderboardType.streak:
        return 'Longest Streaks';
      case LeaderboardType.totalXp:
        return 'Total XP';
    }
  }

  String get icon {
    switch (this) {
      case LeaderboardType.wordsLearned:
        return '📚';
      case LeaderboardType.languagesMastered:
        return '🌍';
      case LeaderboardType.quizzes:
        return '🏆';
      case LeaderboardType.streak:
        return '🔥';
      case LeaderboardType.totalXp:
        return '⭐';
    }
  }
}

enum LeaderboardPeriod {
  weekly,
  monthly,
  allTime,
}

extension LeaderboardPeriodExtension on LeaderboardPeriod {
  String get displayName {
    switch (this) {
      case LeaderboardPeriod.weekly:
        return 'This Week';
      case LeaderboardPeriod.monthly:
        return 'This Month';
      case LeaderboardPeriod.allTime:
        return 'All Time';
    }
  }
}

/// Leaderboard prizes for top performers
class LeaderboardPrize extends Equatable {
  final int rankFrom;
  final int rankTo;
  final int coinReward;
  final int xpReward;
  final String? badgeName;

  const LeaderboardPrize({
    required this.rankFrom,
    required this.rankTo,
    required this.coinReward,
    required this.xpReward,
    this.badgeName,
  });

  @override
  List<Object?> get props => [rankFrom, rankTo, coinReward, xpReward, badgeName];

  static const List<LeaderboardPrize> weeklyPrizes = [
    LeaderboardPrize(
      rankFrom: 1,
      rankTo: 1,
      coinReward: 500,
      xpReward: 250,
      badgeName: 'Weekly Language Champion',
    ),
    LeaderboardPrize(
      rankFrom: 2,
      rankTo: 2,
      coinReward: 300,
      xpReward: 150,
    ),
    LeaderboardPrize(
      rankFrom: 3,
      rankTo: 3,
      coinReward: 200,
      xpReward: 100,
    ),
    LeaderboardPrize(
      rankFrom: 4,
      rankTo: 10,
      coinReward: 100,
      xpReward: 50,
    ),
  ];

  static const List<LeaderboardPrize> monthlyPrizes = [
    LeaderboardPrize(
      rankFrom: 1,
      rankTo: 1,
      coinReward: 2000,
      xpReward: 1000,
      badgeName: 'Monthly Language Legend',
    ),
    LeaderboardPrize(
      rankFrom: 2,
      rankTo: 2,
      coinReward: 1200,
      xpReward: 600,
    ),
    LeaderboardPrize(
      rankFrom: 3,
      rankTo: 3,
      coinReward: 800,
      xpReward: 400,
    ),
    LeaderboardPrize(
      rankFrom: 4,
      rankTo: 10,
      coinReward: 400,
      xpReward: 200,
    ),
  ];
}
