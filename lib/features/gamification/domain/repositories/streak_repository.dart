import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/login_streak.dart';

/// Streak Repository Interface
abstract class StreakRepository {
  /// Get user's login streak
  Future<Either<Failure, LoginStreak?>> getStreak(String userId);

  /// Record daily login and update streak
  Future<Either<Failure, LoginStreak>> recordLogin(String userId);

  /// Claim a streak milestone reward
  Future<Either<Failure, void>> claimMilestone(String userId, String milestoneId);

  /// Watch streak for real-time updates
  Stream<LoginStreak?> watchStreak(String userId);
}
