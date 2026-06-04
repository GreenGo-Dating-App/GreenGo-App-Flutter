import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/swipe_action.dart';
import '../repositories/discovery_repository.dart';

/// Record Swipe Use Case
///
/// Records a user's swipe action and checks for matches
class RecordSwipe implements UseCase<SwipeAction, RecordSwipeParams> {

  RecordSwipe(this.repository);
  final DiscoveryRepository repository;

  @override
  Future<Either<Failure, SwipeAction>> call(RecordSwipeParams params) async {
    return repository.recordSwipe(
      userId: params.userId,
      targetUserId: params.targetUserId,
      actionType: params.actionType,
    );
  }
}

class RecordSwipeParams {

  RecordSwipeParams({
    required this.userId,
    required this.targetUserId,
    required this.actionType,
  });
  final String userId;
  final String targetUserId;
  final SwipeActionType actionType;
}
