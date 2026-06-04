import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/second_chance.dart';
import '../repositories/second_chance_repository.dart';

/// Get second chance profiles
class GetSecondChanceProfiles {

  GetSecondChanceProfiles(this.repository);
  final SecondChanceRepository repository;

  Future<Either<Failure, List<SecondChanceProfile>>> call(String userId) {
    return repository.getSecondChanceProfiles(userId);
  }
}

/// Get second chance usage
class GetSecondChanceUsage {

  GetSecondChanceUsage(this.repository);
  final SecondChanceRepository repository;

  Future<Either<Failure, SecondChanceUsage>> call(String userId) {
    return repository.getUsage(userId);
  }
}

/// Like a second chance profile
class LikeSecondChance {

  LikeSecondChance(this.repository);
  final SecondChanceRepository repository;

  Future<Either<Failure, SecondChanceResult>> call({
    required String userId,
    required String entryId,
  }) {
    return repository.likeSecondChance(userId: userId, entryId: entryId);
  }
}

/// Pass on a second chance profile
class PassSecondChance {

  PassSecondChance(this.repository);
  final SecondChanceRepository repository;

  Future<Either<Failure, void>> call({
    required String userId,
    required String entryId,
  }) {
    return repository.passSecondChance(userId: userId, entryId: entryId);
  }
}

/// Purchase unlimited second chances
class PurchaseUnlimitedSecondChances {

  PurchaseUnlimitedSecondChances(this.repository);
  final SecondChanceRepository repository;

  Future<Either<Failure, SecondChanceUsage>> call(String userId) {
    return repository.purchaseUnlimited(userId);
  }
}

/// Stream second chance profiles
class StreamSecondChances {

  StreamSecondChances(this.repository);
  final SecondChanceRepository repository;

  Stream<Either<Failure, List<SecondChanceProfile>>> call(String userId) {
    return repository.streamSecondChances(userId);
  }
}
