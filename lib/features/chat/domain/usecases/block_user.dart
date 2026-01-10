import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Block User Use Case
class BlockUser {
  final ChatRepository repository;

  BlockUser(this.repository);

  Future<Either<Failure, void>> call(BlockUserParams params) {
    return repository.blockUser(
      blockerId: params.blockerId,
      blockedUserId: params.blockedUserId,
      reason: params.reason,
    );
  }
}

/// Parameters for BlockUser use case
class BlockUserParams {
  final String blockerId;
  final String blockedUserId;
  final String reason;

  BlockUserParams({
    required this.blockerId,
    required this.blockedUserId,
    required this.reason,
  });
}

/// Unblock User Use Case
class UnblockUser {
  final ChatRepository repository;

  UnblockUser(this.repository);

  Future<Either<Failure, void>> call(UnblockUserParams params) {
    return repository.unblockUser(
      blockerId: params.blockerId,
      blockedUserId: params.blockedUserId,
    );
  }
}

/// Parameters for UnblockUser use case
class UnblockUserParams {
  final String blockerId;
  final String blockedUserId;

  UnblockUserParams({
    required this.blockerId,
    required this.blockedUserId,
  });
}

/// Check If User Is Blocked Use Case
class IsUserBlocked {
  final ChatRepository repository;

  IsUserBlocked(this.repository);

  Future<Either<Failure, bool>> call(IsUserBlockedParams params) {
    return repository.isUserBlocked(
      userId: params.userId,
      otherUserId: params.otherUserId,
    );
  }
}

/// Parameters for IsUserBlocked use case
class IsUserBlockedParams {
  final String userId;
  final String otherUserId;

  IsUserBlockedParams({
    required this.userId,
    required this.otherUserId,
  });
}
