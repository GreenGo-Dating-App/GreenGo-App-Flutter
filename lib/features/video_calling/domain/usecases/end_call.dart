import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/video_calling_repository.dart';

/// End Call Use Case
class EndCall {
  final VideoCallingRepository repository;

  EndCall(this.repository);

  Future<Either<Failure, void>> call(EndCallParams params) {
    return repository.endCall(
      callId: params.callId,
      userId: params.userId,
    );
  }
}

/// Parameters for EndCall use case
class EndCallParams {
  final String callId;
  final String userId;

  EndCallParams({
    required this.callId,
    required this.userId,
  });
}
