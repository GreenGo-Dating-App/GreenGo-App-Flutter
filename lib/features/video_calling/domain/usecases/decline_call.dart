import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/video_calling_repository.dart';

/// Decline Call Use Case
class DeclineCall {
  final VideoCallingRepository repository;

  DeclineCall(this.repository);

  Future<Either<Failure, void>> call(DeclineCallParams params) {
    return repository.declineCall(
      callId: params.callId,
      userId: params.userId,
    );
  }
}

/// Parameters for DeclineCall use case
class DeclineCallParams {
  final String callId;
  final String userId;

  DeclineCallParams({
    required this.callId,
    required this.userId,
  });
}
