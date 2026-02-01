import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/blind_date.dart';
import '../repositories/blind_date_repository.dart';

/// Create blind date profile
class CreateBlindProfile {
  final BlindDateRepository repository;

  CreateBlindProfile(this.repository);

  Future<Either<Failure, BlindDateProfile>> call(String userId) {
    return repository.createBlindProfile(userId);
  }
}

/// Get blind date profile
class GetBlindProfile {
  final BlindDateRepository repository;

  GetBlindProfile(this.repository);

  Future<Either<Failure, BlindDateProfile?>> call(String userId) {
    return repository.getBlindProfile(userId);
  }
}

/// Deactivate blind date profile
class DeactivateBlindProfile {
  final BlindDateRepository repository;

  DeactivateBlindProfile(this.repository);

  Future<Either<Failure, void>> call(String userId) {
    return repository.deactivateBlindProfile(userId);
  }
}

/// Get blind date candidates
class GetBlindCandidates {
  final BlindDateRepository repository;

  GetBlindCandidates(this.repository);

  Future<Either<Failure, List<BlindProfileView>>> call({
    required String userId,
    int limit = 10,
  }) {
    return repository.getBlindCandidates(userId: userId, limit: limit);
  }
}

/// Like a blind profile
class LikeBlindProfile {
  final BlindDateRepository repository;

  LikeBlindProfile(this.repository);

  Future<Either<Failure, BlindLikeResult>> call({
    required String userId,
    required String targetUserId,
  }) {
    return repository.likeBlindProfile(
      userId: userId,
      targetUserId: targetUserId,
    );
  }
}

/// Pass on a blind profile
class PassBlindProfile {
  final BlindDateRepository repository;

  PassBlindProfile(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required String targetUserId,
  }) {
    return repository.passBlindProfile(
      userId: userId,
      targetUserId: targetUserId,
    );
  }
}

/// Get blind matches
class GetBlindMatches {
  final BlindDateRepository repository;

  GetBlindMatches(this.repository);

  Future<Either<Failure, List<BlindMatch>>> call(String userId) {
    return repository.getBlindMatches(userId);
  }

  Stream<Either<Failure, List<BlindMatch>>> stream(String userId) {
    return repository.streamBlindMatches(userId);
  }
}

/// Instant reveal photos
class InstantReveal {
  final BlindDateRepository repository;

  InstantReveal(this.repository);

  Future<Either<Failure, BlindMatch>> call({
    required String userId,
    required String matchId,
  }) {
    return repository.instantReveal(userId: userId, matchId: matchId);
  }
}

/// Check reveal status
class CheckRevealStatus {
  final BlindDateRepository repository;

  CheckRevealStatus(this.repository);

  Future<Either<Failure, bool>> call(String matchId) {
    return repository.checkRevealStatus(matchId);
  }
}

/// Get revealed profile
class GetRevealedProfile {
  final BlindDateRepository repository;

  GetRevealedProfile(this.repository);

  Future<Either<Failure, BlindProfileView>> call({
    required String matchId,
    required String userId,
  }) {
    return repository.getRevealedProfile(matchId: matchId, userId: userId);
  }
}
