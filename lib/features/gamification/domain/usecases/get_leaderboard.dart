/**
 * Get Leaderboard Use Case
 * Point 191: Build leaderboard system with rankings
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_level.dart';
import '../repositories/gamification_repository.dart';

class GetLeaderboard implements UseCase<LeaderboardData, GetLeaderboardParams> {
  final GamificationRepository repository;

  GetLeaderboard(this.repository);

  @override
  Future<Either<Failure, LeaderboardData>> call(
    GetLeaderboardParams params,
  ) async {
    // Get leaderboard entries
    final leaderboardResult = await repository.getLeaderboard(
      type: params.type,
      region: params.region,
      limit: params.limit,
    );

    if (leaderboardResult.isLeft()) {
      return Left(leaderboardResult.fold((l) => l, (r) => throw Exception()));
    }

    final entries = leaderboardResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Get user's rank if userId provided
    int? userRank;
    LeaderboardEntry? userEntry;
    if (params.userId != null) {
      final userRankResult = await repository.getUserRank(
        params.userId!,
        type: params.type,
      );

      if (userRankResult.isRight()) {
        userRank = userRankResult.fold(
          (l) => null,
          (r) => r,
        );

        // Find user's entry
        userEntry = entries.firstWhere(
          (e) => e.userId == params.userId,
          orElse: () {
            // User not in top entries, get their level
            return LeaderboardEntry(
              rank: userRank!,
              userId: params.userId!,
              level: 0,
              totalXP: 0,
              region: params.region ?? '',
              isVIP: false,
            );
          },
        );
      }
    }

    // Group entries by rank tiers
    final topTen = entries.take(10).toList();
    final next90 = entries.skip(10).take(90).toList();

    return Right(LeaderboardData(
      entries: entries,
      topTen: topTen,
      next90: next90,
      userRank: userRank,
      userEntry: userEntry,
      type: params.type,
      region: params.region,
    ));
  }
}

class GetLeaderboardParams {
  final LeaderboardType type;
  final String? region;
  final int limit;
  final String? userId; // To get user's rank

  GetLeaderboardParams({
    this.type = LeaderboardType.global,
    this.region,
    this.limit = 100,
    this.userId,
  });
}

class LeaderboardData {
  final List<LeaderboardEntry> entries;
  final List<LeaderboardEntry> topTen;
  final List<LeaderboardEntry> next90;
  final int? userRank;
  final LeaderboardEntry? userEntry;
  final LeaderboardType type;
  final String? region;

  LeaderboardData({
    required this.entries,
    required this.topTen,
    required this.next90,
    this.userRank,
    this.userEntry,
    required this.type,
    this.region,
  });
}
