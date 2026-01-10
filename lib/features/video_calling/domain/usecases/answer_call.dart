import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/video_call.dart';
import '../repositories/video_calling_repository.dart';

/// Answer Call Use Case
class AnswerCall {
  final VideoCallingRepository repository;

  AnswerCall(this.repository);

  Future<Either<Failure, VideoCall>> call(AnswerCallParams params) {
    return repository.answerCall(
      callId: params.callId,
      userId: params.userId,
    );
  }
}

/// Parameters for AnswerCall use case
class AnswerCallParams {
  final String callId;
  final String userId;

  AnswerCallParams({
    required this.callId,
    required this.userId,
  });
}
