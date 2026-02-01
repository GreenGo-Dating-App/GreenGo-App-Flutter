import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/second_chance.dart';

/// Repository interface for Second Chance feature
abstract class SecondChanceRepository {
  /// Get available second chance profiles
  Future<Either<Failure, List<SecondChanceProfile>>> getSecondChanceProfiles(
    String userId,
  );

  /// Get usage for today
  Future<Either<Failure, SecondChanceUsage>> getUsage(String userId);

  /// Like a second chance profile
  Future<Either<Failure, SecondChanceResult>> likeSecondChance({
    required String userId,
    required String entryId,
  });

  /// Pass on a second chance profile
  Future<Either<Failure, void>> passSecondChance({
    required String userId,
    required String entryId,
  });

  /// Purchase unlimited second chances for today
  Future<Either<Failure, SecondChanceUsage>> purchaseUnlimited(String userId);

  /// Stream second chance profiles
  Stream<Either<Failure, List<SecondChanceProfile>>> streamSecondChances(
    String userId,
  );
}
