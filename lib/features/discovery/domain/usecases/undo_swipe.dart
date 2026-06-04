import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/discovery_repository.dart';

/// Undo Swipe Use Case
///
/// Deletes the most recent swipe record for a user on a target
class UndoSwipe implements UseCase<void, UndoSwipeParams> {

  UndoSwipe(this.repository);
  final DiscoveryRepository repository;

  @override
  Future<Either<Failure, void>> call(UndoSwipeParams params) async {
    return repository.undoSwipe(
      userId: params.userId,
      targetUserId: params.targetUserId,
    );
  }
}

class UndoSwipeParams {

  UndoSwipeParams({
    required this.userId,
    required this.targetUserId,
  });
  final String userId;
  final String targetUserId;
}
