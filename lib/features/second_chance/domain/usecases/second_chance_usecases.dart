import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/second_chance.dart';
import '../repositories/second_chance_repository.dart';

/// Get second chance profiles
class GetSecondChanceProfiles {
  final SecondChanceRepository repository;

  GetSecondChanceProfiles(this.repository);

  Future<Either<Failure, List<SecondChanceProfile>>> call(String userId) {
    return repository.getSecondChanceProfiles(userId);
  }
}

/// Get second chance usage
class GetSecondChanceUsage {
  final SecondChanceRepository repository;

  GetSecondChanceUsage(this.repository);

  Future<Either<Failure, SecondChanceUsage>> call(String userId) {
    return repository.getUsage(userId);
  }
}

/// Like a second chance profile
class LikeSecondChance {
  final SecondChanceRepository repository;

  LikeSecondChance(this.repository);

  Future<Either<Failure, SecondChanceResult>> call({
    required String userId,
    required String entryId,
  }) {
    return repository.likeSecondChance(userId: userId, entryId: entryId);
  }
}

/// Pass on a second chance profile
class PassSecondChance {
  final SecondChanceRepository repository;

  PassSecondChance(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required String entryId,
  }) {
    return repository.passSecondChance(userId: userId, entryId: entryId);
  }
}

/// Purchase unlimited second chances
class PurchaseUnlimitedSecondChances {
  final SecondChanceRepository repository;

  PurchaseUnlimitedSecondChances(this.repository);

  Future<Either<Failure, SecondChanceUsage>> call(String userId) {
    return repository.purchaseUnlimited(userId);
  }
}

/// Stream second chance profiles
class StreamSecondChances {
  final SecondChanceRepository repository;

  StreamSecondChances(this.repository);

  Stream<Either<Failure, List<SecondChanceProfile>>> call(String userId) {
    return repository.streamSecondChances(userId);
  }
}
