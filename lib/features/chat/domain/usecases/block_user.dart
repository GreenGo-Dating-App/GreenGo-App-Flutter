import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Block User Use Case
class BlockUser {

  BlockUser(this.repository);
  final ChatRepository repository;

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

  BlockUserParams({
    required this.blockerId,
    required this.blockedUserId,
    required this.reason,
  });
  final String blockerId;
  final String blockedUserId;
  final String reason;
}

/// Unblock User Use Case
class UnblockUser {

  UnblockUser(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, void>> call(UnblockUserParams params) {
    return repository.unblockUser(
      blockerId: params.blockerId,
      blockedUserId: params.blockedUserId,
    );
  }
}

/// Parameters for UnblockUser use case
class UnblockUserParams {

  UnblockUserParams({
    required this.blockerId,
    required this.blockedUserId,
  });
  final String blockerId;
  final String blockedUserId;
}

/// Check If User Is Blocked Use Case
class IsUserBlocked {

  IsUserBlocked(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, bool>> call(IsUserBlockedParams params) {
    return repository.isUserBlocked(
      userId: params.userId,
      otherUserId: params.otherUserId,
    );
  }
}

/// Parameters for IsUserBlocked use case
class IsUserBlockedParams {

  IsUserBlockedParams({
    required this.userId,
    required this.otherUserId,
  });
  final String userId;
  final String otherUserId;
}
